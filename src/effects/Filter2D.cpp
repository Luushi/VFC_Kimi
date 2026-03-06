#include "Filter2D.h"

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
