#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <opencv2/opencv.hpp>
#include <iostream>
#include <memory>

#include "effects/EffectManager.h"
#include "effects/Filter2D.h"
#include "effects/Distortion2D.h"
#include "tracking/FaceTracker.h"
#include "tracking/SegmentationProvider.h"

std::unique_ptr<EffectManager> g_efx;
std::unique_ptr<FaceTracker> g_face;
std::unique_ptr<SegmentationProvider> g_segmenter;  // ADD THIS
cv::VideoCapture g_cam;
GLuint g_tex = 0;
const int W = 1280, H = 720;

void fb_cb(GLFWwindow* win, int w, int h) { glViewport(0, 0, w, h); }

void key_cb(GLFWwindow* win, int key, int sc, int act, int mods) {
    if (act == GLFW_PRESS) {
        if (key == GLFW_KEY_1) {
            auto filter = std::make_shared<Filter2D>();
            filter->init();
            filter->setEnabled(true);
            filter->setFloatParam("contrast", 0.3f);
            g_efx->add(filter);
            std::cout << "[Applied] Contrast Filter" << std::endl;
        }
        if (key == GLFW_KEY_2) {
            auto distort = std::make_shared<Distortion2D>(Distortion2D::FISHEYE);
            distort->init();
            distort->setEnabled(true);
            distort->setStrength(0.8f);
            g_efx->add(distort);
            std::cout << "[Applied] Fisheye Effect" << std::endl;
        }
        if (key == GLFW_KEY_3) {
            auto distort = std::make_shared<Distortion2D>(Distortion2D::TWIRL);
            distort->init();
            distort->setEnabled(true);
            distort->setStrength(2.0f);
            g_efx->add(distort);
            std::cout << "[Applied] Twirl Effect" << std::endl;
        }
        if (key == GLFW_KEY_4) {
            auto distort = std::make_shared<Distortion2D>(Distortion2D::BARREL);
            distort->init();
            distort->setEnabled(true);
            distort->setStrength(-0.5f);
            g_efx->add(distort);
            std::cout << "[Applied] Barrel Effect" << std::endl;
        }
        if (key == GLFW_KEY_C) {
            g_efx->clear();
            std::cout << "[Cleared] All Effects" << std::endl;
        }
        if (key == GLFW_KEY_ESCAPE) glfwSetWindowShouldClose(win, 1);
    }
}

int main() {
    if (!glfwInit()) return -1;
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
   
    GLFWwindow* win = glfwCreateWindow(W, H, "VFC_Kimi Native Engine", nullptr, nullptr);
    if (!win) return -1;
   
    glfwMakeContextCurrent(win);
    glfwSetFramebufferSizeCallback(win, fb_cb);
    glfwSetKeyCallback(win, key_cb);
    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) return -1;

    g_cam.open(0);
    if (!g_cam.isOpened()) {
        std::cerr << "[ERROR] Failed to open webcam!" << std::endl;
        return -1;
    }
    g_cam.set(cv::CAP_PROP_FRAME_WIDTH, W);
    g_cam.set(cv::CAP_PROP_FRAME_HEIGHT, H);
   
    glGenTextures(1, &g_tex);
    glBindTexture(GL_TEXTURE_2D, g_tex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    g_efx = std::make_unique<EffectManager>();
    g_face = std::make_unique<FaceTracker>();
    g_face->init();

    // Initialize segmentation (optional - doesn't break if fails)
    g_segmenter = std::make_unique<SegmentationProvider>();
    if (!g_segmenter->init("assets/models/selfie_multiclass.onnx")) {
        std::cout << "[WARNING] Segmentation model not loaded. Running without AI segmentation." << std::endl;
        g_segmenter.reset(); // Clear if failed
    } else {
        std::cout << "[OK] AI Segmentation loaded successfully!" << std::endl;
    }

    // Terminal Menu
    std::cout << "===============================" << std::endl;
    std::cout << "    VFC_Kimi Effects Engine    " << std::endl;
    std::cout << "===============================" << std::endl;
    std::cout << "  1 = Contrast Filter" << std::endl;
    std::cout << "  2 = Fisheye Distortion" << std::endl;
    std::cout << "  3 = Twirl Distortion" << std::endl;
    std::cout << "  4 = Barrel Distortion" << std::endl;
    std::cout << "  C = Clear All Effects" << std::endl;
    std::cout << "  ESC = Exit Program" << std::endl;
    std::cout << "-------------------------------" << std::endl;

    // Vertices mapped to flip the OpenCV texture correctly
    float qv[24] = {
        -1.0f,  1.0f,  0.0f, 0.0f,
        -1.0f, -1.0f,  0.0f, 1.0f,
         1.0f, -1.0f,  1.0f, 1.0f,
        -1.0f,  1.0f,  0.0f, 0.0f,
         1.0f, -1.0f,  1.0f, 1.0f,
         1.0f,  1.0f,  1.0f, 0.0f
    };
   
    GLuint vao, vbo;
    glGenVertexArrays(1, &vao); 
    glGenBuffers(1, &vbo);
    glBindVertexArray(vao); 
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(qv), qv, GL_STATIC_DRAW);
    glEnableVertexAttribArray(0); 
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 16, (void*)0);
    glEnableVertexAttribArray(1); 
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 16, (void*)8);

    const char* vs = R"(#version 330 core
layout(location=0) in vec2 p; 
layout(location=1) in vec2 t;
out vec2 vT; 
void main() { 
    gl_Position = vec4(p, 0.0, 1.0); 
    vT = t; 
})";

    const char* fs = R"(#version 330 core
in vec2 vT; 
out vec4 c; 
uniform sampler2D tex;
void main() { 
    c = texture(tex, vT); 
})";
   
    GLuint prog = glCreateProgram();
    GLuint vsh = glCreateShader(GL_VERTEX_SHADER);
    GLuint fsh = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(vsh, 1, &vs, nullptr); 
    glShaderSource(fsh, 1, &fs, nullptr);
    glCompileShader(vsh); 
    glCompileShader(fsh);
    glAttachShader(prog, vsh); 
    glAttachShader(prog, fsh); 
    glLinkProgram(prog);
    
    // Clean up shaders
    glDeleteShader(vsh);
    glDeleteShader(fsh);

    cv::Mat frame, frameRGB;

    while (!glfwWindowShouldClose(win)) {
        glfwPollEvents();
        g_cam >> frame;
        if (frame.empty()) continue;

        // 1. RUN SEGMENTATION (if available)
        if (g_segmenter) {
            auto masks = g_segmenter->segment(frame);
            // TODO: Use masks.hair, masks.clothes, etc. for effects
            // For now, just print debug info
            static int frameCount = 0;
            if (++frameCount % 30 == 0) {
                std::cout << "[Segmentation] Hair pixels: " << cv::countNonZero(masks.hair) << std::endl;
            }
        }

        // 2. RUN FACE DETECTION
        std::vector<FaceTracker::Face> faces;
        if (g_face && g_face->detect(frame, faces)) {
            for (auto& f : faces) {
                // Draw face box on CPU frame (will be visible in output)
                cv::rectangle(frame, f.box, cv::Scalar(0, 255, 0), 2);
               
                FaceData d;
                d.landmarks = f.landmarks68;
                d.position = f.pos;
                d.rotation = f.rot;
                d.confidence = f.conf;
                g_efx->onFace(d);
            }
        }

        // 3. CONVERT & UPLOAD
        cv::cvtColor(frame, frameRGB, cv::COLOR_BGR2RGB);
        glBindTexture(GL_TEXTURE_2D, g_tex);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, frameRGB.cols, frameRGB.rows, 0, GL_RGB, GL_UNSIGNED_BYTE, frameRGB.data);
       
        // 4. RENDER EFFECTS
        g_efx->update(0.016f); // 60 FPS delta time
        uint32_t finalTex = g_efx->render(g_tex, frame.cols, frame.rows);
       
        // 5. DRAW TO SCREEN
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        glClear(GL_COLOR_BUFFER_BIT);
        glUseProgram(prog);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, finalTex);
        glUniform1i(glGetUniformLocation(prog, "tex"), 0); // Set uniform
        glBindVertexArray(vao);
        glDrawArrays(GL_TRIANGLES, 0, 6);
       
        glfwSwapBuffers(win);
    }
    
    glfwTerminate();
    g_cam.release();
    return 0;
}