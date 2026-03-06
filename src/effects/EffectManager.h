#pragma once
#include <memory>
#include <vector>
#include "Effect.h"
#include "../graphics/Framebuffer.h"

class EffectManager {
public:
    EffectManager() {}
    ~EffectManager() {}
    void add(std::shared_ptr<Effect> e) { e->init(); effects_.push_back(e); }
    void clear() { effects_.clear(); }
    void update(float dt) { for (auto& e : effects_) if (e->isEnabled()) e->update(dt); }
    uint32_t render(uint32_t inputTex, int w, int h);
    void onFace(const FaceData& f) { for (auto& e : effects_) e->onFace(f); }
private:
    std::vector<std::shared_ptr<Effect>> effects_;
    std::unique_ptr<Framebuffer> buf_[2];
    int w_=0,h_=0;
    void ensure(int w,int h);
};
