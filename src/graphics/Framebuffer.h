#pragma once
#include <glad/glad.h>
#include <cstdint>

class Framebuffer {
public:
    Framebuffer(int width, int height);
    ~Framebuffer();
    void bind() const;
    void unbind() const;
    void resize(int width, int height);
    void clear(float r = 0, float g = 0, float b = 0, float a = 1);
    
    uint32_t getTexture() const { return colorTexture_; }
    uint32_t getFbo() const { return fbo_; } // <--- Added for EffectManager
    
private:
    uint32_t fbo_ = 0, colorTexture_ = 0, depthTexture_ = 0;
    int width_, height_;
    void create();
    void destroy();
};