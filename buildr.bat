dub build --compiler=ldc2 --build=release

copy raylib.dll raylibtemp.dll
move raylibtemp.dll ./bin/raylib.dll