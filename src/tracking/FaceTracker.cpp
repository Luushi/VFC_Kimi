#include "FaceTracker.h"
#include "../effects/Effect.h"
#include <iostream>

bool FaceTracker::init() {
    if (!cascade_.load("assets/haarcascade_frontalface_default.xml")) { 
        std::cerr << "No cascade!\n"; 
        return false; 
    }
    ready_ = true; 
    return true;
}

bool FaceTracker::detect(const cv::Mat& frame, std::vector<Face>& faces) {
    faces.clear(); 
    if (!ready_) return false;
    
    cv::Mat gray; 
    cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);
    std::vector<cv::Rect> rects; 
    
    // Detect faces
    cascade_.detectMultiScale(gray, rects, 1.1, 3, 0, cv::Size(80, 80));
    
    for (auto& r : rects) { 
        Face f; 
        f.box = r; // Store the exact bounding box
        f.id = nextId_++; 
        f.conf = 0.9f; 
        
        // --- THE FIX: Calculate the exact center of the face ---
        float centerX = r.x + (r.width / 2.0f);
        float centerY = r.y + (r.height / 2.0f);
        f.pos = glm::vec3(centerX, centerY, 0.0f); 
        // -------------------------------------------------------

        f.rot = glm::vec3(0);
        
        // Normalized landmark corners
        f.landmarks68.push_back(glm::vec2(r.x / (float)frame.cols, r.y / (float)frame.rows));
        f.landmarks68.push_back(glm::vec2((r.x + r.width) / (float)frame.cols, (r.y + r.height) / (float)frame.rows));
        
        faces.push_back(f); 
    }
    return !faces.empty();
}