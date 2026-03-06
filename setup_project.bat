@echo off
echo Creating VFC_Kimi project structure...

REM Create main directories
mkdir src
mkdir src\core
mkdir src\camera
mkdir src\tracking
mkdir src\rendering
mkdir src\ui
mkdir include
mkdir assets
mkdir assets\shaders
mkdir assets\models
mkdir assets\textures

REM Create empty source files
type nul > src\main.cpp
type nul > src\core\Window.h
type nul > src\core\Window.cpp
type nul > src\camera\WebcamCapture.h
type nul > src\camera\WebcamCapture.cpp
type nul > src\tracking\FaceTracker.h
type nul > src\tracking\FaceTracker.cpp
type nul > src\rendering\Renderer.h
type nul > src\rendering\Renderer.cpp
type nul > src\rendering\Shader.h
type nul > src\rendering\Shader.cpp
type nul > src\ui\UIManager.h
type nul > src\ui\UIManager.cpp
type nul > README.md

echo.
echo Project structure created!
echo.
echo Next steps:
echo 1. Create CMakeLists.txt manually (copy from instructions)
echo 2. Add main.cpp content
echo 3. Run build commands
echo.
pause