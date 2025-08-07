# Genome
<img width="1295" height="876" alt="изображение" src="https://github.com/user-attachments/assets/9e615152-cc59-49a9-b1ef-c27cffebcca5" />
<img width="832" height="828" src="https://github.com/user-attachments/assets/3ec8f9ad-8147-40e4-a0f6-0232c6f061f8" />
<img width="976" height="885" src="https://github.com/user-attachments/assets/f117922f-9dae-4d60-9f62-fd5213dd7da2" />
<img width="1120" height="824" src="https://github.com/user-attachments/assets/6277bbde-a9de-4a0c-8c7e-c3727ecd02fe" />
<br>
Genome is a simple evolutionary simulation based on agents and their genomes.<br>
Each tick, agents execute up to 2 commands from their genome (this value can be changed in the configfile).<br>
Commands include actions such as walking, dividing, saving values to register, comparing values, and more.<br>
<br>
The genome consists of command values ranging from 0 to 63 (this range is also configurable).<br>
If a value exceeds the number of available commands (e.g., 16 when there are only 15 commands), it will be interpreted as a relative jump — added to the current instruction pointer (similar to how a program counter works in CPUs).<br>
<br>
At the start, all genomes are filled with random values. Mutations occur randomly, and more successful agents reproduce by division, while less successful ones die out.<br>
<br>
Yellow tiles are agents. Green tiles are food. Gray tiles are spikes.

# Controls 
WASD or mouse -- move<br>
Q --  reload configuration (you can edit values in the config manager)<br>
R -- restart the simulation<br>
Escape -- exit the simulation

# Building

## Requirements:
* You need a D compiler, that supports D 2.111, I like to use ldc2, so this project uses ldc2 compiler by default (see --compiler=ldc2 in .bat files). If you prefer dmd or gdc, simply replace ldc2 with the appropriate compiler in the scripts.<br>
* Also, Genome uses raylib. There is already raylib.dll file inside project folder and build.bat and buildr.bat automatically move library to bin folder. If you use Linux, you have to add library yourself.

On Windows:
* build.bat -- build in debug mode
* buildr.bat -- build in release mode
* run.bat -- build and run in debug mode
* runr.bat -- build and run in release mode

On Linux:
Idk how libraries work on Linux, just use dub build --compiler=ldc2 --build=debug/dub build --compiler=ldc2 --build=release
