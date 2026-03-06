#include "EffectManager.h"

void EffectManager::ensure(int w, int h) { 
    if (w_ != w || h_ != h) { 
        w_ = w; h_ = h;
        buf_[0] = std::make_unique<Framebuffer>(w, h);
        buf_[1] = std::make_unique<Framebuffer>(w, h);
    } 
}

uint32_t EffectManager::render(uint32_t inputTex, int w, int h) {
    ensure(w, h); 
    
    if (effects_.empty()) {
        return inputTex;
    }
    
    uint32_t cur = inputTex; 
    int pp = 0; // Ping-pong index
    
    for (auto& e : effects_) { 
        if (!e->isEnabled()) continue; 
        
        // Clear the target buffer
        buf_[pp]->clear(0.0f, 0.0f, 0.0f, 1.0f);
        
        // FIX: Pass the actual FBO ID (buf_[pp]->getFbo())
        // This ensures the effect draws INTO the texture, not the screen.
        e->render(cur, buf_[pp]->getFbo(), w, h); 
        
        cur = buf_[pp]->getTexture(); 
        pp = 1 - pp; // Switch to the other buffer for the next effect
    }
    
    return cur;
}