#include "MulticlassSegmenter.h"
#include <iostream>
#include <vector>
#include <string>
#include <cmath>

MulticlassSegmenter::MulticlassSegmenter() 
    : env_(ORT_LOGGING_LEVEL_WARNING, "MulticlassSeg"),
      memoryInfo_(Ort::MemoryInfo::CreateCpu(OrtArenaAllocator, OrtMemTypeDefault)) {}

MulticlassSegmenter::~MulticlassSegmenter() = default;

bool MulticlassSegmenter::initialize(const std::string& modelPath) {
    try {
        Ort::SessionOptions sessionOptions;
        sessionOptions.SetIntraOpNumThreads(4);
        sessionOptions.SetGraphOptimizationLevel(GraphOptimizationLevel::ORT_ENABLE_ALL);
        
        std::wstring wpath(modelPath.begin(), modelPath.end());
        session_ = std::make_unique<Ort::Session>(env_, wpath.c_str(), sessionOptions);
        
        // Query names ONCE and deep copy them safely into strings
        Ort::AllocatorWithDefaultOptions allocator;
        auto inputNameAlloc = session_->GetInputNameAllocated(0, allocator);
        auto outputNameAlloc = session_->GetOutputNameAllocated(0, allocator);
        
        inputName_ = inputNameAlloc.get();
        outputName_ = outputNameAlloc.get();
        
        std::cout << "Model loaded: " << modelPath << std::endl;
        std::cout << "Cached Input name: " << inputName_ << std::endl;
        std::cout << "Cached Output name: " << outputName_ << std::endl;
        std::cout << "Temporal smoothing: " << (useTemporal_ ? "ON" : "OFF") << " (alpha=" << defaultAlpha_ << ")" << std::endl;
        std::cout << "Skip-frame processing: Every " << processEveryN_ << " frames" << std::endl;
        std::cout << "Edge refinement: " << (useEdgeRefinement_ ? "ON" : "OFF") << std::endl;
        
        return true;
    } catch (const Ort::Exception& e) {
        std::cerr << "ONNX Runtime error: " << e.what() << std::endl;
        return false;
    }
}

cv::Mat MulticlassSegmenter::preprocess(const cv::Mat& frame) {
    cv::Mat resized;
    cv::resize(frame, resized, cv::Size(inputSize_, inputSize_));
    
    // Convert BGR to RGB
    cv::Mat rgb;
    cv::cvtColor(resized, rgb, cv::COLOR_BGR2RGB);
    
    // Normalize to [0, 1] 
    cv::Mat floatMat;
    rgb.convertTo(floatMat, CV_32F, 1.0 / 255.0);
    
    return floatMat;
}

float MulticlassSegmenter::calculateMotion(const cv::Mat& currentFrame) {
    if (prevFrameGray_.empty()) {
        return 0.0f;
    }
    
    cv::Mat diff;
    cv::absdiff(currentFrame, prevFrameGray_, diff);
    
    // Calculate mean motion
    cv::Scalar meanDiff = cv::mean(diff);
    return static_cast<float>(meanDiff[0]);
}

std::array<cv::Mat, 6> MulticlassSegmenter::applyConfidenceThreshold(
    const std::array<std::vector<float>, 6>& classProbs) {
    
    std::array<cv::Mat, 6> masks;
    
    for (int c = 0; c < numClasses_; c++) {
        masks[c] = cv::Mat(inputSize_, inputSize_, CV_8U, cv::Scalar(0));
    }
    
    // Parallel processing with OpenMP if available
    for (int y = 0; y < inputSize_; y++) {
        for (int x = 0; x < inputSize_; x++) {
            int idx = y * inputSize_ + x;
            
            float maxProb = -1.0f;
            int maxClass = 0;
            float secondMaxProb = -1.0f;
            
            // Find max and second max
            for (int c = 0; c < numClasses_; c++) {
                float prob = classProbs[c][idx];
                if (prob > maxProb) {
                    secondMaxProb = maxProb;
                    maxProb = prob;
                    maxClass = c;
                } else if (prob > secondMaxProb) {
                    secondMaxProb = prob;
                }
            }
            
            // Confidence check: must be confident and significantly better than runner-up
            float margin = maxProb - secondMaxProb;
            bool confident = (maxProb > confidenceThreshold_) && (margin > 0.1f);
            
            if (confident) {
                masks[maxClass].at<uchar>(y, x) = 255;
            } else if (!prevMasks_[0].empty()) {
                // Use previous frame's classification for this pixel
                // Find which class had this pixel previously
                for (int c = 0; c < numClasses_; c++) {
                    if (prevMasks_[c].at<uchar>(y, x) > 127) {
                        masks[c].at<uchar>(y, x) = 255;
                        break;
                    }
                }
            } else {
                // Default to background if uncertain and no history
                masks[0].at<uchar>(y, x) = 255;
            }
        }
    }
    
    return masks;
}

std::array<cv::Mat, 6> MulticlassSegmenter::temporalSmooth(
    const std::array<cv::Mat, 6>& currentMasks, const cv::Mat& currentFrame) {
    
    if (!useTemporal_ || prevMasks_[0].empty()) {
        return currentMasks;
    }
    
    // Calculate motion for adaptive smoothing
    float motion = calculateMotion(currentFrame);
    
    // Adaptive alpha: less smoothing when moving fast
    float alpha = (motion < motionThreshold_) ? defaultAlpha_ : 0.5f;
    
    std::array<cv::Mat, 6> smoothed;
    
    for (int c = 0; c < numClasses_; c++) {
        if (!prevMasks_[c].empty()) {
            cv::Mat blended;
            cv::addWeighted(currentMasks[c], alpha, prevMasks_[c], 1.0f - alpha, 0, blended);
            smoothed[c] = blended;
        } else {
            smoothed[c] = currentMasks[c].clone();
        }
        prevMasks_[c] = smoothed[c].clone();
    }
    
    return smoothed;
}

cv::Mat MulticlassSegmenter::morphologicalClean(const cv::Mat& mask) {
    cv::Mat cleaned;
    
    // Small opening to remove noise (3x3 ellipse)
    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(3, 3));
    cv::morphologyEx(mask, cleaned, cv::MORPH_OPEN, kernel, cv::Point(-1, -1), 1);
    
    // Closing to fill small gaps
    cv::morphologyEx(cleaned, cleaned, cv::MORPH_CLOSE, kernel, cv::Point(-1, -1), 1);
    
    return cleaned;
}

void MulticlassSegmenter::refineEdges(std::array<cv::Mat, 6>& masks, const cv::Mat& highResFrame) {
    if (!useEdgeRefinement_) {
        // Just resize without refinement
        for (int c = 0; c < numClasses_; c++) {
            cv::resize(masks[c], masks[c], highResFrame.size(), 0, 0, cv::INTER_LINEAR);
        }
        return;
    }
    
    // Process each mask with edge-aware upsampling
    for (int c = 0; c < numClasses_; c++) {
        // Upsample to target resolution
        cv::Mat upsampled;
        cv::resize(masks[c], upsampled, highResFrame.size(), 0, 0, cv::INTER_LINEAR);
        
        // Convert to float for processing
        cv::Mat maskFloat;
        upsampled.convertTo(maskFloat, CV_32F, 1.0 / 255.0);
        
        // Fast bilateral filter for edge smoothing
        // Parameters: d=9 (filter size), sigmaColor=75, sigmaSpace=75
        cv::Mat refined;
        cv::bilateralFilter(maskFloat, refined, 9, 75, 75);
        
        // Additional morphological cleanup at full resolution
        cv::Mat refined8u;
        refined.convertTo(refined8u, CV_8U, 255.0);
        masks[c] = morphologicalClean(refined8u);
    }
}

std::array<cv::Mat, 6> MulticlassSegmenter::postprocess(
    const float* output, int origW, int origH, const cv::Mat& frame) {
    
    // Store class probabilities for confidence thresholding
    std::array<std::vector<float>, 6> classProbs;
    for (int c = 0; c < numClasses_; c++) {
        classProbs[c].resize(inputSize_ * inputSize_);
    }
    
    // Extract probabilities from NHWC format [1, 256, 256, 6]
    for (int y = 0; y < inputSize_; y++) {
        for (int x = 0; x < inputSize_; x++) {
            int baseIdx = y * inputSize_ * numClasses_ + x * numClasses_;
            int flatIdx = y * inputSize_ + x;
            
            for (int c = 0; c < numClasses_; c++) {
                classProbs[c][flatIdx] = output[baseIdx + c];
            }
        }
    }
    
    // 1. Apply confidence thresholding
    auto masks = applyConfidenceThreshold(classProbs);
    
    // 2. Convert frame to grayscale for motion detection
    cv::Mat grayFrame;
    cv::cvtColor(frame, grayFrame, cv::COLOR_BGR2GRAY);
    cv::resize(grayFrame, grayFrame, cv::Size(inputSize_, inputSize_));
    
    // 3. Temporal smoothing (motion-aware)
    masks = temporalSmooth(masks, grayFrame);
    
    // Update previous frame
    prevFrameGray_ = grayFrame.clone();
    
    // 4. Edge-aware upsampling to original resolution
    refineEdges(masks, frame);
    
    return masks;
}

MulticlassMasks MulticlassSegmenter::segment(const cv::Mat& frame) {
    MulticlassMasks result;
    
    if (!session_) {
        std::cerr << "Model not loaded!" << std::endl;
        return result;
    }
    
    frameCount_++;
    
    // Skip-frame processing: reuse cached result if not processing this frame
    if (hasCachedResult_ && (frameCount_ % processEveryN_ != 0)) {
        return cachedResult_;
    }
    
    auto startTime = std::chrono::high_resolution_clock::now();
    
    try {
        // Preprocess
        cv::Mat preprocessed = preprocess(frame);
        
        // Create input tensor [1, 256, 256, 3] (NHWC format)
        std::vector<int64_t> inputShape = {1, inputSize_, inputSize_, 3};
        std::vector<float> inputTensorValues(3 * inputSize_ * inputSize_);
        
        // Fill tensor mapping correctly to NHWC
        for (int h = 0; h < inputSize_; h++) {
            for (int w = 0; w < inputSize_; w++) {
                cv::Vec3f pixel = preprocessed.at<cv::Vec3f>(h, w);
                for (int c = 0; c < 3; c++) {
                    inputTensorValues[h * inputSize_ * 3 + w * 3 + c] = pixel[c];
                }
            }
        }
        
        Ort::Value inputTensor = Ort::Value::CreateTensor<float>(
            memoryInfo_, inputTensorValues.data(), inputTensorValues.size(), 
            inputShape.data(), inputShape.size());
        
        // Safely pass the cached string names as arrays
        std::vector<const char*> inputNames = { inputName_.c_str() };
        std::vector<const char*> outputNames = { outputName_.c_str() };
        
        // Run inference
        auto outputTensors = session_->Run(Ort::RunOptions{nullptr}, 
                                           inputNames.data(), &inputTensor, 1,
                                           outputNames.data(), 1);
        
        // Process output
        float* outputData = outputTensors[0].GetTensorMutableData<float>();
        auto masks = postprocess(outputData, frame.cols, frame.rows, frame);
        
        // Assign to result
        result.background = masks[0];
        result.hair = masks[1];
        result.bodySkin = masks[2];
        result.faceSkin = masks[3];
        result.clothes = masks[4];
        result.accessories = masks[5];
        
        // Create combined masks
        result.person = 255 - result.background;
        result.skin = result.faceSkin | result.bodySkin;
        result.fullBody = result.hair | result.bodySkin | result.faceSkin | result.clothes | result.accessories;
        
        // Create soft masks for alpha blending (optional)
        result.hairSoft = result.hair.clone();
        result.personSoft = result.person.clone();
        
        // Cache result for skip-frame processing
        cachedResult_ = result;
        hasCachedResult_ = true;
        
        // Calculate performance metrics
        auto endTime = std::chrono::high_resolution_clock::now();
        lastInferenceTimeMs_ = std::chrono::duration<float, std::milli>(endTime - startTime).count();
        
        auto timeSinceLast = std::chrono::duration<float>(endTime - lastProcessTime_).count();
        if (timeSinceLast > 0) {
            effectiveFps_ = static_cast<int>(1.0f / timeSinceLast);
        }
        lastProcessTime_ = endTime;
        
    } catch (const Ort::Exception& e) {
        std::cerr << "Inference error: " << e.what() << std::endl;
        // Return cached result if available, otherwise empty
        if (hasCachedResult_) {
            return cachedResult_;
        }
    }
    
    return result;
}