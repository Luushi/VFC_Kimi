#pragma once
#include <string>
#include <map>
#include <vector>
#include <glm/glm.hpp>

struct FaceData {
    std::vector<glm::vec2> landmarks;
    glm::vec3 position, rotation;
    float confidence;
};

class Effect {
public:
    enum Type { FILTER_2D, DISTORT_2D, OVERLAY_3D, FACE_MESH };
    
    Effect(Type t, const std::string& n) : type_(t), name_(n) {}
    virtual ~Effect() = default;
    
    virtual void init() = 0;
    virtual void update(float dt) = 0;
    virtual void render(uint32_t inputTex, uint32_t outFBO, int w, int h) = 0;
    virtual void onFace(const FaceData& f) {}
    
    void setEnabled(bool e) { enabled_ = e; }
    bool isEnabled() const { return enabled_; }
    Type getType() const { return type_; }
    const std::string& getName() const { return name_; }
    
    // ADD THIS METHOD
    void setFloatParam(const std::string& name, float value) { fParams_[name] = value; }
    
protected:
    Type type_;
    std::string name_;
    bool enabled_ = true;
    std::map<std::string, float> fParams_;
};