#include <iostream>
#include <fstream>
#include <string>
#include <stack>
#include "antlr4-runtime.h"
#include "C8086Lexer.h"
#include "C8086Parser.h"
#include "2105120_SymbolTable.hpp"
#include "2105120_optimizer.hpp"

using namespace antlr4;
using namespace std;

ofstream lexLogFile;
ofstream asmCodeFile;
SymbolTable symbolTable(7, "sdbm"); // Initialize symbol table with 7 buckets and sdbm hash function
bool codeSegmentStarted = false;
int label_count = 0;
stack<string> currentFunctions;
int localVarCount = 0;

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
                << ".data ; data definition goes here\n"
                << "\tnumber db \"00000$\"\n";

    ANTLRInputStream input(inputFile);
    C8086Lexer lexer(&input);
    CommonTokenStream tokens(&lexer);
    C8086Parser parser(&tokens);
    parser.removeErrorListeners();

    parser.start();

    {
        ifstream lib("printProc.lib");
        if (lib) {
            asmCodeFile << "\n; ===== runtime print support =====\n";
            asmCodeFile << lib.rdbuf();
        } else {
            std::cerr << "Warning: could not open printProc.lib; continuing without it.\n";
        }
    }


    asmCodeFile << "end main\n";

    inputFile.close();
    lexLogFile.close();
    asmCodeFile.close();
    cout << "Code generation completed. Assembly code written to: " << asmCodeFileName << endl;

    // Run optimizer
    Optimizer optimizer;
    string optFileName = outputDirectory + "optCode.asm";
    cout << "Optimizing assembly code..." << endl;
    optimizer.optimize(asmCodeFileName, optFileName);
    cout << "Optimization completed. Optimized code written to: " << optFileName << endl;
    return 0;
}
