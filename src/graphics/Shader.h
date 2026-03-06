#pragma once
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
