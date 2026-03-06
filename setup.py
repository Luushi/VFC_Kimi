import os
import sys

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

def write_file(path, content):
    full_path = os.path.join(BASE_DIR, path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, 'w') as f:
        f.write(content)
    print(f"Created: {path}")

def main():
    print("=== VFC_Kimi Effects Setup ===\n")
    
    # Create directories
    dirs = [
        "src/graphics", "src/effects", "src/tracking",
        "assets/shaders/2d", "assets/shaders/3d", "assets/shaders/face",
        "assets/textures/luts", "assets/models", "assets/effects"
    ]
    for d in dirs:
        os.makedirs(os.path.join(BASE_DIR, d), exist_ok=True)
        print(f"Created dir: {d}")
    
    print("\nCreating files...")
    
    # Framebuffer.h
    write_file("src/graphics/Framebuffer.h", '''#pragma once
#include <glad/glad.h>
#include <cstdint>

class Framebuffer {
public:
    Framebuffer(int width, int height);
    ~Framebuffer();
    void bind() const;
    void unbind() const;
    void resize(int width, int height);
    uint32_t getTexture() const { return colorTexture_; }
private:
    uint32_t fbo_ = 0, colorTexture_ = 0, depthTexture_ = 0;
    int width_, height_;
    void create();
    void destroy();
};
''')
    
    # Framebuffer.cpp
    write_file("src/graphics/Framebuffer.cpp", '''#include "Framebuffer.h"
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
        std::cerr << "Framebuffer incomplete!\\n";
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
''')
    
    # Shader.h
    write_file("src/graphics/Shader.h", '''#pragma once
#include <string>
#include <glad/glad.h>
#include <glm/glm.hpp>

class Shader {
public:
    Shader() {}
    ~Shader() { if (program_) glDeleteProgram(program_); }
    bool loadFromStrings(const std::string& vert, const std::string& frag);
    void use() const { glUseProgram(program_); }
    void setInt(const std::string& n, int v) { glUniform1i(glGetUniformLocation(program_, n.c_str()), v); }
    void setFloat(const std::string& n, float v) { glUniform1f(glGetUniformLocation(program_, n.c_str()), v); }
    void setVec2(const std::string& n, const glm::vec2& v) { glUniform2fv(glGetUniformLocation(program_, n.c_str()), 1, &v[0]); }
    void setMat4(const std::string& n, const glm::mat4& v) { glUniformMatrix4fv(glGetUniformLocation(program_, n.c_str()), 1, GL_FALSE, &v[0][0]); }
private:
    uint32_t program_ = 0;
};
''')
    
    # Shader.cpp
    write_file("src/graphics/Shader.cpp", '''#include "Shader.h"

bool Shader::loadFromStrings(const std::string& vertSrc, const std::string& fragSrc) {
    uint32_t vs = glCreateShader(GL_VERTEX_SHADER);
    const char* v = vertSrc.c_str();
    glShaderSource(vs, 1, &v, nullptr);
    glCompileShader(vs);
    
    uint32_t fs = glCreateShader(GL_FRAGMENT_SHADER);
    const char* f = fragSrc.c_str();
    glShaderSource(fs, 1, &f, nullptr);
    glCompileShader(fs);
    
    program_ = glCreateProgram();
    glAttachShader(program_, vs);
    glAttachShader(program_, fs);
    glLinkProgram(program_);
    
    glDeleteShader(vs);
    glDeleteShader(fs);
    return true;
}
''')
    
    # Effect.h
    write_file("src/effects/Effect.h", '''#pragma once
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
    
protected:
    Type type_;
    std::string name_;
    bool enabled_ = true;
    std::map<std::string, float> fParams_;
};
''')
    
    # Filter2D.h
    write_file("src/effects/Filter2D.h", '''#pragma once
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
''')
    
    # Filter2D.cpp
    write_file("src/effects/Filter2D.cpp", '''#include "Filter2D.h"

Filter2D::~Filter2D() { 
    if (vao_) glDeleteVertexArrays(1, &vao_); 
    if (vbo_) glDeleteBuffers(1, &vbo_); 
}

void Filter2D::init() {
    const char* v = R"(#version 330 core
layout(location=0) in vec2 p;
layout(location=1) in vec2 t;
out vec2 vT;
void main() { gl_Position=vec4(p,0,1); vT=t; })";

    const char* f = R"(#version 330 core
in vec2 vT;
out vec4 c;
uniform sampler2D tex;
uniform float bright, contrast, sat;
vec3 b(vec3 x,float v) { return x+v; }
vec3 ct(vec3 x,float v) { return (x-0.5)*(1.0+v)+0.5; }
vec3 s(vec3 x,float v) { float g=dot(x,vec3(0.299,0.587,0.114)); return mix(vec3(g),x,1.0+v); }
void main() { 
    vec4 x=texture(tex,vT); 
    vec3 r=b(x.rgb,bright); 
    r=ct(r,contrast); 
    r=s(r,sat); 
    c=vec4(r,x.a); 
})";

    shader_.loadFromStrings(v,f);
    createQuad();
    fParams_["bright"] = 0.0f;
    fParams_["contrast"] = 0.0f;
    fParams_["sat"] = 0.0f;
}

void Filter2D::createQuad() {
    float v[24] = {-1,1,0,1, -1,-1,0,0, 1,-1,1,0, -1,1,0,1, 1,-1,1,0, 1,1,1,1};
    glGenVertexArrays(1,&vao_); 
    glGenBuffers(1,&vbo_);
    glBindVertexArray(vao_); 
    glBindBuffer(GL_ARRAY_BUFFER,vbo_);
    glBufferData(GL_ARRAY_BUFFER,sizeof(v),v,GL_STATIC_DRAW);
    glEnableVertexAttribArray(0); 
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,16,(void*)0);
    glEnableVertexAttribArray(1); 
    glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,16,(void*)8);
}

void Filter2D::render(uint32_t inputTex, uint32_t outFBO, int w, int h) {
    glBindFramebuffer(GL_FRAMEBUFFER,outFBO);
    shader_.use();
    glActiveTexture(GL_TEXTURE0); 
    glBindTexture(GL_TEXTURE_2D,inputTex);
    shader_.setInt("tex",0);
    shader_.setFloat("bright",fParams_["bright"]);
    shader_.setFloat("contrast",fParams_["contrast"]);
    shader_.setFloat("sat",fParams_["sat"]);
    glBindVertexArray(vao_); 
    glDrawArrays(GL_TRIANGLES,0,6);
}
''')
    
    # Distortion2D.h
    write_file("src/effects/Distortion2D.h", '''#pragma once
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
''')
    
    # Distortion2D.cpp
    write_file("src/effects/Distortion2D.cpp", '''#include "Distortion2D.h"

Distortion2D::~Distortion2D() { 
    if (vao_) glDeleteVertexArrays(1, &vao_); 
    if (vbo_) glDeleteBuffers(1, &vbo_); 
}

const char* Distortion2D::getFrag() {
    if (mode_==FISHEYE) return R"(#version 330 core
in vec2 vT;
out vec4 c;
uniform sampler2D tex;
uniform vec2 cen;
uniform float str;
const float PI=3.14159265;
void main() { 
    vec2 p=vT-cen; 
    float d=length(p)*2.0; 
    float a=atan(p.y,p.x);
    float nd=tan(d*str*PI*0.5)/tan(str*PI*0.5); 
    vec2 nt=cen+vec2(cos(a),sin(a))*nd*0.5;
    c=texture(tex,clamp(nt,0.0,1.0)); 
})";

    if (mode_==TWIRL) return R"(#version 330 core
in vec2 vT;
out vec4 c;
uniform sampler2D tex;
uniform vec2 cen;
uniform float str;
void main() { 
    vec2 p=vT-cen; 
    float d=length(p); 
    float a=atan(p.y,p.x)+str*(1.0-d)*3.14159;
    vec2 nt=cen+d*vec2(cos(a),sin(a)); 
    c=texture(tex,nt); 
})";

    return R"(#version 330 core
in vec2 vT;
out vec4 c;
uniform sampler2D tex;
uniform vec2 cen;
uniform float str;
void main() { 
    vec2 p=vT-cen; 
    float d=length(p); 
    float r=d*(1.0+str*d*d);
    vec2 nt=cen+normalize(p)*r; 
    c=texture(tex,nt); 
})";
}

void Distortion2D::init() {
    const char* v = R"(#version 330 core
layout(location=0) in vec2 p;
layout(location=1) in vec2 t;
out vec2 vT;
void main() { gl_Position=vec4(p,0,1); vT=t; })";
    shader_.loadFromStrings(v,getFrag());
    createQuad();
}

void Distortion2D::createQuad() {
    float v[24] = {-1,1,0,1, -1,-1,0,0, 1,-1,1,0, -1,1,0,1, 1,-1,1,0, 1,1,1,1};
    glGenVertexArrays(1,&vao_); 
    glGenBuffers(1,&vbo_);
    glBindVertexArray(vao_); 
    glBindBuffer(GL_ARRAY_BUFFER,vbo_);
    glBufferData(GL_ARRAY_BUFFER,sizeof(v),v,GL_STATIC_DRAW);
    glEnableVertexAttribArray(0); 
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,16,(void*)0);
    glEnableVertexAttribArray(1); 
    glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,16,(void*)8);
}

void Distortion2D::render(uint32_t inputTex, uint32_t outFBO, int w, int h) {
    glBindFramebuffer(GL_FRAMEBUFFER,outFBO);
    shader_.use();
    glActiveTexture(GL_TEXTURE0); 
    glBindTexture(GL_TEXTURE_2D,inputTex);
    shader_.setInt("tex",0); 
    shader_.setVec2("cen",center_); 
    shader_.setFloat("str",strength_);
    glBindVertexArray(vao_); 
    glDrawArrays(GL_TRIANGLES,0,6);
}
''')
    
    # EffectManager.h
    write_file("src/effects/EffectManager.h", '''#pragma once
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
''')
    
    # EffectManager.cpp
    write_file("src/effects/EffectManager.cpp", '''#include "EffectManager.h"

void EffectManager::ensure(int w,int h) { 
    if (w_!=w||h_!=h) { 
        w_=w; h_=h;
        buf_[0]=std::make_unique<Framebuffer>(w,h);
        buf_[1]=std::make_unique<Framebuffer>(w,h);
    } 
}

uint32_t EffectManager::render(uint32_t inputTex,int w,int h) {
    ensure(w,h); 
    uint32_t cur=inputTex; 
    int pp=0;
    for (auto& e : effects_) { 
        if (!e->isEnabled()) continue; 
        uint32_t out=buf_[pp]->getTexture(); 
        e->render(cur,out,w,h); 
        cur=out; 
        pp=1-pp; 
    }
    return cur;
}
''')
    
    # FaceTracker.h
    write_file("src/tracking/FaceTracker.h", '''#pragma once
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
''')
    
    # FaceTracker.cpp
    write_file("src/tracking/FaceTracker.cpp", '''#include "FaceTracker.h"
#include "../effects/Effect.h"
#include <iostream>

bool FaceTracker::init() {
    if (!cascade_.load("assets/haarcascade_frontalface_default.xml")) { 
        std::cerr << "No cascade!\\n"; 
        return false; 
    }
    ready_=true; 
    return true;
}

bool FaceTracker::detect(const cv::Mat& frame, std::vector<Face>& faces) {
    faces.clear(); 
    if (!ready_) return false;
    cv::Mat gray; 
    cv::cvtColor(frame,gray,cv::COLOR_BGR2GRAY);
    std::vector<cv::Rect> rects; 
    cascade_.detectMultiScale(gray,rects,1.1,3,0,cv::Size(80,80));
    
    for (auto& r : rects) { 
        Face f; 
        f.box=r; 
        f.id=nextId_++; 
        f.conf=0.9f; 
        f.pos=glm::vec3(0); 
        f.rot=glm::vec3(0);
        f.landmarks68.push_back(glm::vec2(r.x/(float)frame.cols,r.y/(float)frame.rows));
        f.landmarks68.push_back(glm::vec2((r.x+r.width)/(float)frame.cols,(r.y+r.height)/(float)frame.rows));
        faces.push_back(f); 
    }
    return !faces.empty();
}
''')
    
    # main_effects.cpp
    write_file("src/main_effects.cpp", '''#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <opencv2/opencv.hpp>
#include <iostream>
#include <memory>
#include "effects/EffectManager.h"
#include "effects/Filter2D.h"
#include "effects/Distortion2D.h"
#include "tracking/FaceTracker.h"

std::unique_ptr<EffectManager> g_efx;
std::unique_ptr<FaceTracker> g_face;
cv::VideoCapture g_cam;
GLuint g_tex = 0;
const int W = 1280, H = 720;

void fb_cb(GLFWwindow* win, int w, int h) { glViewport(0,0,w,h); }

void key_cb(GLFWwindow* win, int key, int sc, int act, int mods) {
    if (act==GLFW_PRESS) {
        if (key==GLFW_KEY_1) { 
            g_efx->add(std::make_shared<Filter2D>()); 
            std::cout << "Filter added\\n"; 
        }
        if (key==GLFW_KEY_2) { 
            g_efx->add(std::make_shared<Distortion2D>(Distortion2D::FISHEYE)); 
            std::cout << "Fisheye added\\n"; 
        }
        if (key==GLFW_KEY_3) { 
            g_efx->add(std::make_shared<Distortion2D>(Distortion2D::TWIRL)); 
            std::cout << "Twirl added\\n"; 
        }
        if (key==GLFW_KEY_C) { 
            g_efx->clear(); 
            std::cout << "Cleared\\n"; 
        }
        if (key==GLFW_KEY_ESCAPE) 
            glfwSetWindowShouldClose(win,1);
    }
}

int main() {
    if (!glfwInit()) return -1;
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR,3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR,3);
    glfwWindowHint(GLFW_OPENGL_PROFILE,GLFW_OPENGL_CORE_PROFILE);
    
    GLFWwindow* win = glfwCreateWindow(W,H,"VFC_Kimi Effects",nullptr,nullptr);
    if (!win) return -1;
    
    glfwMakeContextCurrent(win);
    glfwSetFramebufferSizeCallback(win,fb_cb);
    glfwSetKeyCallback(win,key_cb);
    
    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) return -1;

    g_cam.open(0); 
    g_cam.set(cv::CAP_PROP_FRAME_WIDTH,W);
    g_cam.set(cv::CAP_PROP_FRAME_HEIGHT,H);
    
    glGenTextures(1,&g_tex); 
    glBindTexture(GL_TEXTURE_2D,g_tex);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);

    g_efx = std::make_unique<EffectManager>();
    g_face = std::make_unique<FaceTracker>(); 
    g_face->init();

    float qv[24] = {-1,1,0,1,-1,-1,0,0,1,-1,1,0,-1,1,0,1,1,-1,1,0,1,1,1,1};
    GLuint vao,vbo; 
    glGenVertexArrays(1,&vao); 
    glGenBuffers(1,&vbo);
    glBindVertexArray(vao); 
    glBindBuffer(GL_ARRAY_BUFFER,vbo);
    glBufferData(GL_ARRAY_BUFFER,sizeof(qv),qv,GL_STATIC_DRAW);
    glEnableVertexAttribArray(0); 
    glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,16,(void*)0);
    glEnableVertexAttribArray(1); 
    glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,16,(void*)8);

    const char* vs = "#version 330 core\\nlayout(location=0) in vec2 p;\\nlayout(location=1) in vec2 t;\\nout vec2 vT;\\nvoid main(){gl_Position=vec4(p,0,1);vT=t;}";
    const char* fs = "#version 330 core\\nin vec2 vT;\\nout vec4 c;\\nuniform sampler2D tex;\\nvoid main(){c=texture(tex,vT);}";
    
    GLuint prog = glCreateProgram(), vsh = glCreateShader(GL_VERTEX_SHADER), fsh = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(vsh,1,&vs,nullptr); 
    glShaderSource(fsh,1,&fs,nullptr);
    glCompileShader(vsh); 
    glCompileShader(fsh);
    glAttachShader(prog,vsh); 
    glAttachShader(prog,fsh); 
    glLinkProgram(prog);

    std::cout << "=== VFC_Kimi Effects ===\\n";
    std::cout << "1=Filter 2=Fisheye 3=Twirl C=Clear ESC=Exit\\n";

    cv::Mat frame;
    while (!glfwWindowShouldClose(win)) {
        glfwPollEvents();
        g_cam >> frame; 
        if (frame.empty()) continue;
        
        glBindTexture(GL_TEXTURE_2D,g_tex);
        glTexImage2D(GL_TEXTURE_2D,0,GL_RGB,frame.cols,frame.rows,0,GL_BGR,GL_UNSIGNED_BYTE,frame.data);
        
        std::vector<FaceTracker::Face> faces; 
        if (g_face->detect(frame,faces)) { 
            for (auto& f : faces) { 
                FaceData d; 
                d.landmarks=f.landmarks68; 
                d.position=f.pos; 
                d.rotation=f.rot; 
                d.confidence=f.conf; 
                g_efx->onFace(d); 
            } 
        }
        
        g_efx->update(0.016f);
        uint32_t finalTex = g_efx->render(g_tex,frame.cols,frame.rows);
        
        glBindFramebuffer(GL_FRAMEBUFFER,0); 
        glClear(GL_COLOR_BUFFER_BIT);
        glUseProgram(prog); 
        glActiveTexture(GL_TEXTURE0); 
        glBindTexture(GL_TEXTURE_2D,finalTex);
        glUniform1i(glGetUniformLocation(prog,"tex"),0); 
        glBindVertexArray(vao); 
        glDrawArrays(GL_TRIANGLES,0,6);
        
        glfwSwapBuffers(win);
    }
    
    glfwTerminate(); 
    g_cam.release(); 
    return 0;
}
''')
    
    print("\n=== Setup Complete! ===")
    print("\nFiles created:")
    for root, dirs, files in os.walk(os.path.join(BASE_DIR, "src")):
        for f in files:
            if f.endswith(('.h', '.cpp')):
                print(f"  {os.path.join(root, f).replace(BASE_DIR+'/', '')}")
    
    print("\nNEXT STEPS:")
    print("1. Download haarcascade_frontalface_default.xml to assets/")
    print("   From: https://github.com/opencv/opencv/raw/master/data/haarcascades/haarcascade_frontalface_default.xml")
    print("2. Update CMakeLists.txt to use src/main_effects.cpp instead of src/main.cpp")
    print("3. cd build && cmake .. && cmake --build . --config Release")
    print("4. Run: Release\\VFC_Kimi.exe")
    print("\nControls:")
    print("  1 = Add color filter")
    print("  2 = Add fisheye distortion")
    print("  3 = Add twirl distortion")
    print("  C = Clear all effects")
    print("  ESC = Exit")

if __name__ == "__main__":
    main()