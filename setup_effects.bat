@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

REM Create log file
echo Starting setup... > setup_log.txt
echo Current directory: %CD% >> setup_log.txt

REM Check if we're in the right place
if not exist "src" (
    echo ERROR: src folder not found! >> setup_log.txt
    echo ERROR: Please run this from VFC_Kimi folder
    pause
    exit /b 1
)

echo Creating directories...
mkdir "src\graphics" 2>nul
mkdir "src\effects" 2>nul
mkdir "src\media" 2>nul
mkdir "src\utils" 2>nul
mkdir "assets\shaders\2d" 2>nul
mkdir "assets\shaders\3d" 2>nul
mkdir "assets\shaders\face" 2>nul
mkdir "assets\textures\luts" 2>nul
mkdir "assets\models" 2>nul
mkdir "assets\effects" 2>nul
mkdir "third_party" 2>nul

echo Creating Framebuffer.h...
(
echo #pragma once
echo #include ^<glad/glad.h^>
echo #include ^<cstdint^>
echo.
echo class Framebuffer {
echo public:
echo     Framebuffer(int width, int height^);
echo     ~Framebuffer(^);
echo     void bind(^) const;
echo     void unbind(^) const;
echo     void resize(int width, int height^);
echo     uint32_t getTexture(^) const { return colorTexture_; }
echo private:
echo     uint32_t fbo_ = 0, colorTexture_ = 0, depthTexture_ = 0;
echo     int width_, height_;
echo     void create(^);
echo     void destroy(^);
echo };
) > "src\graphics\Framebuffer.h"

echo Creating Framebuffer.cpp...
(
echo #include "Framebuffer.h"
echo #include ^<iostream^>
echo Framebuffer::Framebuffer(int width, int height^) : width_(width^), height_(height^) { create(^); }
echo Framebuffer::~Framebuffer(^) { destroy(^); }
echo void Framebuffer::create(^) {
echo     glGenFramebuffers(1, ^&fbo_^);
echo     glBindFramebuffer(GL_FRAMEBUFFER, fbo_^);
echo     glGenTextures(1, ^&colorTexture_^);
echo     glBindTexture(GL_TEXTURE_2D, colorTexture_^);
echo     glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width_, height_, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr^);
echo     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR^);
echo     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR^);
echo     glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, colorTexture_, 0^);
echo     glGenTextures(1, ^&depthTexture_^);
echo     glBindTexture(GL_TEXTURE_2D, depthTexture_^);
echo     glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT24, width_, height_, 0, GL_DEPTH_COMPONENT, GL_FLOAT, nullptr^);
echo     glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, depthTexture_, 0^);
echo     if (glCheckFramebufferStatus(GL_FRAMEBUFFER^) != GL_FRAMEBUFFER_COMPLETE^) std::cerr ^<^< "Framebuffer incomplete!\n"^;
echo     glBindFramebuffer(GL_FRAMEBUFFER, 0^);
echo }
echo void Framebuffer::destroy(^) {
echo     if (fbo_^) glDeleteFramebuffers(1, ^&fbo_^);
echo     if (colorTexture_^) glDeleteTextures(1, ^&colorTexture_^);
echo     if (depthTexture_^) glDeleteTextures(1, ^&depthTexture_^);
echo }
echo void Framebuffer::bind(^) const { glBindFramebuffer(GL_FRAMEBUFFER, fbo_^); glViewport(0, 0, width_, height_^); }
echo void Framebuffer::unbind(^) const { glBindFramebuffer(GL_FRAMEBUFFER, 0^); }
echo void Framebuffer::resize(int width, int height^) { destroy(^); width_ = width; height_ = height; create(^); }
) > "src\graphics\Framebuffer.cpp"

echo Creating Shader.h...
(
echo #pragma once
echo #include ^<string^>
echo #include ^<glad/glad.h^>
echo #include ^<glm/glm.hpp^>
echo class Shader {
echo public:
echo     Shader(^) {}
echo     ~Shader(^) { if (program_^) glDeleteProgram(program_^); }
echo     bool loadFromStrings(const std::string^& vert, const std::string^& frag^);
echo     void use(^) const { glUseProgram(program_^); }
echo     void setInt(const std::string^& n, int v^) { glUniform1i(glGetUniformLocation(program_, n.c_str(^)^), v^); }
echo     void setFloat(const std::string^& n, float v^) { glUniform1f(glGetUniformLocation(program_, n.c_str(^)^), v^); }
echo     void setVec2(const std::string^& n, const glm::vec2^& v^) { glUniform2fv(glGetUniformLocation(program_, n.c_str(^)^), 1, ^&v[0]^); }
echo     void setMat4(const std::string^& n, const glm::mat4^& v^) { glUniformMatrix4fv(glGetUniformLocation(program_, n.c_str(^)^), 1, GL_FALSE, ^&v[0][0]^); }
echo private:
echo     uint32_t program_ = 0;
echo };
) > "src\graphics\Shader.h"

echo Creating Shader.cpp...
(
echo #include "Shader.h"
echo #include ^<iostream^>
echo bool Shader::loadFromStrings(const std::string^& vertSrc, const std::string^& fragSrc^) {
echo     uint32_t vs = glCreateShader(GL_VERTEX_SHADER^);
echo     const char* v = vertSrc.c_str(^);
echo     glShaderSource(vs, 1, ^&v, nullptr^);
echo     glCompileShader(vs^);
echo     uint32_t fs = glCreateShader(GL_FRAGMENT_SHADER^);
echo     const char* f = fragSrc.c_str(^);
echo     glShaderSource(fs, 1, ^&f, nullptr^);
echo     glCompileShader(fs^);
echo     program_ = glCreateProgram(^);
echo     glAttachShader(program_, vs^);
echo     glAttachShader(program_, fs^);
echo     glLinkProgram(program_^);
echo     glDeleteShader(vs^);
echo     glDeleteShader(fs^);
echo     return true;
echo }
) > "src\graphics\Shader.cpp"

echo Creating Effect.h...
(
echo #pragma once
echo #include ^<string^>
echo #include ^<map^>
echo #include ^<glm/glm.hpp^>
echo struct FaceData {
echo     std::vector^<glm::vec2^> landmarks;
echo     glm::vec3 position, rotation;
echo     float confidence;
echo };
echo class Effect {
echo public:
echo     enum Type { FILTER_2D, DISTORT_2D, OVERLAY_3D, FACE_MESH };
echo     Effect(Type t, const std::string^& n^) : type_(t^), name_(n^) {}
echo     virtual ~Effect(^) = default;
echo     virtual void init(^) = 0;
echo     virtual void update(float dt^) = 0;
echo     virtual void render(uint32_t inputTex, uint32_t outFBO, int w, int h^) = 0;
echo     virtual void onFace(const FaceData^& f^) {}
echo     void setEnabled(bool e^) { enabled_ = e; }
echo     bool isEnabled(^) const { return enabled_; }
echo     Type getType(^) const { return type_; }
echo     const std::string^& getName(^) const { return name_; }
echo protected:
echo     Type type_; std::string name_; bool enabled_ = true;
echo     std::map^<std::string, float^> fParams_;
echo };
) > "src\effects\Effect.h"

echo Creating Filter2D.h...
(
echo #pragma once
echo #include "Effect.h"
echo #include "../graphics/Shader.h"
echo class Filter2D : public Effect {
echo public:
echo     Filter2D(^) : Effect(FILTER_2D, "Color Filter"^) {}
echo     ~Filter2D(^);
echo     void init(^) override;
echo     void update(float dt^) override {}
echo     void render(uint32_t inputTex, uint32_t outFBO, int w, int h^) override;
echo private:
echo     Shader shader_;
echo     uint32_t vao_ = 0, vbo_ = 0;
echo     void createQuad(^);
echo };
) > "src\effects\Filter2D.h"

echo Creating Filter2D.cpp...
(
echo #include "Filter2D.h"
echo Filter2D::~Filter2D(^) { if (vao_^) glDeleteVertexArrays(1, ^&vao_^); if (vbo_^) glDeleteBuffers(1, ^&vbo_^); }
echo void Filter2D::init(^) {
echo     const char* v = R"(#version 330 core
echo layout(location=0^) in vec2 p; layout(location=1^) in vec2 t; out vec2 vT; void main(^) { gl_Position=vec4(p,0,1^); vT=t; })";
echo     const char* f = R"(#version 330 core
echo in vec2 vT; out vec4 c; uniform sampler2D tex; uniform float bright, contrast, sat;
echo vec3 b(vec3 x,float v^) { return x+v; }
echo vec3 ct(vec3 x,float v^) { return (x-0.5^)*(1.0+v^)+0.5; }
echo vec3 s(vec3 x,float v^) { float g=dot(x,vec3(0.299,0.587,0.114^)^); return mix(vec3(g^),x,1.0+v^); }
echo void main(^) { vec4 x=texture(tex,vT^); vec3 r=b(x.rgb,bright^); r=ct(r,contrast^); r=s(r,sat^); c=vec4(r,x.a^); })";
echo     shader_.loadFromStrings(v,f^);
echo     createQuad(^);
echo     fParams_["bright"] = 0.0f; fParams_["contrast"] = 0.0f; fParams_["sat"] = 0.0f;
echo }
echo void Filter2D::createQuad(^) {
echo     float v[24] = {-1,1,0,1, -1,-1,0,0, 1,-1,1,0, -1,1,0,1, 1,-1,1,0, 1,1,1,1};
echo     glGenVertexArrays(1,^&vao_^); glGenBuffers(1,^&vbo_^);
echo     glBindVertexArray(vao_^); glBindBuffer(GL_ARRAY_BUFFER,vbo_^);
echo     glBufferData(GL_ARRAY_BUFFER,sizeof(v^),v,GL_STATIC_DRAW^);
echo     glEnableVertexAttribArray(0^); glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,16,^(void*^)0^);
echo     glEnableVertexAttribArray(1^); glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,16,^(void*^)8^);
echo }
echo void Filter2D::render(uint32_t inputTex, uint32_t outFBO, int w, int h^) {
echo     glBindFramebuffer(GL_FRAMEBUFFER,outFBO^);
echo     shader_.use(^);
echo     glActiveTexture(GL_TEXTURE0^); glBindTexture(GL_TEXTURE_2D,inputTex^);
echo     shader_.setInt("tex",0^);
echo     shader_.setFloat("bright",fParams_["bright"]^);
echo     shader_.setFloat("contrast",fParams_["contrast"]^);
echo     shader_.setFloat("sat",fParams_["sat"]^);
echo     glBindVertexArray(vao_^); glDrawArrays(GL_TRIANGLES,0,6^);
echo }
) > "src\effects\Filter2D.cpp"

echo Creating Distortion2D.h...
(
echo #pragma once
echo #include "Effect.h"
echo #include "../graphics/Shader.h"
echo class Distortion2D : public Effect {
echo public:
echo     enum Mode { FISHEYE, TWIRL, BARREL };
echo     Distortion2D(Mode m^) : Effect(DISTORT_2D,"Distortion"^), mode_(m^) {}
echo     ~Distortion2D(^);
echo     void init(^) override;
echo     void update(float dt^) override {}
echo     void render(uint32_t inputTex, uint32_t outFBO, int w, int h^) override;
echo     void setCenter(const glm::vec2^& c^) { center_ = c; }
echo     void setStrength(float s^) { strength_ = s; }
echo private:
echo     Mode mode_;
echo     Shader shader_;
echo     uint32_t vao_ = 0, vbo_ = 0;
echo     glm::vec2 center_ = glm::vec2(0.5f,0.5f^);
echo     float strength_ = 0.5f;
echo     void createQuad(^);
echo     const char* getFrag(^);
echo };
) > "src\effects\Distortion2D.h"

echo Creating Distortion2D.cpp...
(
echo #include "Distortion2D.h"
echo Distortion2D::~Distortion2D(^) { if (vao_^) glDeleteVertexArrays(1, ^&vao_^); if (vbo_^) glDeleteBuffers(1, ^&vbo_^); }
echo const char* Distortion2D::getFrag(^) {
echo     if (mode_==FISHEYE^) return R"(#version 330 core
echo in vec2 vT; out vec4 c; uniform sampler2D tex; uniform vec2 cen; uniform float str;
echo const float PI=3.14159265;
echo void main(^) { vec2 p=vT-cen; float d=length(p^)*2.0; float a=atan(p.y,p.x^);
echo float nd=tan(d*str*PI*0.5^)/tan(str*PI*0.5^); vec2 nt=cen+vec2(cos(a^),sin(a^)^)*nd*0.5;
echo c=texture(tex,clamp(nt,0.0,1.0^)^); })";
echo     if (mode_==TWIRL^) return R"(#version 330 core
echo in vec2 vT; out vec4 c; uniform sampler2D tex; uniform vec2 cen; uniform float str;
echo void main(^) { vec2 p=vT-cen; float d=length(p^); float a=atan(p.y,p.x^)+str*(1.0-d^)*3.14159;
echo vec2 nt=cen+d*vec2(cos(a^),sin(a^)^); c=texture(tex,nt^); })";
echo     return R"(#version 330 core
echo in vec2 vT; out vec4 c; uniform sampler2D tex; uniform vec2 cen; uniform float str;
echo void main(^) { vec2 p=vT-cen; float d=length(p^); float r=d*(1.0+str*d*d^);
echo vec2 nt=cen+normalize(p^)*r; c=texture(tex,nt^); })";
echo }
echo void Distortion2D::init(^) {
echo     const char* v = R"(#version 330 core
echo layout(location=0^) in vec2 p; layout(location=1^) in vec2 t; out vec2 vT; void main(^) { gl_Position=vec4(p,0,1^); vT=t; })";
echo     shader_.loadFromStrings(v,getFrag(^)^);
echo     createQuad(^);
echo }
echo void Distortion2D::createQuad(^) {
echo     float v[24] = {-1,1,0,1, -1,-1,0,0, 1,-1,1,0, -1,1,0,1, 1,-1,1,0, 1,1,1,1};
echo     glGenVertexArrays(1,^&vao_^); glGenBuffers(1,^&vbo_^);
echo     glBindVertexArray(vao_^); glBindBuffer(GL_ARRAY_BUFFER,vbo_^);
echo     glBufferData(GL_ARRAY_BUFFER,sizeof(v^),v,GL_STATIC_DRAW^);
echo     glEnableVertexAttribArray(0^); glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,16,^(void*^)0^);
echo     glEnableVertexAttribArray(1^); glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,16,^(void*^)8^);
echo }
echo void Distortion2D::render(uint32_t inputTex, uint32_t outFBO, int w, int h^) {
echo     glBindFramebuffer(GL_FRAMEBUFFER,outFBO^);
echo     shader_.use(^);
echo     glActiveTexture(GL_TEXTURE0^); glBindTexture(GL_TEXTURE_2D,inputTex^);
echo     shader_.setInt("tex",0^); shader_.setVec2("cen",center_^); shader_.setFloat("str",strength_^);
echo     glBindVertexArray(vao_^); glDrawArrays(GL_TRIANGLES,0,6^);
echo }
) > "src\effects\Distortion2D.cpp"

echo Creating EffectManager.h...
(
echo #pragma once
echo #include ^<memory^>
echo #include ^<vector^>
echo #include "Effect.h"
echo #include "../graphics/Framebuffer.h"
echo class EffectManager {
echo public:
echo     EffectManager(^) {}
echo     ~EffectManager(^) {}
echo     void add(std::shared_ptr^<Effect^> e^) { e->init(^); effects_.push_back(e^); }
echo     void clear(^) { effects_.clear(^); }
echo     void update(float dt^) { for (auto^& e : effects_^) if (e->isEnabled(^)^) e->update(dt^); }
echo     uint32_t render(uint32_t inputTex, int w, int h^);
echo     void onFace(const FaceData^& f^) { for (auto^& e : effects_^) e->onFace(f^); }
echo private:
echo     std::vector^<std::shared_ptr^<Effect^>^> effects_;
echo     std::unique_ptr^<Framebuffer^> buf_[2];
echo     int w_=0,h_=0;
echo     void ensure(int w,int h^);
echo };
) > "src\effects\EffectManager.h"

echo Creating EffectManager.cpp...
(
echo #include "EffectManager.h"
echo void EffectManager::ensure(int w,int h^) { if (w_!=w^|^|h_!=h^) { w_=w;h_=h;buf_[0]=std::make_unique^<Framebuffer^>(w,h^);buf_[1]=std::make_unique^<Framebuffer^>(w,h^);} }
echo uint32_t EffectManager::render(uint32_t inputTex,int w,int h^) {
echo     ensure(w,h^); uint32_t cur=inputTex; int pp=0;
echo     for (auto^& e : effects_^) { if (!e->isEnabled(^)^) continue; uint32_t out=buf_[pp]->getTexture(^); e->render(cur,out,w,h^); cur=out; pp=1-pp; }
echo     return cur;
echo }
) > "src\effects\EffectManager.cpp"

echo Creating FaceTracker.h...
(
echo #pragma once
echo #include ^<opencv2/opencv.hpp^>
echo #include ^<vector^>
echo #include ^<glm/glm.hpp^>
echo struct FaceData;
echo class FaceTracker {
echo public:
echo     struct Face { std::vector^<glm::vec2^> landmarks68; cv::Rect box; glm::vec3 pos,rot; float conf; int id; };
echo     FaceTracker(^) {}
echo     bool init(^);
echo     bool detect(const cv::Mat^& frame, std::vector^<Face^>^& faces^);
echo private:
echo     cv::CascadeClassifier cascade_;
echo     bool ready_ = false;
echo     int nextId_ = 0;
echo };
) > "src\tracking\FaceTracker.h"

echo Creating FaceTracker.cpp...
(
echo #include "FaceTracker.h"
echo #include "../effects/Effect.h"
echo #include ^<iostream^>
echo bool FaceTracker::init(^) {
echo     if (!cascade_.load("assets/haarcascade_frontalface_default.xml"^)^) { std::cerr ^<^< "No cascade!\n"; return false; }
echo     ready_=true; return true;
echo }
echo bool FaceTracker::detect(const cv::Mat^& frame, std::vector^<Face^>^& faces^) {
echo     faces.clear(^); if (!ready_^) return false;
echo     cv::Mat gray; cv::cvtColor(frame,gray,cv::COLOR_BGR2GRAY^);
echo     std::vector^<cv::Rect^> rects; cascade_.detectMultiScale(gray,rects,1.1,3,0,cv::Size(80,80^)^);
echo     for (auto^& r : rects^) { Face f; f.box=r; f.id=nextId_++; f.conf=0.9f; f.pos=glm::vec3(0^); f.rot=glm::vec3(0^);
echo     f.landmarks68.push_back(glm::vec2(r.x/(float^)frame.cols,r.y/(float^)frame.rows^)^);
echo     f.landmarks68.push_back(glm::vec2((r.x+r.width^)/(float^)frame.cols,(r.y+r.height^)/(float^)frame.rows^)^);
echo     faces.push_back(f^); }
echo     return !faces.empty(^);
echo }
) > "src\tracking\FaceTracker.cpp"

echo Creating main_effects.cpp...
(
echo #include ^<glad/glad.h^>
echo #include ^<GLFW/glfw3.h^>
echo #include ^<opencv2/opencv.hpp^>
echo #include ^<iostream^>
echo #include ^<memory^>
echo #include "effects/EffectManager.h"
echo #include "effects/Filter2D.h"
echo #include "effects/Distortion2D.h"
echo #include "tracking/FaceTracker.h"
echo.
echo std::unique_ptr^<EffectManager^> g_efx;
echo std::unique_ptr^<FaceTracker^> g_face;
echo cv::VideoCapture g_cam;
echo GLuint g_tex = 0;
echo const int W = 1280, H = 720;
echo.
echo void fb_cb(GLFWwindow* win, int w, int h^) { glViewport(0,0,w,h^); }
echo.
echo void key_cb(GLFWwindow* win, int key, int sc, int act, int mods^) {
echo     if (act==GLFW_PRESS^) {
echo         if (key==GLFW_KEY_1^) { g_efx->add(std::make_shared^<Filter2D^>(^)^); std::cout ^<^< "Filter added\n"; }
echo         if (key==GLFW_KEY_2^) { g_efx->add(std::make_shared^<Distortion2D^>(Distortion2D::FISHEYE^)^); std::cout ^<^< "Fisheye added\n"; }
echo         if (key==GLFW_KEY_3^) { g_efx->add(std::make_shared^<Distortion2D^>(Distortion2D::TWIRL^)^); std::cout ^<^< "Twirl added\n"; }
echo         if (key==GLFW_KEY_C^) { g_efx->clear(^); std::cout ^<^< "Cleared\n"; }
echo         if (key==GLFW_KEY_ESCAPE^) glfwSetWindowShouldClose(win,1^);
echo     }
echo }
echo.
echo int main(^) {
echo     if (!glfwInit(^)^) return -1;
echo     glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR,3^);
echo     glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR,3^);
echo     glfwWindowHint(GLFW_OPENGL_PROFILE,GLFW_OPENGL_CORE_PROFILE^);
echo     GLFWwindow* win = glfwCreateWindow(W,H,"VFC_Kimi Effects",nullptr,nullptr^);
echo     if (!win^) return -1;
echo     glfwMakeContextCurrent(win^);
echo     glfwSetFramebufferSizeCallback(win,fb_cb^);
echo     glfwSetKeyCallback(win,key_cb^);
echo     if (!gladLoadGLLoader((GLADloadproc^)glfwGetProcAddress^)^) return -1;
echo.
echo     g_cam.open(0^); g_cam.set(cv::CAP_PROP_FRAME_WIDTH,W^); g_cam.set(cv::CAP_PROP_FRAME_HEIGHT,H^);
echo     glGenTextures(1,^&g_tex^); glBindTexture(GL_TEXTURE_2D,g_tex^);
echo     glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR^);
echo     glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR^);
echo.
echo     g_efx = std::make_unique^<EffectManager^>(^);
echo     g_face = std::make_unique^<FaceTracker^>(^); g_face->init(^);
echo.
echo     float qv[24] = {-1,1,0,1,-1,-1,0,0,1,-1,1,0,-1,1,0,1,1,-1,1,0,1,1,1,1};
echo     GLuint vao,vbo; glGenVertexArrays(1,^&vao^); glGenBuffers(1,^&vbo^);
echo     glBindVertexArray(vao^); glBindBuffer(GL_ARRAY_BUFFER,vbo^);
echo     glBufferData(GL_ARRAY_BUFFER,sizeof(qv^),qv,GL_STATIC_DRAW^);
echo     glEnableVertexAttribArray(0^); glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,16,^(void*^)0^);
echo     glEnableVertexAttribArray(1^); glVertexAttribPointer(1,2,GL_FLOAT,GL_FALSE,16,^(void*^)8^);
echo.
echo     const char* vs = "layout(location=0^) in vec2 p; layout(location=1^) in vec2 t; out vec2 vT; void main(^){gl_Position=vec4(p,0,1^);vT=t;}";
echo     const char* fs = "in vec2 vT; out vec4 c; uniform sampler2D tex; void main(^){c=texture(tex,vT^);}";
echo     GLuint prog = glCreateProgram(^), vsh = glCreateShader(GL_VERTEX_SHADER^), fsh = glCreateShader(GL_FRAGMENT_SHADER^);
echo     glShaderSource(vsh,1,^&vs,nullptr^); glShaderSource(fsh,1,^&fs,nullptr^);
echo     glCompileShader(vsh^); glCompileShader(fsh^);
echo     glAttachShader(prog,vsh^); glAttachShader(prog,fsh^); glLinkProgram(prog^);
echo.
echo     std::cout ^<^< "=== VFC_Kimi Effects ===\n1=Filter 2=Fisheye 3=Twirl C=Clear ESC=Exit\n";
echo     cv::Mat frame;
echo     while (!glfwWindowShouldClose(win^)^) {
echo         glfwPollEvents(^);
echo         g_cam ^>^> frame; if (frame.empty(^)^) continue;
echo         glBindTexture(GL_TEXTURE_2D,g_tex^);
echo         glTexImage2D(GL_TEXTURE_2D,0,GL_RGB,frame.cols,frame.rows,0,GL_BGR,GL_UNSIGNED_BYTE,frame.data^);
echo         std::vector^<FaceTracker::Face^> faces; if (g_face->detect(frame,faces^)^) { for (auto^& f : faces^) { FaceData d; d.landmarks=f.landmarks68; d.position=f.pos; d.rotation=f.rot; d.confidence=f.conf; g_efx->onFace(d^); } }
echo         g_efx->update(0.016f^);
echo         uint32_t finalTex = g_efx->render(g_tex,frame.cols,frame.rows^);
echo         glBindFramebuffer(GL_FRAMEBUFFER,0^); glClear(GL_COLOR_BUFFER_BIT^);
echo         glUseProgram(prog^); glActiveTexture(GL_TEXTURE0^); glBindTexture(GL_TEXTURE_2D,finalTex^);
echo         glUniform1i(glGetUniformLocation(prog,"tex"^),0^); glBindVertexArray(vao^); glDrawArrays(GL_TRIANGLES,0,6^);
echo         glfwSwapBuffers(win^);
echo     }
echo     glfwTerminate(^); g_cam.release(^); return 0;
echo }
) > "src\main_effects.cpp"

echo Updating CMakeLists.txt...
(
echo cmake_minimum_required(VERSION 3.10^)
echo project(VFC_Kimi^)
echo set(CMAKE_CXX_STANDARD 17^)
echo find_package(OpenCV REQUIRED^)
echo find_package(glfw3 REQUIRED^)
echo find_package(OpenGL REQUIRED^)
echo add_library(glad STATIC include/glad.c^)
echo target_include_directories(glad PUBLIC include/^)
echo add_executable(${PROJECT_NAME}
echo     src/main_effects.cpp
echo     src/graphics/Framebuffer.cpp
echo     src/graphics/Shader.cpp
echo     src/effects/Filter2D.cpp
echo     src/effects/Distortion2D.cpp
echo     src/effects/EffectManager.cpp
echo     src/tracking/FaceTracker.cpp
echo     src/camera/WebcamCapture.cpp
echo     src/core/Window.cpp
echo ^)
echo target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/include ${CMAKE_SOURCE_DIR}/src ${OpenCV_INCLUDE_DIRS}^)
echo target_link_libraries(${PROJECT_NAME} glad glfw OpenGL::GL ${OpenCV_LIBS}^)
) > CMakeLists_new.txt

echo.
echo ==========================================
echo SETUP COMPLETE!
echo ==========================================
echo.
echo Files created:
dir /s /b src\graphics src\effects src\tracking 2>nul | findstr /i "\.h \.cpp"
echo.
echo NEXT STEPS:
echo 1. Copy haarcascade_frontalface_default.xml to assets\
echo 2. Rename CMakeLists_new.txt to CMakeLists.txt (or merge^)
echo 3. cd build ^&^& cmake .. ^&^& cmake --build . --config Release
echo.
pause