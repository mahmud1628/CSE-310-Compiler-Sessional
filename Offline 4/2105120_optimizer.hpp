#ifndef _2105120_OPTIMIZER_HPP_
#define _2105120_OPTIMIZER_HPP_

#include <vector>
#include <fstream>
#include <sstream>
#include <string>
#include <iostream>
#include <unordered_set>

using namespace std;

const string outputFileName = "optCode.asm";

struct Instruction {
    string operation;
    string firstOperand;
    string secondOperand;

    Instruction(const string& op, const string& first, const string& second)
        : operation(op), firstOperand(first), secondOperand(second) {}
};

class Optimizer {
    vector<Instruction> instructions;
    void loadInstructions(const string& fileName);
    vector<string> originalInstructions;
    unordered_set<int> indicesToRemove;
    void trim(string &s);
    string toLowerCopy(string &s);
    void setIndicesToRemove();
    void handlePush(int index);
    void handleAddToZero(int index);
    void handleSubToZero(int index);
    void removeInstructionsAndWriteToFile(const string& fileName);
    public:
    Optimizer() {}
    void optimize(const string& fileName);
    void printInstructions() const;
};

void Optimizer::optimize(const string& fileName) {
    instructions.clear();
    originalInstructions.clear();
    indicesToRemove.clear();
    loadInstructions(fileName);
    // determine the indices of the instructions that need to be removed
    setIndicesToRemove();
    // remove the instructions that are marked for removal
    removeInstructionsAndWriteToFile(outputFileName);
}

void Optimizer::setIndicesToRemove() {
    for (size_t i = 0; i < instructions.size(); ++i) {
        const auto instr = instructions[i];
        const string operation = instr.operation;

        if(operation == "empty" || operation == "comment" || operation == "not_in_code") {
            // Skip empty lines, comments, and lines not in code segment
            continue;
        }

        if(operation == "push") {
            handlePush(i);
        }
        else if(operation == "add") {
            handleAddToZero(i);
        }
        else if(operation == "sub") {
            handleSubToZero(i);
        }

    }
}

void Optimizer::handlePush(int index) {
    if(index + 1 >= instructions.size()) {
        // If this is the last instruction, we can't do anything
        return;
    }
    int nextIndex = index + 1;
    auto& nextInstr = instructions[nextIndex];
    while(nextInstr.operation == "empty" || nextInstr.operation == "comment") {
        nextIndex++;
        if(nextIndex >= instructions.size()) {
            // If we reach the end of the instructions, we can't do anything
            return;
        }
        nextInstr = instructions[nextIndex];
    }
    const string& nextOperation = nextInstr.operation;
    if(nextOperation != "pop") {
        // If the next instruction is not a pop, we don't check for the operand
        return;
    }

    string currentFirstOperand = instructions[index].firstOperand;
    string nextFirstOperand = nextInstr.firstOperand;

    if(currentFirstOperand == nextFirstOperand) {
        // If the first operand of push and pop are the same, we can remove both of them
        indicesToRemove.insert(index);
        indicesToRemove.insert(nextIndex);
    }
}

void Optimizer::handleAddToZero(int index) {
    const string & firstOperand = instructions[index].firstOperand, secondOperand = instructions[index].secondOperand;

    if(firstOperand == "0" || secondOperand == "0") {
        // If either operand is zero, we can remove this instruction
        indicesToRemove.insert(index);
        return;
    }
}

void Optimizer::handleSubToZero(int index) {
    const string & secondOperand = instructions[index].secondOperand;

    if(secondOperand == "0") {
        // If both operands are zero, we can remove this instruction
        indicesToRemove.insert(index);
        return;
    }
}


void Optimizer::removeInstructionsAndWriteToFile(const string& fileName) {
    ofstream outFile(fileName);
    if (!outFile.is_open()) {
        std::cerr << "Error opening output file: " << fileName << "\n";
        return;
    }

    for (size_t i = 0; i < originalInstructions.size(); ++i) {
        if (indicesToRemove.find(i) != indicesToRemove.end()) {
            continue; // Skip this instruction
        }
        outFile << originalInstructions[i] << endl;
    }

    outFile.close();
}

void Optimizer::trim(string &s) {
    size_t a = s.find_first_not_of(" \t\r\n");
    if (a == string::npos) { s.clear(); return; }
    size_t b = s.find_last_not_of(" \t\r\n");
    s = s.substr(a, b - a + 1);
}

string Optimizer::toLowerCopy(string &s) {
    for (char &c : s) c = (char)tolower((unsigned char)c);
    return s;
};

void Optimizer::loadInstructions(const string& fileName) {
    bool inCode = false;
    ifstream file(fileName);
    if (!file.is_open()) {
        std::cerr << "Error opening file: " << fileName << "\n";
        return;
    }

    string line;
    while (getline(file, line)) {
        string original = line;
        originalInstructions.push_back(original);
        if(line.empty()) {
            instructions.emplace_back("empty", "empty", "empty");
            continue;
        }
        if(!inCode) {
            instructions.emplace_back("not_in_code", "not_in_code", "not_in_code");
        }
        // Remove comments
        string noComment = line.substr(0, line.find(';'));
        trim(noComment);
        if (noComment.empty()) {
            instructions.emplace_back("comment", "comment", "comment");
            continue;
        }

        string lowered = toLowerCopy(noComment);

        // Wait for .code
        if (!inCode) {
            if (lowered == ".code") {
                inCode = true;
            }
            continue;
        }

        // Arrive at new_line proc
        if (lowered.find("new_line proc") != string::npos) {
            inCode = false;
            continue;
        }

        // Parse operation and operands
        string operation;
        {
            istringstream iss(noComment);
            iss >> operation;
        }
        string rest = noComment.substr(noComment.find(operation) + operation.size());
        trim(rest);

        string op1, op2;
        if (!rest.empty()) {
            size_t commaPos = rest.find(',');
            if (commaPos == string::npos) {
                op1 = rest;
            } else {
                op1 = rest.substr(0, commaPos);
                op2 = rest.substr(commaPos + 1);
                trim(op2);
            }
            trim(op1);
            if (!op1.empty() && op1.back() == ',') op1.pop_back();
            trim(op1);
        }

        instructions.emplace_back(operation, op1, op2);
    }

    file.close();
}




void Optimizer::printInstructions() const {
    for (const auto& instr : instructions) {
        cout << instr.operation << " " << instr.firstOperand << " " << instr.secondOperand << endl;
        //cout << instr << endl;
    }
    // cout << instructions.size() << " instructions loaded." << endl;
    // cout << originalInstructions.size() << " original instructions loaded." << endl;
}



#endif // _2105120_OPTIMIZER_HPP_