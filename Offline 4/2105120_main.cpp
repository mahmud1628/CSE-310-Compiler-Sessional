#include <iostream>
#include <fstream>
#include <string>
#include "antlr4-runtime.h"
#include "C8086Lexer.h"
#include "C8086Parser.h"

using namespace antlr4;
using namespace std;

ofstream lexLogFile;
ofstream asmCodeFile;

int main(int argc, const char* argv[]) {
    if (argc < 2) {
        cerr << "Usage: " << argv[0] << " <input_file>" << endl;
        return 1;
    }

    ifstream inputFile(argv[1]);
    if (!inputFile.is_open()) {
        cerr << "Error opening input file: " << argv[1] << endl;
        return 1;
    }

    string outputDirectory = "output/";
    string lexLogFileName = outputDirectory + "lexerLog.txt";
    system(("mkdir -p " + outputDirectory).c_str());

    lexLogFile.open(lexLogFileName);
    if (!lexLogFile.is_open()) {
        cerr << "Error opening lexer log file: " << lexLogFileName << endl;
        return 1;
    }

    string asmCodeFileName = outputDirectory + "code.asm";
    asmCodeFile.open(asmCodeFileName);
    if (!asmCodeFile.is_open()) {
        cerr << "Error opening assembly code file: " << asmCodeFileName << endl;
        lexLogFile.close();
        return 1;
    }

    asmCodeFile << ".model small\n"
                << ".stack 100h\n\n"
                << ".data ; data definition goes here\n";

    ANTLRInputStream input(inputFile);
    C8086Lexer lexer(&input);
    CommonTokenStream tokens(&lexer);
    C8086Parser parser(&tokens);
    parser.removeErrorListeners();

    parser.start();

    inputFile.close();
    lexLogFile.close();
    asmCodeFile.close();
    cout << "Parsing completed." << endl;
    return 0;
}
