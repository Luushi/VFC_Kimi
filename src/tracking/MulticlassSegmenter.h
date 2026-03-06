#pragma once
#include <opencv2/opencv.hpp>
#include <onnxruntime_cxx_api.h>
#include <array>
#include <string>

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
};

class MulticlassSegmenter {
public:
    MulticlassSegmenter();
    ~MulticlassSegmenter();
    
    bool initialize(const std::string& modelPath);
    MulticlassMasks segment(const cv::Mat& frame);
    
    // Temporal smoothing for video
    void enableTemporalSmoothing(bool enable) { useTemporal_ = enable; }
    void setSmoothingFactor(float alpha) { smoothAlpha_ = alpha; }
    
private:
    Ort::Env env_;
    std::unique_ptr<Ort::Session> session_;
    Ort::MemoryInfo memoryInfo_;
    
    const int inputSize_ = 256;
    const int numClasses_ = 6;
    
    bool useTemporal_ = true;
    float smoothAlpha_ = 0.7f;
    std::array<cv::Mat, 6> prevMasks_;
    
    cv::Mat preprocess(const cv::Mat& frame);
    std::array<cv::Mat, 6> postprocess(const float* output, int origW, int origH);
};