@echo off
echo Fixing GLAD folder structure...

REM Move glad.c from include/src to include
move include\src\glad.c include\glad.c

REM Move glad and KHR folders from include/include to include
move include\include\glad include\glad
move include\include\KHR include\KHR

REM Remove empty include/include folder
rmdir include\include

echo Done! Structure fixed.
pause