#pragma once
#include "Effect.h"
#include "../graphics/Shader.h"

class Filter2D : public Effect {
public:
    Filter2D() : Effect(FILTER_2D, "Color Filter") {}
    ~Filter2D();
    void init() override;
    void update(float dt) override {}
    void render(uint32_t inputTex, uint32_t outFBO, int w, int h) override;
private:
    Shader shader_;
    uint32_t vao_ = 0, vbo_ = 0;
    void createQuad();
};
