#pragma once
#include <opencv2/opencv.hpp>
#include <onnxruntime_cxx_api.h>
#include <array>
#include <string>
#include <chrono>

struct MulticlassMasks {
    cv::Mat background;  // Class 0
    cv::Mat hair;        // Class 1
    cv::Mat bodySkin;    // Class 2
    cv::Mat faceSkin;    // Class 3
    cv::Mat clothes;     // Class 4
    cv::Mat accessories; // Class 5
    
    // Combined masks
    cv::Mat person;      // All non-background
    cv::Mat skin;        // faceSkin + bodySkin
    cv::Mat fullBody;    // All except background
    
    // Soft masks (for alpha blending)
    cv::Mat hairSoft;
    cv::Mat personSoft;
};

class MulticlassSegmenter {
public:
    MulticlassSegmenter();
    ~MulticlassSegmenter();
    
    bool initialize(const std::string& modelPath);
    MulticlassMasks segment(const cv::Mat& frame);
    
    // Configuration
    void enableTemporalSmoothing(bool enable) { useTemporal_ = enable; }
    void setSmoothingFactor(float alpha) { defaultAlpha_ = alpha; }
    void setConfidenceThreshold(float thresh) { confidenceThreshold_ = thresh; }
    void setSkipFrames(int skip) { processEveryN_ = skip; }
    void setEdgeRefinement(bool enable) { useEdgeRefinement_ = enable; }
    
    // Performance stats
    float getLastInferenceTimeMs() const { return lastInferenceTimeMs_; }
    int getEffectiveFPS() const { return effectiveFps_; }
    
private:
    Ort::Env env_;
    std::unique_ptr<Ort::Session> session_;
    Ort::MemoryInfo memoryInfo_;
    
    const int inputSize_ = 256;
    const int numClasses_ = 6;
    
    std::string inputName_;
    std::string outputName_;
    
    // Temporal smoothing parameters
    bool useTemporal_ = true;
    float defaultAlpha_ = 0.9f;  // Changed from 0.7 to reduce lag
    float motionThreshold_ = 15.0f; // Pixel difference for motion detection
    std::array<cv::Mat, 6> prevMasks_;
    cv::Mat prevFrameGray_;
    
    // Confidence thresholding
    float confidenceThreshold_ = 0.6f;
    
    // Skip-frame processing
    int processEveryN_ = 2; // Process every 2nd frame
    int frameCount_ = 0;
    MulticlassMasks cachedResult_;
    bool hasCachedResult_ = false;
    
    // Edge refinement
    bool useEdgeRefinement_ = true;
    
    // Performance tracking
    float lastInferenceTimeMs_ = 0.0f;
    int effectiveFps_ = 30;
    std::chrono::high_resolution_clock::time_point lastProcessTime_;
    
    // Internal methods
    cv::Mat preprocess(const cv::Mat& frame);
    std::array<cv::Mat, 6> postprocess(const float* output, int origW, int origH, const cv::Mat& frame);
    
    // New processing steps
    std::array<cv::Mat, 6> applyConfidenceThreshold(const std::array<std::vector<float>, 6>& classProbs);
    std::array<cv::Mat, 6> temporalSmooth(const std::array<cv::Mat, 6>& currentMasks, const cv::Mat& currentFrame);
    void refineEdges(std::array<cv::Mat, 6>& masks, const cv::Mat& highResFrame);
    cv::Mat morphologicalClean(const cv::Mat& mask);
    
    // Motion detection
    float calculateMotion(const cv::Mat& currentFrame);
};