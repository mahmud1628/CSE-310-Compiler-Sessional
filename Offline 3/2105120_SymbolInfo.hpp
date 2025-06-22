#pragma once

#include<iostream>
#include<string>
using namespace std;

class SymbolInfo {
    string name, type;
    SymbolInfo * next;

    public:
        SymbolInfo(string name, string type, SymbolInfo * next = nullptr) : name(name), type(type), next(next) {}

        ~SymbolInfo() {
            if(next != nullptr) {
                delete next;
            }
        }

        string getName() const {
            return name;
        }

        string getType() const {
            return type;
        }

        SymbolInfo * getNext() const {
            return next;
        }

        void setName(const string& name) {
            this->name = name;
        }

        void setType(const string& type) {
            this->type = type;
        }

        void setNext(SymbolInfo * next) {
            this->next = next;
        }

        friend ostream& operator<<(ostream& os, const SymbolInfo& symbolInfo) {
            os << "< " << symbolInfo.name << " : " << symbolInfo.type << " >";
            return os;
        }

        void print(FILE *log_file) const {
            fprintf(log_file, "< %s : %s >", name.c_str(), type.c_str());
        }

        string getSymbolInfoAsString() const {
            return "< " + name + " : " + type + " >";
        }
};