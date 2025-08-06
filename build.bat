@echo off
dub build --compiler=ldc2 --build=debug

copy raylib.dll raylibtemp.dll
move raylibtemp.dll ./bin/raylib.dll