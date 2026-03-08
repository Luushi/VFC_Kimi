#pragma once
#include <opencv2/opencv.hpp>

class EdgeAwareFilter {
public:
    // Fast bilateral filter refinement (always available)
    static cv::Mat bilateralRefine(const cv::Mat& mask, const cv::Mat& guidance, 
                                    int d = 9, double sigmaColor = 75, double sigmaSpace = 75) {
        CV_Assert(mask.type() == CV_8U || mask.type() == CV_32F);
        
        cv::Mat maskFloat;
        if (mask.type() == CV_8U) {
            mask.convertTo(maskFloat, CV_32F, 1.0 / 255.0);
        } else {
            maskFloat = mask.clone();
        }
        
        // Ensure guidance is grayscale and same size
        cv::Mat grayGuide;
        if (guidance.channels() == 3) {
            cv::cvtColor(guidance, grayGuide, cv::COLOR_BGR2GRAY);
        } else {
            grayGuide = guidance.clone();
        }
        
        if (grayGuide.size() != maskFloat.size()) {
            cv::resize(grayGuide, grayGuide, maskFloat.size());
        }
        
        grayGuide.convertTo(grayGuide, CV_32F, 1.0 / 255.0);
        
        // Joint bilateral filter: use color image as guidance
        cv::Mat refined;
        cv::bilateralFilter(maskFloat, refined, d, sigmaColor, sigmaSpace);
        
        // Convert back
        cv::Mat result;
        refined.convertTo(result, CV_8U, 255.0);
        
        return result;
    }
    
    // Multi-scale refinement for hair details
    static cv::Mat multiScaleRefine(const cv::Mat& mask, const cv::Mat& guidance) {
        std::vector<cv::Mat> pyramids;
        
        // Build pyramid
        cv::Mat current = mask.clone();
        for (int i = 0; i < 3; i++) {
            pyramids.push_back(current);
            cv::pyrDown(current, current);
        }
        
        // Refine from coarse to fine
        cv::Mat refined = pyramids.back();
        for (int i = pyramids.size() - 2; i >= 0; i--) {
            cv::pyrUp(refined, refined, pyramids[i].size());
            cv::Mat temp;
            cv::addWeighted(refined, 0.5, pyramids[i], 0.5, 0, temp);
            refined = bilateralRefine(temp, guidance, 5, 50, 50);
        }
        
        return refined;
    }
    
    // Feather edges for soft transitions
    static cv::Mat featherEdges(const cv::Mat& mask, int featherRadius = 5) {
        cv::Mat floatMask;
        mask.convertTo(floatMask, CV_32F, 1.0 / 255.0);
        
        // Apply Gaussian blur for softness
        cv::Mat blurred;
        cv::GaussianBlur(floatMask, blurred, cv::Size(featherRadius * 2 + 1, featherRadius * 2 + 1), 
                         featherRadius);
        
        // Convert back
        cv::Mat result;
        blurred.convertTo(result, CV_8U, 255.0);
        
        return result;
    }
};