#!/bin/bash
set -e

java -Xmx500M -cp "/usr/local/lib/antlr-4.13.2-complete.jar:." org.antlr.v4.Tool -Dlanguage=Cpp C8086Lexer.g4
java -Xmx500M -cp "/usr/local/lib/antlr-4.13.2-complete.jar:." org.antlr.v4.Tool -Dlanguage=Cpp C8086Parser.g4

g++ -std=c++17 -I/usr/local/include/antlr4-runtime -c C8086Lexer.cpp C8086Parser.cpp 2105120_main.cpp
g++ -std=c++17 C8086Lexer.o C8086Parser.o 2105120_main.o -L/usr/local/lib -lantlr4-runtime -o 2105120_main.out -pthread

# LD_LIBRARY_PATH=/usr/local/lib ./2105120_main.out "$1"

``
