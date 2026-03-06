cmake_minimum_required(VERSION 3.10)
project(VFC_Kimi)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 1. VCPKG Toolchain (must be before project() or set via command line)
if(NOT DEFINED CMAKE_TOOLCHAIN_FILE)
    set(CMAKE_TOOLCHAIN_FILE "D:/dev/deps/vcpkg/scripts/buildsystems/vcpkg.cmake" 
        CACHE STRING "Vcpkg toolchain file")
endif()

# 2. Find packages (vcpkg will provide these)
find_package(OpenCV CONFIG REQUIRED)
find_package(glfw3 CONFIG REQUIRED)
find_package(OpenGL REQUIRED)

# 3. ONNX Runtime - try to find via vcpkg first, fallback to manual
find_package(onnxruntime CONFIG QUIET)
if(NOT onnxruntime_FOUND)
    message(STATUS "ONNX Runtime not found via vcpkg, using manual path")
    set(ONNX_DIR "D:/dev/deps/onnxruntime-gpu/onnxruntime-win-x64-gpu-1.24.3" CACHE PATH "ONNX Runtime directory")
    if(EXISTS ${ONNX_DIR})
        include_directories(${ONNX_DIR}/include)
        link_directories(${ONNX_DIR}/lib)
        set(ONNX_MANUAL_LIBS onnxruntime)
    else()
        message(FATAL_ERROR "ONNX Runtime not found. Install via vcpkg: vcpkg install onnxruntime-gpu:x64-windows")
    endif()
else()
    set(ONNX_MANUAL_LIBS "")
endif()

# 4. GLAD library
add_library(glad STATIC include/glad.c)
target_include_directories(glad PUBLIC include/)

# 5. Collect all source files
set(SOURCES
    src/main_effects.cpp
    src/graphics/Framebuffer.cpp
    src/graphics/Shader.cpp
    src/effects/Filter2D.cpp
    src/effects/Distortion2D.cpp
    src/effects/EffectManager.cpp
    src/tracking/FaceTracker.cpp
    src/tracking/SegmentationProvider.cpp
    src/camera/WebcamCapture.cpp
    src/core/Window.cpp
)

# 6. Main Executable
add_executable(${PROJECT_NAME} ${SOURCES})

# 7. Include Paths
target_include_directories(${PROJECT_NAME} PRIVATE 
    ${CMAKE_SOURCE_DIR}/include 
    ${CMAKE_SOURCE_DIR}/src
)

# 8. Link libraries
target_link_libraries(${PROJECT_NAME}
    glad
    glfw
    OpenGL::GL
    ${OpenCV_LIBS}
)

# Add onnxruntime from vcpkg or manual
if(onnxruntime_FOUND)
    target_link_libraries(${PROJECT_NAME} onnxruntime::onnxruntime)
else()
    target_link_libraries(${PROJECT_NAME} ${ONNX_MANUAL_LIBS})
endif()

# 9. Deployment: Assets and DLLs
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    # Copy Assets
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${CMAKE_SOURCE_DIR}/assets $<TARGET_FILE_DIR:${PROJECT_NAME}>/assets
)

# Copy ONNX DLLs only if using manual path
if(NOT onnxruntime_FOUND AND EXISTS ${ONNX_DIR})
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy ${ONNX_DIR}/lib/onnxruntime.dll $<TARGET_FILE_DIR:${PROJECT_NAME}>/
        COMMAND ${CMAKE_COMMAND} -E copy_if_exists ${ONNX_DIR}/lib/onnxruntime_providers_cuda.dll $<TARGET_FILE_DIR:${PROJECT_NAME}>/
        COMMAND ${CMAKE_COMMAND} -E copy_if_exists ${ONNX_DIR}/lib/onnxruntime_providers_shared.dll $<TARGET_FILE_DIR:${PROJECT_NAME}>/
    )
endif()