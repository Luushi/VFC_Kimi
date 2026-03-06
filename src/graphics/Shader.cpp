#include "Shader.h"

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
