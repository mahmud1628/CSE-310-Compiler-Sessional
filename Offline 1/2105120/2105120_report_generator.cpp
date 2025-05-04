#include<iostream>
#include<string>
#include<sstream>
#include "2105120_SymbolTable.hpp"


using namespace std;

void print_report(SymbolTable * symbolTable) {
    int num_buckets = symbolTable->getNumBuckets();
    int num_scopes = symbolTable->getNumScopes();
    int number_of_collisions = symbolTable->getNumberOfCollisions();
    cout << "\tTotal number of ScopeTables : " << num_scopes << endl;
    cout << "\tTotal number of Collisions : " << number_of_collisions << endl;
    cout << "\tRatio : " << 1.0 * number_of_collisions / (num_scopes * num_buckets) << endl;
}


int main(int argc, char *argv[]) {
    if(argc >= 3) {
        freopen(argv[1], "r",stdin);
        freopen(argv[2], "w",stdout);
    }
    int num_buckets;
    cin >> num_buckets;
    // string hashName;
    // if(argc == 4) {
    //     hashName = argv[3];
    // } else {
    //     hashName = "sdbm";
    // }
    cin.ignore(); // Ignore the newline character after the number of buckets
    SymbolTable * symbolTableSDBM = new SymbolTable(num_buckets, "sdbm");
    SymbolTable * symbolTableBKDR = new SymbolTable(num_buckets, "bkdr");
    SymbolTable * symbolTableDJB = new SymbolTable(num_buckets, "djb");
    
    int commandCount = 0;
    string line, command;

    while(true) {
        getline(cin, line);
        if(line == "") {
            continue;
        }

        commandCount++;
        // cout << "Cmd " << commandCount << ": " << line << endl;

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
                        // cout << "\tReturn type missing for type FUNCTION" << endl;
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
                            // cout << "\tMember name missing for type " << t << endl;
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
                        // cout << "\tNumber of parameters mismatch for the command I" << type << endl;
                        continue;
                    }
                }
                if(!not_to_insert) {
                    symbolTableSDBM->insert(name, type);
                    symbolTableBKDR->insert(name, type);
                    symbolTableDJB->insert(name, type);
                }
            } else {
                // cout << "\tNumber of parameters mismatch for the command I" << endl;
                continue;
            }
        }

        else if(command == "L") {
            string name;
            if(ss >> name) {
                string extra;
                if(ss >> extra) {
                    // cout << "\tNumber of parameters mismatch for the command L" << endl;
                    continue;
                } else {
                    symbolTableSDBM->lookup(name);
                    symbolTableBKDR->lookup(name);
                    symbolTableDJB->lookup(name);
                }
            } else {
                // cout << "\tNumber of parameters mismatch for the command L" << endl;
                continue;
            }
        }

        else if(command == "D") {
            string name;
            if(ss >> name) {
                string extra;
                if(ss >> extra) {
                    // cout << "\tNumber of parameters mismatch for the command D" << endl;
                    continue;
                } else {
                    symbolTableSDBM->remove(name);
                    symbolTableBKDR->remove(name);
                    symbolTableDJB->remove(name);
                }
            } else {
                // cout << "\tNumber of parameters mismatch for the command D" << endl;
                continue;
            }
        }

        else if(command == "P") {
            // string printType;
            // if(ss >> printType) {
            //     string extra;
            //     if(ss >> extra) {
            //         // cout << "\tNumber of parameters mismatch for the command P" << endl;
            //         continue;
            //     } else {
            //         if(printType == "C") {
            //             symbolTableSDBM->printCurrentScope(true);
            //         } else if(printType == "A") {
            //             symbolTableSDBM->printAllScopes(true);
            //         } else {
            //             cout << "\tInvalid command for P" << endl;
            //             continue;
            //         }
            //     }
            // } else {
            //     cout << "\tNumber of parameters mismatch for the command P" << endl;
            //     continue;
            // }
            continue; // Ignore the print command for report generation
        }

        else if(command == "S") {
            string extra;
            if(ss >> extra) {
                // cout << "\tNumber of parameters mismatch for the command S" << endl;
                continue;
            } else {
                symbolTableSDBM->enterScope();
                symbolTableBKDR->enterScope();
                symbolTableDJB->enterScope();
            }
        }

        else if(command == "E") {
            string extra;
            if(ss >> extra) {
                // cout << "\tNumber of parameters mismatch for the command S" << endl;
                continue;
            } else {
                symbolTableSDBM->exitScope();
                symbolTableBKDR->exitScope();
                symbolTableDJB->exitScope();
            }
        } 

        else if(command == "Q") {
            string extra;
            if(ss >> extra) {
                // cout << "\tNumber of parameters mismatch for the command Q" << endl;
                continue;
            } else {
                cout << "Report for SDBM Hash Function : " << endl;
                print_report(symbolTableSDBM);
                delete symbolTableSDBM;
                // generate report for bkdr hash function
                cout << "Report for BKDR Hash Function : " << "(Hash function collecred from https://www.partow.net/programming/hashfunctions/#BKDRHashFunction)" << endl;
                print_report(symbolTableBKDR);
                delete symbolTableBKDR;
                // generate report for djb hash function
                cout << "Report for DJB Hash Function : " << "(Hash function collected from https://www.partow.net/programming/hashfunctions/#DJBHashFunction)" << endl;
                print_report(symbolTableDJB);
                delete symbolTableDJB;
                break;
            }
        } 

        else {
            // cout << "\tInvalid command" << endl;
            continue;
        }
    }
}