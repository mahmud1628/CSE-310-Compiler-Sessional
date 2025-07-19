#ifndef _2105120_OPTIMIZER_HPP_
#define _2105120_OPTIMIZER_HPP_

#include <vector>
#include <fstream>
#include <sstream>
#include <string>
#include <iostream>
#include <unordered_set>

using namespace std;

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
    // Optimization logic can be added here
    // For now, we just load the instructions
}

void trim(std::string &s) {
    size_t a = s.find_first_not_of(" \t\r\n");
    if (a == std::string::npos) { s.clear(); return; }
    size_t b = s.find_last_not_of(" \t\r\n");
    s = s.substr(a, b - a + 1);
}

string toLowerCopy(std::string s) {
    for (char &c : s) c = (char)std::tolower((unsigned char)c);
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