#include "Distortion2D.h"

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
