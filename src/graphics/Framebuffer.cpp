#include "Framebuffer.h"
#include <iostream>

Framebuffer::Framebuffer(int width, int height) : width_(width), height_(height) { create(); }
Framebuffer::~Framebuffer() { destroy(); }

void Framebuffer::create() {
    glGenFramebuffers(1, &fbo_);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo_);
    
    glGenTextures(1, &colorTexture_);
    glBindTexture(GL_TEXTURE_2D, colorTexture_);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width_, height_, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, colorTexture_, 0);
    
    glGenTextures(1, &depthTexture_);
    glBindTexture(GL_TEXTURE_2D, depthTexture_);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT24, width_, height_, 0, GL_DEPTH_COMPONENT, GL_FLOAT, nullptr);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, depthTexture_, 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) 
        std::cerr << "Framebuffer incomplete!\n";
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

void Framebuffer::destroy() {
    if (fbo_) glDeleteFramebuffers(1, &fbo_);
    if (colorTexture_) glDeleteTextures(1, &colorTexture_);
    if (depthTexture_) glDeleteTextures(1, &depthTexture_);
}

void Framebuffer::bind() const { 
    glBindFramebuffer(GL_FRAMEBUFFER, fbo_); 
    glViewport(0, 0, width_, height_); 
}

void Framebuffer::unbind() const { glBindFramebuffer(GL_FRAMEBUFFER, 0); }

void Framebuffer::resize(int width, int height) { 
    destroy(); 
    width_ = width; 
    height_ = height; 
    create(); 
}

// ADD THIS FUNCTION AT THE END
void Framebuffer::clear(float r, float g, float b, float a) {
    bind();
    glClearColor(r, g, b, a);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}