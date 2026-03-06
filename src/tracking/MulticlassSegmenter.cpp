#include "MulticlassSegmenter.h"
#include <iostream>

MulticlassSegmenter::MulticlassSegmenter() 
    : env_(ORT_LOGGING_LEVEL_WARNING, "MulticlassSeg"),
      memoryInfo_(Ort::MemoryInfo::CreateCpu(OrtArenaAllocator, OrtMemTypeDefault)) {}

MulticlassSegmenter::~MulticlassSegmenter() = default;

bool MulticlassSegmenter::initialize(const std::string& modelPath) {
    try {
        Ort::SessionOptions sessionOptions;
        sessionOptions.SetIntraOpNumThreads(4);
        sessionOptions.SetGraphOptimizationLevel(GraphOptimizationLevel::ORT_ENABLE_ALL);
        
        session_ = std::make_unique<Ort::Session>(env_, modelPath.c_str(), sessionOptions);
        
        // Print model info
        Ort::AllocatorWithDefaultOptions allocator;
        std::cout << "Model loaded: " << modelPath << std::endl;
        std::cout << "Input name: " << session_->GetInputNameAllocated(0, allocator) << std::endl;
        std::cout << "Output name: " << session_->GetOutputNameAllocated(0, allocator) << std::endl;
        
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
    
    // Normalize to [-1, 1] or [0, 1] depending on model
    // MediaPipe typically uses [0, 1]
    cv::Mat floatMat;
    rgb.convertTo(floatMat, CV_32F, 1.0 / 255.0);
    
    return floatMat;
}

std::array<cv::Mat, 6> MulticlassSegmenter::postprocess(const float* output, int origW, int origH) {
    std::array<cv::Mat, 6> masks;
    
    // Output is [1, 6, 256, 256] - softmax probabilities per class
    // Find argmax for each pixel
    cv::Mat segMap(inputSize_, inputSize_, CV_8U);
    
    for (int y = 0; y < inputSize_; y++) {
        for (int x = 0; x < inputSize_; x++) {
            int maxClass = 0;
            float maxProb = -1.0f;
            
            for (int c = 0; c < numClasses_; c++) {
                // NCHW format: [batch][channel][height][width]
                float prob = output[c * inputSize_ * inputSize_ + y * inputSize_ + x];
                if (prob > maxProb) {
                    maxProb = prob;
                    maxClass = c;
                }
            }
            segMap.at<uchar>(y, x) = maxClass;
        }
    }
    
    // Resize to original size
    cv::Mat fullSizeSeg;
    cv::resize(segMap, fullSizeSeg, cv::Size(origW, origH), 0, 0, cv::INTER_NEAREST);
    
    // Extract individual class masks
    for (int c = 0; c < numClasses_; c++) {
        masks[c] = (fullSizeSeg == c);
    }
    
    // Temporal smoothing
    if (useTemporal_) {
        for (int c = 0; c < numClasses_; c++) {
            if (!prevMasks_[c].empty()) {
                cv::Mat smoothed;
                cv::addWeighted(masks[c], smoothAlpha_, prevMasks_[c], 1.0f - smoothAlpha_, 0, smoothed);
                masks[c] = smoothed;
            }
            prevMasks_[c] = masks[c].clone();
        }
    }
    
    return masks;
}

MulticlassMasks MulticlassSegmenter::segment(const cv::Mat& frame) {
    MulticlassMasks result;
    
    if (!session_) {
        std::cerr << "Model not loaded!" << std::endl;
        return result;
    }
    
    try {
        // Preprocess
        cv::Mat preprocessed = preprocess(frame);
        
        // Create input tensor [1, 3, 256, 256]
        std::vector<int64_t> inputShape = {1, 3, inputSize_, inputSize_};
        std::vector<float> inputTensorValues(3 * inputSize_ * inputSize_);
        
        // Fill tensor (NCHW format)
        for (int c = 0; c < 3; c++) {
            for (int h = 0; h < inputSize_; h++) {
                for (int w = 0; w < inputSize_; w++) {
                    cv::Vec3f pixel = preprocessed.at<cv::Vec3f>(h, w);
                    inputTensorValues[c * inputSize_ * inputSize_ + h * inputSize_ + w] = pixel[c];
                }
            }
        }
        
        Ort::Value inputTensor = Ort::Value::CreateTensor<float>(
            memoryInfo_, inputTensorValues.data(), inputTensorValues.size(), 
            inputShape.data(), inputShape.size());
        
        // Get input/output names
        Ort::AllocatorWithDefaultOptions allocator;
        const char* inputName = session_->GetInputNameAllocated(0, allocator).get();
        const char* outputName = session_->GetOutputNameAllocated(0, allocator).get();
        
        // Run inference
        auto outputTensors = session_->Run(Ort::RunOptions{nullptr}, 
                                           &inputName, &inputTensor, 1,
                                           &outputName, 1);
        
        // Process output
        float* outputData = outputTensors[0].GetTensorMutableData<float>();
        auto masks = postprocess(outputData, frame.cols, frame.rows);
        
        // Assign to result
        result.background = masks[0];
        result.hair = masks[1];
        result.bodySkin = masks[2];
        result.faceSkin = masks[3];
        result.clothes = masks[4];
        result.accessories = masks[5];
        
        // Create combined masks
        result.person = 255 - result.background; // Everything except background
        result.skin = result.faceSkin | result.bodySkin;
        result.fullBody = result.hair | result.bodySkin | result.faceSkin | result.clothes | result.accessories;
        
    } catch (const Ort::Exception& e) {
        std::cerr << "Inference error: " << e.what() << std::endl;
    }
    
    return result;
}