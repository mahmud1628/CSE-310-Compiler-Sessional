#!/bin/bash
set -e

ANTLR_JAR="/usr/local/lib/antlr-4.13.2-complete.jar"
INCLUDE_DIR="/usr/local/include/antlr4-runtime"
LIB_DIR="/usr/local/lib"
SRC_FILES="2105120_main.cpp"

# === Generate Lexer & Parser with Visitors ===
java -Xmx500M -cp "$ANTLR_JAR:." org.antlr.v4.Tool -Dlanguage=Cpp C8086Lexer.g4
java -Xmx500M -cp "$ANTLR_JAR:." org.antlr.v4.Tool -Dlanguage=Cpp C8086Parser.g4



# === Compile ===
g++ -std=c++17 -I"$INCLUDE_DIR" -c C8086Lexer.cpp C8086Parser.cpp $SRC_FILES
g++ -std=c++17 C8086Lexer.o C8086Parser.o 2105120_main.o -L"$LIB_DIR" -lantlr4-runtime -o 2105120_main.out -pthread

LD_LIBRARY_PATH=/usr/local/lib ./2105120_main.out "$1"