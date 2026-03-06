@echo off
setlocal EnableDelayedExpansion
echo ==========================================
echo VFC_Kimi Effects System Setup
echo ==========================================
echo.

set PROJECT_ROOT=%~dp0
cd /d "%PROJECT_ROOT%"

:: Create directory structure
echo [1/8] Creating directory structure...
mkdir src\graphics 2>nul
mkdir src\effects 2>nul
mkdir src\media 2>nul
mkdir src\utils 2>nul
mkdir assets\shaders\2d 2>nul
mkdir assets\shaders\3d 2>nul
mkdir assets\shaders\face 2>nul
mkdir assets\textures\luts 2>nul
mkdir assets\models 2>nul
mkdir assets\effects 2>nul
mkdir third_party 2>nul
echo Directory structure created.
echo.

:: Create Framebuffer.h
echo [2/8] Creating Graphics classes...
(
echo #pragma once
echo #include ^<glad/glad.h^>
echo #include ^<cstdint^>
echo.
echo class Framebuffer {
echo public:
echo     Framebuffer^(%1int width, int height%2^);
echo     ~Framebuffer^(^);
echo.
echo     void bind^(^) const;
echo     void unbind^(^) const;
echo     void resize^(%1int width, int height%2^);
echo     uint32_t getTexture^(^) const { return colorTexture_; }
echo.
echo private:
echo     uint32_t fbo_ = 0;
echo     uint32_t colorTexture_ = 0;
echo     uint32_t depthTexture_ = 0;
echo     int width_, height_;
echo.
echo     void create^(^);
echo     void destroy^(^);
echo };
) > src\graphics\Framebuffer.h

:: Create Framebuffer.cpp
(
echo #include "Framebuffer.h"
echo #include ^<iostream^>
echo.
echo Framebuffer::Framebuffer^(%1int width, int height%2^) 
echo     : width_(width^), height_(height^) {
echo     create^(^);
echo }
echo.
echo Framebuffer::~Framebuffer^(^) {
echo     destroy^(^);
echo }
echo.
echo void Framebuffer::create^(^) {
echo     glGenFramebuffers^(1, ^&fbo_^);
echo     glBindFramebuffer^(GL_FRAMEBUFFER, fbo_^);
echo.
echo     // Color texture
echo     glGenTextures^(1, ^&colorTexture_^);
echo     glBindTexture^(GL_TEXTURE_2D, colorTexture_^);
echo     glTexImage2D^(GL_TEXTURE_2D, 0, GL_RGBA8, width_, height_, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr^);
echo     glTexParameteri^(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR^);
echo     glTexParameteri^(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR^);
echo     glFramebufferTexture2D^(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, colorTexture_, 0^);
echo.
echo     // Depth texture
echo     glGenTextures^(1, ^&depthTexture_^);
echo     glBindTexture^(GL_TEXTURE_2D, depthTexture_^);
echo     glTexImage2D^(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT24, width_, height_, 0, GL_DEPTH_COMPONENT, GL_FLOAT, nullptr^);
echo     glFramebufferTexture2D^(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, depthTexture_, 0^);
echo.
echo     if %1glCheckFramebufferStatus^(GL_FRAMEBUFFER^) != GL_FRAMEBUFFER_COMPLETE%2 {
echo         std::cerr ^<^< "Framebuffer incomplete!" ^<^< std::endl;
echo     }
echo     glBindFramebuffer^(GL_FRAMEBUFFER, 0^);
echo }
echo.
echo void Framebuffer::destroy^(^) {
echo     if %1fbo_%2 glDeleteFramebuffers^(1, ^&fbo_^);
echo     if %1colorTexture_%2 glDeleteTextures^(1, ^&colorTexture_^);
echo     if %1depthTexture_%2 glDeleteTextures^(1, ^&depthTexture_^);
echo }
echo.
echo void Framebuffer::bind^(^) const {
echo     glBindFramebuffer^(GL_FRAMEBUFFER, fbo_^);
echo     glViewport^(0, 0, width_, height_^);
echo }
echo.
echo void Framebuffer::unbind^(^) const {
echo     glBindFramebuffer^(GL_FRAMEBUFFER, 0^);
echo }
echo.
echo void Framebuffer::resize^(%1int width, int height%2^) {
echo     destroy^(^);
echo     width_ = width;
echo     height_ = height;
echo     create^(^);
echo }
) > src\graphics\Framebuffer.cpp

:: Create Shader.h
(
echo #pragma once
echo #include ^<string^>
echo #include ^<glad/glad.h^>
echo #include ^<glm/glm.hpp^>
echo.
echo class Shader {
echo public:
echo     Shader^(^);
echo     ~Shader^(^);
echo.
echo     bool loadFromFiles^(%1const std::string^& vertPath, const std::string^& fragPath%2^);
echo     bool loadFromStrings^(%1const std::string^& vertSource, const std::string^& fragSource%2^);
echo     void use^(^) const;
echo.
echo     void setInt^(%1const std::string^& name, int value%2^);
echo     void setFloat^(%1const std::string^& name, float value%2^);
echo     void setVec2^(%1const std::string^& name, const glm::vec2^& value%2^);
echo     void setVec3^(%1const std::string^& name, const glm::vec3^& value%2^);
echo     void setMat4^(%1const std::string^& name, const glm::mat4^& value%2^);
echo.
echo private:
echo     uint32_t program_ = 0;
echo     int getUniformLocation^(%1const std::string^& name%2^);
echo };
) > src\graphics\Shader.h

:: Create Shader.cpp
(
echo #include "Shader.h"
echo #include ^<iostream^>
echo #include ^<fstream^>
echo #include ^<sstream^>
echo.
echo Shader::Shader^(^) {}
echo.
echo Shader::~Shader^(^) {
echo     if %1program_%2 glDeleteProgram^(program_^);
echo }
echo.
echo bool Shader::loadFromFiles^(%1const std::string^& vertPath, const std::string^& fragPath%2^) {
echo     std::ifstream vFile^(vertPath^), fFile^(fragPath^);
echo     std::stringstream vStream, fStream;
echo     vStream ^<^< vFile.rdbuf^(^);
echo     fStream ^<^< fFile.rdbuf^(^);
echo     return loadFromStrings^(vStream.str^(^), fStream.str^(^)^);
echo }
echo.
echo bool Shader::loadFromStrings^(%1const std::string^& vertSource, const std::string^& fragSource%2^) {
echo     uint32_t vert = glCreateShader^(GL_VERTEX_SHADER^);
echo     const char* vSrc = vertSource.c_str^(^);
echo     glShaderSource^(vert, 1, ^&vSrc, nullptr^);
echo     glCompileShader^(vert^);
echo.
echo     uint32_t frag = glCreateShader^(GL_FRAGMENT_SHADER^);
echo     const char* fSrc = fragSource.c_str^(^);
echo     glShaderSource^(frag, 1, ^&fSrc, nullptr^);
echo     glCompileShader^(frag^);
echo.
echo     program_ = glCreateProgram^(^);
echo     glAttachShader^(program_, vert^);
echo     glAttachShader^(program_, frag^);
echo     glLinkProgram^(program_^);
echo.
echo     glDeleteShader^(vert^);
echo     glDeleteShader^(frag^);
echo     return true;
echo }
echo.
echo void Shader::use^(^) const {
echo     glUseProgram^(program_^);
echo }
echo.
echo void Shader::setInt^(%1const std::string^& name, int value%2^) {
echo     glUniform1i^(getUniformLocation^(name^), value^);
echo }
echo.
echo void Shader::setFloat^(%1const std::string^& name, float value%2^) {
echo     glUniform1f^(getUniformLocation^(name^), value^);
echo }
echo.
echo void Shader::setVec2^(%1const std::string^& name, const glm::vec2^& value%2^) {
echo     glUniform2fv^(getUniformLocation^(name^), 1, ^&value[0]^);
echo }
echo.
echo void Shader::setVec3^(%1const std::string^& name, const glm::vec3^& value%2^) {
echo     glUniform3fv^(getUniformLocation^(name^), 1, ^&value[0]^);
echo }
echo.
echo void Shader::setMat4^(%1const std::string^& name, const glm::mat4^& value%2^) {
echo     glUniformMatrix4fv^(getUniformLocation^(name^), 1, GL_FALSE, ^&value[0][0]^);
echo }
echo.
echo int Shader::getUniformLocation^(%1const std::string^& name%2^) {
echo     return glGetUniformLocation^(program_, name.c_str^(^)^);
echo }
) > src\graphics\Shader.cpp

echo Graphics classes created.
echo.

:: Create Effect base class
echo [3/8] Creating Effect system...
(
echo #pragma once
echo #include ^<string^>
echo #include ^<vector^>
echo #include ^<map^>
echo #include ^<glm/glm.hpp^>
echo #include "../graphics/Framebuffer.h"
echo.
echo struct FaceData {
echo     std::vector^<glm::vec2^> landmarks;  // Normalized 0-1
echo     glm::vec3 position;  // Head position in 3D
echo     glm::vec3 rotation;  // Head rotation Euler angles
echo     float confidence;
echo };
echo.
echo class Effect {
echo public:
echo     enum Type { FILTER_2D, DISTORT_2D, OVERLAY_3D, FACE_MESH, PARTICLE };
echo.
echo     Effect^(Type type, const std::string^& name^) : type_(type^), name_(name^) {}
echo     virtual ~Effect^(^) = default;
echo.
echo     virtual void init^(^) = 0;
echo     virtual void update^(%1float deltaTime%2^) = 0;
echo     virtual void render^(%1uint32_t inputTexture, uint32_t outputFBO, int width, int height%2^) = 0;
echo     virtual void onFaceDetected^(%1const FaceData^& face%2^) {}
echo.
echo     void setEnabled^(%1bool enabled%2^) { enabled_ = enabled; }
echo     bool isEnabled^(^) const { return enabled_; }
echo     Type getType^(^) const { return type_; }
echo     const std::string^& getName^(^) const { return name_; }
echo.
echo     // Parameter system
echo     void setFloat^(%1const std::string^& name, float value%2^) { floatParams_[name] = value; }
echo     void setInt^(%1const std::string^& name, int value%2^) { intParams_[name] = value; }
echo     void setVec2^(%1const std::string^& name, const glm::vec2^& value%2^) { vec2Params_[name] = value; }
echo.
echo protected:
echo     Type type_;
echo     std::string name_;
echo     bool enabled_ = true;
echo.
echo     std::map^<std::string, float^> floatParams_;
echo     std::map^<std::string, int^> intParams_;
echo     std::map^<std::string, glm::vec2^> vec2Params_;
echo };
) > src\effects\Effect.h

:: Create Filter2D effect
(
echo #pragma once
echo #include "Effect.h"
echo #include "../graphics/Shader.h"
echo.
echo class Filter2D : public Effect {
echo public:
echo     Filter2D^(^);
echo     ~Filter2D^(^);
echo.
echo     void init^(^) override;
echo     void update^(%1float deltaTime%2^) override;
echo     void render^(%1uint32_t inputTexture, uint32_t outputFBO, int width, int height%2^) override;
echo.
echo     void setLUT^(%1uint32_t lutTexture^);  // Color grading lookup table
echo.
echo private:
echo     Shader shader_;
echo     uint32_t vao_ = 0, vbo_ = 0;
echo     uint32_t lutTexture_ = 0;
echo     bool useLUT_ = false;
echo.
echo     void createFullscreenQuad^(^);
echo };
) > src\effects\Filter2D.h

:: Create Filter2D.cpp
(
echo #include "Filter2D.h"
echo.
echo Filter2D::Filter2D^(^) : Effect^(FILTER_2D, "Color Filter"^) {}
echo.
echo Filter2D::~Filter2D^(^) {
echo     if %1vao_%2 glDeleteVertexArrays^(1, ^&vao_^);
echo     if %1vbo_%2 glDeleteBuffers^(1, ^&vbo_^);
echo }
echo.
echo void Filter2D::init^(^) {
echo     const char* vert = R"(
echo #version 330 core
echo layout^(location = 0^) in vec2 aPos;
echo layout^(location = 1^) in vec2 aTexCoord;
echo out vec2 vTexCoord;
echo void main^(^) {
echo     gl_Position = vec4^(aPos, 0.0, 1.0^);
echo     vTexCoord = aTexCoord;
echo }
echo     )";
echo.
echo     const char* frag = R"(
echo #version 330 core
echo in vec2 vTexCoord;
echo out vec4 fragColor;
echo uniform sampler2D inputTexture;
echo uniform sampler3D lutTexture;
echo uniform float intensity;
echo uniform bool useLUT;
echo uniform float brightness;
echo uniform float contrast;
echo uniform float saturation;
echo.
echo vec3 applyLUT^(vec3 color^) {
echo     vec3 lutCoord = color * 0.9375 + 0.03125;
echo     return texture^(lutTexture, lutCoord^).rgb;
echo }
echo.
echo vec3 adjustBrightness^(vec3 color, float b^) {
echo     return color + b;
echo }
echo.
echo vec3 adjustContrast^(vec3 color, float c^) {
echo     return ^(color - 0.5^) * ^(1.0 + c^) + 0.5;
echo }
echo.
echo vec3 adjustSaturation^(vec3 color, float s^) {
echo     float gray = dot^(color, vec3^(0.299, 0.587, 0.114^)^);
echo     return mix^(vec3^(gray^), color, 1.0 + s^);
echo }
echo.
echo void main^(^) {
echo     vec4 color = texture^(inputTexture, vTexCoord^);
echo     vec3 result = color.rgb;
echo     
echo     result = adjustBrightness^(result, brightness^);
echo     result = adjustContrast^(result, contrast^);
echo     result = adjustSaturation^(result, saturation^);
echo     
echo     if %1useLUT%2 {
echo         vec3 graded = applyLUT^(result^);
echo         result = mix^(result, graded, intensity^);
echo     }
echo     
echo     fragColor = vec4^(result, color.a^);
echo }
echo     )";
echo.
echo     shader_.loadFromStrings^(vert, frag^);
echo     createFullscreenQuad^(^);
echo.
echo     // Default params
echo     setFloat^("intensity", 1.0f^);
echo     setFloat^("brightness", 0.0f^);
echo     setFloat^("contrast", 0.0f^);
echo     setFloat^("saturation", 0.0f^);
echo }
echo.
echo void Filter2D::createFullscreenQuad^(^) {
echo     float vertices[] = {
echo         // Positions   // TexCoords
echo         -1.0f,  1.0f,  0.0f, 1.0f,
echo         -1.0f, -1.0f,  0.0f, 0.0f,
echo          1.0f, -1.0f,  1.0f, 0.0f,
echo         -1.0f,  1.0f,  0.0f, 1.0f,
echo          1.0f, -1.0f,  1.0f, 0.0f,
echo          1.0f,  1.0f,  1.0f, 1.0f
echo     };
echo.
echo     glGenVertexArrays^(1, ^&vao_^);
echo     glGenBuffers^(1, ^&vbo_^);
echo     glBindVertexArray^(vao_^);
echo     glBindBuffer^(GL_ARRAY_BUFFER, vbo_^);
echo     glBufferData^(GL_ARRAY_BUFFER, sizeof^(vertices^), vertices, GL_STATIC_DRAW^);
echo     glEnableVertexAttribArray^(0^);
echo     glVertexAttribPointer^(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof^(float^), ^(void*^)0^);
echo     glEnableVertexAttribArray^(1^);
echo     glVertexAttribPointer^(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof^(float^), ^(void*^)^(2 * sizeof^(float^)^)^);
echo }
echo.
echo void Filter2D::update^(%1float deltaTime%2^) {}
echo.
echo void Filter2D::render^(%1uint32_t inputTexture, uint32_t outputFBO, int width, int height%2^) {
echo     glBindFramebuffer^(GL_FRAMEBUFFER, outputFBO^);
echo     shader_.use^(^);
echo.
echo     glActiveTexture^(GL_TEXTURE0^);
echo     glBindTexture^(GL_TEXTURE_2D, inputTexture^);
echo     shader_.setInt^("inputTexture", 0^);
echo.
echo     if %1useLUT_%2 {
echo         glActiveTexture^(GL_TEXTURE1^);
echo         glBindTexture^(GL_TEXTURE_3D, lutTexture_^);
echo         shader_.setInt^("lutTexture", 1^);
echo     }
echo     shader_.setInt^("useLUT", useLUT_^);
echo     shader_.setFloat^("intensity", floatParams_["intensity"]^);
echo     shader_.setFloat^("brightness", floatParams_["brightness"]^);
echo     shader_.setFloat^("contrast", floatParams_["contrast"]^);
echo     shader_.setFloat^("saturation", floatParams_["saturation"]^);
echo.
echo     glBindVertexArray^(vao_^);
echo     glDrawArrays^(GL_TRIANGLES, 0, 6^);
echo }
echo.
echo void Filter2D::setLUT^(%1uint32_t lutTexture^) {
echo     lutTexture_ = lutTexture;
echo     useLUT_ = ^(lutTexture != 0^);
echo }
) > src\effects\Filter2D.cpp

echo Effect system created.
echo.

:: Create Distortion2D effect
echo [4/8] Creating distortion effects...
(
echo #pragma once
echo #include "Effect.h"
echo #include "../graphics/Shader.h"
echo.
echo class Distortion2D : public Effect {
echo public:
echo     enum DistortType { BARREL, PINCUSHION, FISHEYE, TWIRL, WAVE };
echo.
echo     Distortion2D^(DistortType type = BARREL^);
echo     ~Distortion2D^(^);
echo.
echo     void init^(^) override;
echo     void update^(%1float deltaTime%2^) override;
echo     void render^(%1uint32_t inputTexture, uint32_t outputFBO, int width, int height%2^) override;
echo.
echo     void setCenter^(%1const glm::vec2^& center^) { center_ = center; }  // 0-1 normalized
echo     void setStrength^(%1float strength^) { strength_ = strength; }
echo.
echo private:
echo     DistortType distortType_;
echo     Shader shader_;
echo     uint32_t vao_ = 0, vbo_ = 0;
echo     glm::vec2 center_ = glm::vec2^(0.5f, 0.5f^);
echo     float strength_ = 0.5f;
echo.
echo     const char* getFragmentShader^(^);
echo     void createFullscreenQuad^(^);
echo };
) > src\effects\Distortion2D.h

:: Create Distortion2D.cpp
(
echo #include "Distortion2D.h"
echo.
echo Distortion2D::Distortion2D^(DistortType type^) 
echo     : Effect^(DISTORT_2D, "Distortion"^), distortType_(type^) {}
echo.
echo Distortion2D::~Distortion2D^(^) {
echo     if %1vao_%2 glDeleteVertexArrays^(1, ^&vao_^);
echo     if %1vbo_%2 glDeleteBuffers^(1, ^&vbo_^);
echo }
echo.
echo void Distortion2D::init^(^) {
echo     const char* vert = R"(
echo #version 330 core
echo layout^(location = 0^) in vec2 aPos;
echo layout^(location = 1^) in vec2 aTexCoord;
echo out vec2 vTexCoord;
echo void main^(^) {
echo     gl_Position = vec4^(aPos, 0.0, 1.0^);
echo     vTexCoord = aTexCoord;
echo }
echo     )";
echo.
echo     shader_.loadFromStrings^(vert, getFragmentShader^(^)^);
echo     createFullscreenQuad^(^);
echo }
echo.
echo const char* Distortion2D::getFragmentShader^(^) {
echo     switch^(distortType_^) {
echo     case BARREL:
echo         return R"(
echo #version 330 core
echo in vec2 vTexCoord;
echo out vec4 fragColor;
echo uniform sampler2D inputTexture;
echo uniform vec2 center;
echo uniform float strength;
echo void main^(^) {
echo     vec2 coord = vTexCoord - center;
echo     float dist = length^(coord^);
echo     float radius = dist * ^(1.0 + strength * dist * dist^);
echo     vec2 newCoord = center + normalize^(coord^) * radius;
echo     fragColor = texture^(inputTexture, newCoord^);
echo }
echo         )";
echo     case FISHEYE:
echo         return R"(
echo #version 330 core
echo in vec2 vTexCoord;
echo out vec4 fragColor;
echo uniform sampler2D inputTexture;
echo uniform vec2 center;
echo uniform float strength;
echo const float PI = 3.14159265359;
echo void main^(^) {
echo     vec2 coord = vTexCoord - center;
echo     float dist = length^(coord^) * 2.0;
echo     float angle = atan^(coord.y, coord.x^);
echo     float newDist = tan^(dist * strength * PI * 0.5^) / tan^(strength * PI * 0.5^);
echo     vec2 newCoord = center + vec2^(cos^(angle^), sin^(angle^)^) * newDist * 0.5;
echo     fragColor = texture^(inputTexture, clamp^(newCoord, 0.0, 1.0^)^);
echo }
echo         )";
echo     case TWIRL:
echo         return R"(
echo #version 330 core
echo in vec2 vTexCoord;
echo out vec4 fragColor;
echo uniform sampler2D inputTexture;
echo uniform vec2 center;
echo uniform float strength;
echo void main^(^) {
echo     vec2 coord = vTexCoord - center;
echo     float dist = length^(coord^);
echo     float angle = atan^(coord.y, coord.x^) + strength * ^(1.0 - dist^) * 3.14159;
echo     vec2 newCoord = center + dist * vec2^(cos^(angle^), sin^(angle^)^);
echo     fragColor = texture^(inputTexture, newCoord^);
echo }
echo         )";
echo     default:
echo         return "";
echo     }
echo }
echo.
echo void Distortion2D::createFullscreenQuad^(^) {
echo     float vertices[] = {
echo         -1.0f,  1.0f,  0.0f, 1.0f,
echo         -1.0f, -1.0f,  0.0f, 0.0f,
echo          1.0f, -1.0f,  1.0f, 0.0f,
echo         -1.0f,  1.0f,  0.0f, 1.0f,
echo          1.0f, -1.0f,  1.0f, 0.0f,
echo          1.0f,  1.0f,  1.0f, 1.0f
echo     };
echo     glGenVertexArrays^(1, ^&vao_^);
echo     glGenBuffers^(1, ^&vbo_^);
echo     glBindVertexArray^(vao_^);
echo     glBindBuffer^(GL_ARRAY_BUFFER, vbo_^);
echo     glBufferData^(GL_ARRAY_BUFFER, sizeof^(vertices^), vertices, GL_STATIC_DRAW^);
echo     glEnableVertexAttribArray^(0^);
echo     glVertexAttribPointer^(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof^(float^), ^(void*^)0^);
echo     glEnableVertexAttribArray^(1^);
echo     glVertexAttribPointer^(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof^(float^), ^(void*^)^(2 * sizeof^(float^)^)^);
echo }
echo.
echo void Distortion2D::update^(%1float deltaTime%2^) {}
echo.
echo void Distortion2D::render^(%1uint32_t inputTexture, uint32_t outputFBO, int width, int height%2^) {
echo     glBindFramebuffer^(GL_FRAMEBUFFER, outputFBO^);
echo     shader_.use^(^);
echo     glActiveTexture^(GL_TEXTURE0^);
echo     glBindTexture^(GL_TEXTURE_2D, inputTexture^);
echo     shader_.setInt^("inputTexture", 0^);
echo     shader_.setVec2^("center", center_^);
echo     shader_.setFloat^("strength", strength_^);
echo     glBindVertexArray^(vao_^);
echo     glDrawArrays^(GL_TRIANGLES, 0, 6^);
echo }
) > src\effects\Distortion2D.cpp

echo Distortion effects created.
echo.

:: Create FaceTracker
echo [5/8] Creating FaceTracker...
(
echo #pragma once
echo #include ^<opencv2/opencv.hpp^>
echo #include ^<vector^>
echo #include ^<glm/glm.hpp^>
echo #include "Effect.h"
echo.
echo class FaceTracker {
echo public:
echo     struct TrackedFace {
echo         std::vector^<glm::vec2^> landmarks68;   // dlib style 68 points
echo         std::vector^<glm::vec2^> landmarks468;  // MediaPipe style
echo         cv::Rect boundingBox;
echo         glm::vec3 position;    // 3D head position
echo         glm::vec3 rotation;    // Euler angles
echo         float confidence;
echo         int id;                // Face ID for tracking multiple
echo     };
echo.
echo     FaceTracker^(^);
echo     ~FaceTracker^(^);
echo.
echo     bool initialize^(^);
echo     bool detect^(%1const cv::Mat^& frame, std::vector^<TrackedFace^>^& faces%2^);
echo     void setFaceMeshEnabled^(%1bool enabled%2^) { useFaceMesh_ = enabled; }
echo.
echo private:
echo     cv::CascadeClassifier faceCascade_;
echo     cv::Ptr^<cv::face::Facemark^> facemark_;
echo     bool initialized_ = false;
echo     bool useFaceMesh_ = false;
echo     int nextFaceId_ = 0;
echo.
echo     void estimateHeadPose^(TrackedFace^& face^);
echo };
) > src\tracking\FaceTracker.h

:: Create FaceTracker.cpp
(
echo #include "FaceTracker.h"
echo #include ^<opencv2/face.hpp^>
echo #include ^<opencv2/calib3d.hpp^>
echo #include ^<iostream^>
echo.
echo FaceTracker::FaceTracker^(^) {}
echo.
echo FaceTracker::~FaceTracker^(^) {}
echo.
echo bool FaceTracker::initialize^(^) {
echo     // Load Haar cascade for face detection
echo     std::string cascadePath = "assets/haarcascade_frontalface_default.xml";
echo     if %1!faceCascade_.load^(cascadePath^)%2 {
echo         std::cerr ^<^< "Failed to load face cascade!" ^<^< std::endl;
echo         return false;
echo     }
echo.
echo     // Initialize Facemark for 68 landmarks
echo     facemark_ = cv::face::createFacemarkLBF^(^);
echo     std::string modelPath = "assets/lbfmodel.yaml";
echo     if %1!facemark_->loadModel^(modelPath^)%2 {
echo         std::cerr ^<^< "Failed to load Facemark model!" ^<^< std::endl;
echo         return false;
echo     }
echo.
echo     initialized_ = true;
echo     return true;
echo }
echo.
echo bool FaceTracker::detect^(%1const cv::Mat^& frame, std::vector^<TrackedFace^>^& faces%2^) {
echo     faces.clear^(^);
echo     if %1!initialized_%2 return false;
echo.
echo     cv::Mat gray;
echo     if %1frame.channels^(^) == 3%2
echo         cv::cvtColor^(frame, gray, cv::COLOR_BGR2GRAY^);
echo     else
echo         gray = frame.clone^(^);
echo.
echo     std::vector^<cv::Rect^> detectedFaces;
echo     faceCascade_.detectMultiScale^(gray, detectedFaces, 1.1, 3, 0, cv::Size^(80, 80^)^);
echo.
echo     std::vector^<std::vector^<cv::Point2f^>^> allLandmarks;
echo     bool success = facemark_->fit^(frame, detectedFaces, allLandmarks^);
echo.
echo     for %1size_t i = 0; i ^< detectedFaces.size^(^); ++i%2 {
echo         TrackedFace face;
echo         face.boundingBox = detectedFaces[i];
echo         face.id = nextFaceId_++;
echo         face.confidence = 0.9f;
echo.
echo         if %1success ^&^& i ^< allLandmarks.size^(^)%2 {
echo             for %1auto^& pt : allLandmarks[i]%2 {
echo                 face.landmarks68.emplace_back^(pt.x / frame.cols, pt.y / frame.rows^);
echo             }
echo         }
echo.
echo         estimateHeadPose^(face^);
echo         faces.push_back^(face^);
echo     }
echo.
echo     return !faces.empty^(^);
echo }
echo.
echo void FaceTracker::estimateHeadPose^(TrackedFace^& face^) {
echo     // Simplified head pose estimation based on eye positions
echo     if %1face.landmarks68.size^(^) ^< 45%2 return;
echo.
echo     glm::vec2 leftEye = face.landmarks68[36];
echo     glm::vec2 rightEye = face.landmarks68[45];
echo     glm::vec2 noseTip = face.landmarks68[30];
echo.
echo     // Estimate position ^(normalized^)
echo     face.position = glm::vec3^(
echo         ^(leftEye.x + rightEye.x^) * 0.5f - 0.5f,
echo         ^(leftEye.y + rightEye.y^) * 0.5f - 0.5f,
echo         0.0f
echo     ^);
echo.
echo     // Estimate rotation from eye angle
echo     float eyeAngle = atan2^(rightEye.y - leftEye.y, rightEye.x - leftEye.x^);
echo     face.rotation = glm::vec3^(0.0f, 0.0f, eyeAngle^);
echo }
) > src\tracking\FaceTracker.cpp

echo FaceTracker created.
echo.

:: Create EffectManager
echo [6/8] Creating EffectManager...
(
echo #pragma once
echo #include ^<memory^>
echo #include ^<vector^>
echo #include "Effect.h"
echo.
echo class EffectManager {
echo public:
echo     EffectManager^(^);
echo     ~EffectManager^(^);
echo.
echo     void addEffect^(std::shared_ptr^<Effect^> effect^);
echo     void removeEffect^(const std::string^& name^);
echo     void clearEffects^(^);
echo.
echo     std::shared_ptr^<Effect^> getEffect^(const std::string^& name^);
echo     std::vector^<std::shared_ptr^<Effect^>^>^& getAllEffects^(^) { return effects_; }
echo.
echo     void update^(%1float deltaTime%2^);
echo     uint32_t render^(%1uint32_t inputTexture, int width, int height%2^);
echo.
echo     void onFaceDetected^(%1const FaceData^& face%2^);
echo.
echo     // Helper methods for common effects
echo     void addFilter2D^(const std::string^& name^);
echo     void addDistortion2D^(const std::string^& name, Distortion2D::DistortType type^);
echo.
echo private:
echo     std::vector^<std::shared_ptr^<Effect^>^> effects_;
echo     std::unique_ptr^<Framebuffer^> pingPongBuffers_[2];
echo     int currentBuffer_ = 0;
echo     int width_ = 0, height_ = 0;
echo.
echo     void ensureBuffers^(int width, int height^);
echo };
) > src\effects\EffectManager.h

:: Create EffectManager.cpp
(
echo #include "EffectManager.h"
echo #include "Filter2D.h"
echo #include "Distortion2D.h"
echo.
echo EffectManager::EffectManager^(^) {}
echo.
echo EffectManager::~EffectManager^(^) {}
echo.
echo void EffectManager::addEffect^(std::shared_ptr^<Effect^> effect^) {
echo     effects_.push_back^(effect^);
echo     effect->init^(^);
echo }
echo.
echo void EffectManager::removeEffect^(const std::string^& name^) {
echo     effects_.erase^(
echo         std::remove_if^(effects_.begin^(^), effects_.end^(^),
echo             [^&name^](auto^& e^) { return e->getName^(^) == name; }^),
echo         effects_.end^(^)
echo     ^);
echo }
echo.
echo void EffectManager::clearEffects^(^) {
echo     effects_.clear^(^);
echo }
echo.
echo std::shared_ptr^<Effect^> EffectManager::getEffect^(const std::string^& name^) {
echo     for %1auto^& e : effects_%2 {
echo         if %1e->getName^(^) == name%2 return e;
echo     }
echo     return nullptr;
echo }
echo.
echo void EffectManager::update^(%1float deltaTime%2^) {
echo     for %1auto^& effect : effects_%2 {
echo         if %1effect->isEnabled^(^)%2
echo             effect->update^(deltaTime^);
echo     }
echo }
echo.
echo void EffectManager::ensureBuffers^(int width, int height^) {
echo     if %1width_ != width ^|^| height_ != height%2 {
echo         width_ = width;
echo         height_ = height;
echo         pingPongBuffers_[0] = std::make_unique^<Framebuffer^>^(width, height^);
echo         pingPongBuffers_[1] = std::make_unique^<Framebuffer^>^(width, height^);
echo     }
echo }
echo.
echo uint32_t EffectManager::render^(%1uint32_t inputTexture, int width, int height%2^) {
echo     ensureBuffers^(width, height^);
echo.
echo     uint32_t currentInput = inputTexture;
echo     int pingPongIndex = 0;
echo.
echo     for %1auto^& effect : effects_%2 {
echo         if %1!effect->isEnabled^(^)%2 continue;
echo.
echo         uint32_t outputFBO = pingPongBuffers_[pingPongIndex]->getTexture^(^);
echo         effect->render^(currentInput, outputFBO, width, height^);
echo.
echo         currentInput = pingPongBuffers_[pingPongIndex]->getTexture^(^);
echo         pingPongIndex = 1 - pingPongIndex;
echo     }
echo.
echo     return currentInput;
echo }
echo.
echo void EffectManager::onFaceDetected^(%1const FaceData^& face%2^) {
echo     for %1auto^& effect : effects_%2 {
echo         effect->onFaceDetected^(face^);
echo     }
echo }
echo.
echo void EffectManager::addFilter2D^(const std::string^& name^) {
echo     auto filter = std::make_shared^<Filter2D^>^(^);
echo     filter->setEnabled^(true^);
echo     addEffect^(filter^);
echo }
echo.
echo void EffectManager::addDistortion2D^(const std::string^& name, Distortion2D::DistortType type^) {
echo     auto distort = std::make_shared^<Distortion2D^>^(type^);
echo     distort->setEnabled^(true^);
echo     addEffect^(distort^);
echo }
) > src\effects\EffectManager.cpp

echo EffectManager created.
echo.

:: Create updated main.cpp
echo [7/8] Creating updated main.cpp...
(
echo #include ^<glad/glad.h^>
echo #include ^<GLFW/glfw3.h^>
echo #include ^<opencv2/opencv.hpp^>
echo #include ^<iostream^>
echo #include ^<memory^>
echo.
echo #include "effects/EffectManager.h"
echo #include "effects/Filter2D.h"
echo #include "effects/Distortion2D.h"
echo #include "tracking/FaceTracker.h"
echo #include "graphics/Framebuffer.h"
echo.
echo // Window dimensions
echo const int WINDOW_WIDTH = 1280;
echo const int WINDOW_HEIGHT = 720;
echo.
echo // Global objects
echo std::unique_ptr^<EffectManager^> g_effectManager;
echo std::unique_ptr^<FaceTracker^> g_faceTracker;
echo cv::VideoCapture g_webcam;
echo GLuint g_cameraTexture = 0;
echo.
echo // Callbacks
echo void framebuffer_size_callback^(GLFWwindow* window, int width, int height^) {
echo     glViewport^(0, 0, width, height^);
echo }
echo.
echo void key_callback^(GLFWwindow* window, int key, int scancode, int action, int mods^) {
echo     if %1action == GLFW_PRESS%2 {
echo         switch %1key%2 {
echo         case GLFW_KEY_1:
echo             g_effectManager->addFilter2D^("Filter_" + std::to_string^(rand^(^)^)^);
echo             std::cout ^<^< "Added 2D Filter" ^<^< std::endl;
echo             break;
echo         case GLFW_KEY_2:
echo             g_effectManager->addDistortion2D^("Distort_" + std::to_string^(rand^(^)^), 
echo                 Distortion2D::FISHEYE^);
echo             std::cout ^<^< "Added Fisheye Distortion" ^<^< std::endl;
echo             break;
echo         case GLFW_KEY_3:
echo             g_effectManager->addDistortion2D^("Distort_" + std::to_string^(rand^(^)^), 
echo                 Distortion2D::TWIRL^);
echo             std::cout ^<^< "Added Twirl Distortion" ^<^< std::endl;
echo             break;
echo         case GLFW_KEY_C:
echo             g_effectManager->clearEffects^(^);
echo             std::cout ^<^< "Cleared all effects" ^<^< std::endl;
echo             break;
echo         case GLFW_KEY_ESCAPE:
echo             glfwSetWindowShouldClose^(window, true^);
echo             break;
echo         }
echo     }
echo }
echo.
echo bool initOpenGL^(^) {
echo     if %1!glfwInit^(^)%2 {
echo         std::cerr ^<^< "Failed to initialize GLFW" ^<^< std::endl;
echo         return false;
echo     }
echo.
echo     glfwWindowHint^(GLFW_CONTEXT_VERSION_MAJOR, 3^);
echo     glfwWindowHint^(GLFW_CONTEXT_VERSION_MINOR, 3^);
echo     glfwWindowHint^(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE^);
echo.
echo     return true;
echo }
echo.
echo bool initCamera^(^) {
echo     g_webcam.open^(0^);
echo     if %1!g_webcam.isOpened^(^)%2 {
echo         std::cerr ^<^< "Failed to open webcam!" ^<^< std::endl;
echo         return false;
echo     }
echo     g_webcam.set^(cv::CAP_PROP_FRAME_WIDTH, 1280^);
echo     g_webcam.set^(cv::CAP_PROP_FRAME_HEIGHT, 720^);
echo     return true;
echo }
echo.
echo void initCameraTexture^(^) {
echo     glGenTextures^(1, ^&g_cameraTexture^);
echo     glBindTexture^(GL_TEXTURE_2D, g_cameraTexture^);
echo     glTexParameteri^(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR^);
echo     glTexParameteri^(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR^);
echo }
echo.
echo void updateCameraTexture^(%1const cv::Mat^& frame%2^) {
echo     glBindTexture^(GL_TEXTURE_2D, g_cameraTexture^);
echo     glTexImage2D^(GL_TEXTURE_2D, 0, GL_RGB, frame.cols, frame.rows, 
echo                  0, GL_BGR, GL_UNSIGNED_BYTE, frame.data^);
echo }
echo.
echo int main^(^) {
echo     // Initialize systems
echo     if %1!initOpenGL^(^)%2 return -1;
echo     if %1!initCamera^(^)%2 return -1;
echo.
echo     GLFWwindow* window = glfwCreateWindow^(WINDOW_WIDTH, WINDOW_HEIGHT, 
echo         "VFC_Kimi - Effects System", nullptr, nullptr^);
echo     if %1!window%2 return -1;
echo.
echo     glfwMakeContextCurrent^(window^);
echo     glfwSetFramebufferSizeCallback^(window, framebuffer_size_callback^);
echo     glfwSetKeyCallback^(window, key_callback^);
echo.
echo     if %1!gladLoadGLLoader^(^(GLADloadproc^)glfwGetProcAddress^)%2 {
echo         std::cerr ^<^< "Failed to initialize GLAD" ^<^< std::endl;
echo         return -1;
echo     }
echo.
echo     // Initialize subsystems
echo     g_effectManager = std::make_unique^<EffectManager^>^(^);
echo     g_faceTracker = std::make_unique^<FaceTracker^>^(^);
echo     g_faceTracker->initialize^(^);
echo     initCameraTexture^(^);
echo.
echo     // Create fullscreen quad for final blit
echo     float quadVertices[] = {
echo         -1.0f,  1.0f,  0.0f, 1.0f,
echo         -1.0f, -1.0f,  0.0f, 0.0f,
echo          1.0f, -1.0f,  1.0f, 0.0f,
echo         -1.0f,  1.0f,  0.0f, 1.0f,
echo          1.0f, -1.0f,  1.0f, 0.0f,
echo          1.0f,  1.0f,  1.0f, 1.0f
echo     };
echo     GLuint quadVAO, quadVBO;
echo     glGenVertexArrays^(1, ^&quadVAO^);
echo     glGenBuffers^(1, ^&quadVBO^);
echo     glBindVertexArray^(quadVAO^);
echo     glBindBuffer^(GL_ARRAY_BUFFER, quadVBO^);
echo     glBufferData^(GL_ARRAY_BUFFER, sizeof^(quadVertices^), quadVertices, GL_STATIC_DRAW^);
echo     glEnableVertexAttribArray^(0^);
echo     glVertexAttribPointer^(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof^(float^), ^(void*^)0^);
echo     glEnableVertexAttribArray^(1^);
echo     glVertexAttribPointer^(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof^(float^), ^(void*^)^(2 * sizeof^(float^)^)^);
echo.
echo     // Simple pass-through shader for final display
echo     const char* vertShader = R"(
echo #version 330 core
echo layout^(location = 0^) in vec2 aPos;
echo layout^(location = 1^) in vec2 aTexCoord;
echo out vec2 vTexCoord;
echo void main^(^) {
echo     gl_Position = vec4^(aPos, 0.0, 1.0^);
echo     vTexCoord = aTexCoord;
echo }
echo     )";
echo.
echo     const char* fragShader = R"(
echo #version 330 core
echo in vec2 vTexCoord;
echo out vec4 fragColor;
echo uniform sampler2D screenTexture;
echo void main^(^) {
echo     fragColor = texture^(screenTexture, vTexCoord^);
echo }
echo     )";
echo.
echo     GLuint program = glCreateProgram^(^);
echo     GLuint vs = glCreateShader^(GL_VERTEX_SHADER^);
echo     GLuint fs = glCreateShader^(GL_FRAGMENT_SHADER^);
echo     glShaderSource^(vs, 1, ^&vertShader, nullptr^);
echo     glShaderSource^(fs, 1, ^&fragShader, nullptr^);
echo     glCompileShader^(vs^);
echo     glCompileShader^(fs^);
echo     glAttachShader^(program, vs^);
echo     glAttachShader^(program, fs^);
echo     glLinkProgram^(program^);
echo.
echo     std::cout ^<^< "====================================" ^<^< std::endl;
echo     std::cout ^<^< "VFC_Kimi Effects System Started" ^<^< std::endl;
echo     std::cout ^<^< "Controls:" ^<^< std::endl;
echo     std::cout ^<^< "  1 - Add Color Filter" ^<^< std::endl;
echo     std::cout ^<^< "  2 - Add Fisheye Distortion" ^<^< std::endl;
echo     std::cout ^<^< "  3 - Add Twirl Distortion" ^<^< std::endl;
echo     std::cout ^<^< "  C - Clear all effects" ^<^< std::endl;
echo     std::cout ^<^< "  ESC - Exit" ^<^< std::endl;
echo     std::cout ^<^< "====================================" ^<^< std::endl;
echo.
echo     // Main loop
echo     cv::Mat frame;
echo     float deltaTime = 0.0f;
echo     float lastFrame = 0.0f;
echo.
echo     while %1!glfwWindowShouldClose^(window^)%2 {
echo         float currentFrame = glfwGetTime^(^);
echo         deltaTime = currentFrame - lastFrame;
echo         lastFrame = currentFrame;
echo.
echo         glfwPollEvents^(^);
echo.
echo         // Capture frame
echo         g_webcam ^>^> frame;
echo         if %1frame.empty^(^)%2 continue;
echo.
echo         // Update camera texture
echo         updateCameraTexture^(frame^);
echo.
echo         // Face detection
echo         std::vector^<FaceTracker::TrackedFace^> faces;
echo         if %1g_faceTracker->detect^(frame, faces^)%2 {
echo             for %1auto^& face : faces%2 {
echo                 FaceData data;
echo                 data.landmarks = face.landmarks68;
echo                 data.position = face.position;
echo                 data.rotation = face.rotation;
echo                 data.confidence = face.confidence;
echo                 g_effectManager->onFaceDetected^(data^);
echo             }
echo         }
echo.
echo         // Update and render effects
echo         g_effectManager->update^(deltaTime^);
echo         uint32_t finalTexture = g_effectManager->render^(g_cameraTexture, 
echo             frame.cols, frame.rows^);
echo.
echo         // Display to screen
echo         glBindFramebuffer^(GL_FRAMEBUFFER, 0^);
echo         glClear^(GL_COLOR_BUFFER_BIT^);
echo         glUseProgram^(program^);
echo         glActiveTexture^(GL_TEXTURE0^);
echo         glBindTexture^(GL_TEXTURE_2D, finalTexture^);
echo         glUniform1i^(glGetUniformLocation^(program, "screenTexture"^), 0^);
echo         glBindVertexArray^(quadVAO^);
echo         glDrawArrays^(GL_TRIANGLES, 0, 6^);
echo.
echo         glfwSwapBuffers^(window^);
echo     }
echo.
echo     // Cleanup
echo     glfwTerminate^(^);
echo     g_webcam.release^(^);
echo     return 0;
echo }
) > src\main_new.cpp

echo Main application created.
echo.

:: Update CMakeLists.txt
echo [8/8] Updating CMakeLists.txt...
(
echo cmake_minimum_required^(VERSION 3.10^)
echo project^(VFC_Kimi^)
echo.
echo set^(CMAKE_CXX_STANDARD 17^)
echo set^(CMAKE_CXX_STANDARD_REQUIRED ON^)
echo.
echo # Find packages
echo find_package^(OpenCV REQUIRED^)
echo find_package^(glfw3 REQUIRED^)
echo find_package^(OpenGL REQUIRED^)
echo.
echo # GLAD library
echo add_library^(glad STATIC include/glad.c^)
echo target_include_directories^(glad PUBLIC include/^)
echo.
echo # Main executable
echo add_executable^(${PROJECT_NAME}
echo     src/main_new.cpp
echo     src/graphics/Framebuffer.cpp
echo     src/graphics/Shader.cpp
echo     src/effects/Filter2D.cpp
echo     src/effects/Distortion2D.cpp
echo     src/effects/EffectManager.cpp
echo     src/tracking/FaceTracker.cpp
echo     src/camera/WebcamCapture.cpp
echo     src/core/Window.cpp
echo ^)
echo.
echo target_include_directories^(${PROJECT_NAME} PRIVATE 
echo     ${CMAKE_SOURCE_DIR}/include
echo     ${CMAKE_SOURCE_DIR}/src
echo     ${OpenCV_INCLUDE_DIRS}
echo ^)
echo.
echo target_link_libraries^(${PROJECT_NAME}
echo     glad
echo     glfw
echo     OpenGL::GL
echo     ${OpenCV_LIBS}
echo ^)
echo.
echo # Copy assets to build directory
echo add_custom_command^(TARGET ${PROJECT_NAME} POST_BUILD
echo     COMMAND ${CMAKE_COMMAND} -E copy_directory
echo     ${CMAKE_SOURCE_DIR}/assets ^$^<TARGET_FILE_DIR:${PROJECT_NAME}^>/assets
echo ^)
) > CMakeLists.txt.new

echo ==========================================
echo Setup Complete!
echo ==========================================
echo.
echo NEXT STEPS:
echo -----------
echo 1. Download OpenCV face detection models:
echo    - haarcascade_frontalface_default.xml
echo    - lbfmodel.yaml
echo    Place these in assets/
echo.
echo 2. Replace old main.cpp:
echo    copy src\main_new.cpp src\main.cpp
echo.
echo 3. Update CMakeLists.txt:
echo    copy CMakeLists.txt.new CMakeLists.txt
echo.
echo 4. Rebuild:
echo    cd build
echo    cmake ..
echo    cmake --build . --config Release
echo.
echo 5. Run:
echo    Release\VFC_Kimi.exe
echo.
echo CONTROLS:
echo ---------
echo 1 - Add color filter effect
echo 2 - Add fisheye distortion
echo 3 - Add twirl distortion  
echo C - Clear all effects
echo ESC - Exit
echo.
pause