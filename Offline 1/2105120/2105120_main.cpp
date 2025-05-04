#include<iostream>
#include<string>
#include<sstream>
#include "2105120_SymbolTable.hpp"


using namespace std;


int main(int argc, char *argv[]) {
    if(argc >= 3) {
        freopen(argv[1], "r",stdin);
        freopen(argv[2], "w",stdout);
    }
    int num_buckets;
    cin >> num_buckets;
    string hashName;
    if(argc == 4) {
        hashName = argv[3];
    } else {
        hashName = "sdbm";
    }
    cin.ignore(); // Ignore the newline character after the number of buckets
    SymbolTable * symbolTable = new SymbolTable(num_buckets, hashName, true);
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
                bool not_to_insert = false;
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
                } else if(type == "STRUCT" || type == "UNION") {
                    string t = type;
                    type = type + ",{";
                    string dataType;
                    while(ss >> dataType) {
                        string member;
                        if(ss >> member) {
                            type = type + "(" + dataType + "," + member + "),";
                        } else {
                            cout << "\tMember name missing for type " << t << endl;
                            not_to_insert = true;
                            continue;
                        }
                    }
                    if(type.back() == ',') {
                        type.pop_back(); // Remove the last comma
                    }
                    type = type + "}";
                } else {
                    string extra;
                    if(ss >> extra) {
                        cout << "\tNumber of parameters mismatch for the command I" << type << endl;
                        continue;
                    }
                }
                if(!not_to_insert)
                    symbolTable->insert(name, type, true);
            } else {
                cout << "\tNumber of parameters mismatch for the command I" << endl;
                continue;
            }
        }

        else if(command == "L") {
            string name;
            if(ss >> name) {
                string extra;
                if(ss >> extra) {
                    cout << "\tNumber of parameters mismatch for the command L" << endl;
                    continue;
                } else {
                    symbolTable->lookup(name, true);
                }
            } else {
                cout << "\tNumber of parameters mismatch for the command L" << endl;
                continue;
            }
        }

        else if(command == "D") {
            string name;
            if(ss >> name) {
                string extra;
                if(ss >> extra) {
                    cout << "\tNumber of parameters mismatch for the command D" << endl;
                    continue;
                } else {
                    symbolTable->remove(name, true);
                }
            } else {
                cout << "\tNumber of parameters mismatch for the command D" << endl;
                continue;
            }
        }

        else if(command == "P") {
            string printType;
            if(ss >> printType) {
                string extra;
                if(ss >> extra) {
                    cout << "\tNumber of parameters mismatch for the command P" << endl;
                    continue;
                } else {
                    if(printType == "C") {
                        symbolTable->printCurrentScope(true);
                    } else if(printType == "A") {
                        symbolTable->printAllScopes(true);
                    } else {
                        cout << "\tInvalid command for P" << endl;
                        continue;
                    }
                }
            } else {
                cout << "\tNumber of parameters mismatch for the command P" << endl;
                continue;
            }
        }

        else if(command == "S") {
            string extra;
            if(ss >> extra) {
                cout << "\tNumber of parameters mismatch for the command S" << endl;
                continue;
            } else {
                symbolTable->enterScope(true);
            }
        }

        else if(command == "E") {
            string extra;
            if(ss >> extra) {
                cout << "\tNumber of parameters mismatch for the command S" << endl;
                continue;
            } else {
                symbolTable->exitScope(true);
            }
        } 

        else if(command == "Q") {
            string extra;
            if(ss >> extra) {
                cout << "\tNumber of parameters mismatch for the command Q" << endl;
                continue;
            } else {
                delete symbolTable;
                break;
            }
        } 

        else {
            cout << "\tInvalid command" << endl;
            continue;
        }
    }
}