#pragma once
#include "Effect.h"
#include "../graphics/Shader.h"

class Distortion2D : public Effect {
public:
    enum Mode { FISHEYE, TWIRL, BARREL };
    Distortion2D(Mode m) : Effect(DISTORT_2D,"Distortion"), mode_(m) {}
    ~Distortion2D();
    void init() override;
    void update(float dt) override {}
    void render(uint32_t inputTex, uint32_t outFBO, int w, int h) override;
    void setCenter(const glm::vec2& c) { center_ = c; }
    void setStrength(float s) { strength_ = s; }
private:
    Mode mode_;
    Shader shader_;
    uint32_t vao_ = 0, vbo_ = 0;
    glm::vec2 center_ = glm::vec2(0.5f,0.5f);
    float strength_ = 0.5f;
    void createQuad();
    const char* getFrag();
};
