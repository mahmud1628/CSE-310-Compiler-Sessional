#!/usr/bin/bash

flex 2105120.l
g++ lex.yy.c
./a.out test.txt