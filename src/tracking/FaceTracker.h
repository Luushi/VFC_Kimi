#pragma once
#include <opencv2/opencv.hpp>
#include <vector>
#include <glm/glm.hpp>

struct FaceData;

class FaceTracker {
public:
    struct Face { 
        std::vector<glm::vec2> landmarks68; 
        cv::Rect box; 
        glm::vec3 pos,rot; 
        float conf; 
        int id; 
    };
    FaceTracker() {}
    bool init();
    bool detect(const cv::Mat& frame, std::vector<Face>& faces);
private:
    cv::CascadeClassifier cascade_;
    bool ready_ = false;
    int nextId_ = 0;
};
