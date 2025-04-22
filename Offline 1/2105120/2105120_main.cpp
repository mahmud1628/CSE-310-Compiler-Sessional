#include<iostream>
#include<string>
#include<sstream>
#include "2105120_SymbolTable.hpp"


using namespace std;


int main() {
    int num_buckets;
    cin >> num_buckets;
    cin.ignore(); // Ignore the newline character after the number of buckets
    SymbolTable symbolTable(num_buckets);
    int commandCount = 0;
    string line, command;

    while(true) {
        getline(cin, line);
        if(line == "") {
            continue;
        }

        commandCount++;
        cout << "Cmd " << commandCount << ": " << line << endl;

        stringstream ss(line);
        ss >> command;
        if(command == "I") {
            string name, type;
            if(ss >> name >> type) {
                if(type == "FUNCTION") {
                    string returnType;
                    if(ss >> returnType) {
                        type = type + "," + returnType + "<==(";
                        string param;
                        while(ss >> param) {
                            type = type + param + ",";
                        }
                        if(type.back() == ',') {
                            type.pop_back(); // Remove the last comma
                        }
                        type = type + ")";
                    } else {
                        cout << "\tReturn type missing for type FUNCTION" << endl;
                        continue;
                    }
                } else if(type == "STRCUT") {
                    type = type + ",{";
                    string dataType;
                    while(ss >> dataType) {
                        string member;
                        if(ss >> member) {
                            type = type + "(" + dataType + "," + member + "),";
                        } else {
                            cout << "\tMember name missing for type STRUCT" << endl;
                            continue;
                        }
                    }
                    if(type.back() == ',') {
                        type.pop_back(); // Remove the last comma
                    }
                    type = type + "}";
                } else if(type == "UNION") {

                } else {
                    string extra;
                    if(ss >> extra) {
                        cout << "\tNumber of parameters mismatch for the command I" << type << endl;
                        continue;
                    }
                }
                symbolTable.insert(name, type);
            } else {
                cout << "\tNumber of parameters mismatch for the command I" << endl;
                continue;
            }
        }
    }
}