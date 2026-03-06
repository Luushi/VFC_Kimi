cmake_minimum_required(VERSION 3.10)
project(VFC_Kimi)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# --------------------------------------------------
# VCPKG Toolchain
# --------------------------------------------------
if(NOT DEFINED CMAKE_TOOLCHAIN_FILE)
    set(CMAKE_TOOLCHAIN_FILE "D:/dev/deps/vcpkg/scripts/buildsystems/vcpkg.cmake"
        CACHE STRING "Vcpkg toolchain file")
endif()

# --------------------------------------------------
# Packages
# --------------------------------------------------
find_package(OpenCV CONFIG REQUIRED)
find_package(glfw3 CONFIG REQUIRED)
find_package(OpenGL REQUIRED)

# --------------------------------------------------
# ONNX Runtime
# --------------------------------------------------
find_package(onnxruntime CONFIG QUIET)

if(NOT onnxruntime_FOUND)
    message(STATUS "ONNX Runtime not found via vcpkg, using manual path")

    set(ONNX_DIR "D:/dev/deps/onnxruntime-gpu/onnxruntime-win-x64-gpu-1.24.3" CACHE PATH "ONNX Runtime directory")

    if(EXISTS ${ONNX_DIR})
        include_directories(${ONNX_DIR}/include)
        link_directories(${ONNX_DIR}/lib)
        set(ONNX_MANUAL_LIBS onnxruntime)
    else()
        message(FATAL_ERROR "ONNX Runtime not found.")
    endif()

else()
    set(ONNX_MANUAL_LIBS "")
endif()

# --------------------------------------------------
# GLAD
# --------------------------------------------------
add_library(glad STATIC include/glad.c)
target_include_directories(glad PUBLIC include)

# --------------------------------------------------
# Source files
# --------------------------------------------------
set(SOURCES
    src/main_effects.cpp

    src/graphics/Framebuffer.cpp
    src/graphics/Shader.cpp

    src/effects/Filter2D.cpp
    src/effects/Distortion2D.cpp
    src/effects/EffectManager.cpp

    src/tracking/FaceTracker.cpp
    src/tracking/MulticlassSegmenter.cpp   # ← new segmentation system

    src/camera/WebcamCapture.cpp
    src/core/Window.cpp
)

# --------------------------------------------------
# Executable
# --------------------------------------------------
add_executable(${PROJECT_NAME} ${SOURCES})

# --------------------------------------------------
# Include paths
# --------------------------------------------------
target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/src
)

# --------------------------------------------------
# Link libraries
# --------------------------------------------------
target_link_libraries(${PROJECT_NAME}
    glad
    glfw
    OpenGL::GL
    ${OpenCV_LIBS}
)

# ONNX Runtime linking
if(onnxruntime_FOUND)
    target_link_libraries(${PROJECT_NAME} onnxruntime::onnxruntime)
else()
    target_link_libraries(${PROJECT_NAME} ${ONNX_MANUAL_LIBS})
endif()

# --------------------------------------------------
# Copy assets after build
# --------------------------------------------------
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_SOURCE_DIR}/assets
    $<TARGET_FILE_DIR:${PROJECT_NAME}>/assets
)

# --------------------------------------------------
# Copy ONNX DLLs if manual install
# --------------------------------------------------
if(NOT onnxruntime_FOUND AND EXISTS ${ONNX_DIR})
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
        ${ONNX_DIR}/lib/onnxruntime.dll
        $<TARGET_FILE_DIR:${PROJECT_NAME}>/

        COMMAND ${CMAKE_COMMAND} -E copy_if_exists
        ${ONNX_DIR}/lib/onnxruntime_providers_cuda.dll
        $<TARGET_FILE_DIR:${PROJECT_NAME}>/

        COMMAND ${CMAKE_COMMAND} -E copy_if_exists
        ${ONNX_DIR}/lib/onnxruntime_providers_shared.dll
        $<TARGET_FILE_DIR:${PROJECT_NAME}>/
    )
endif()