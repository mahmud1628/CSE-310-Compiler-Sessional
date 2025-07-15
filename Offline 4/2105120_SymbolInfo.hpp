#pragma once

#include<iostream>
#include<string>
using namespace std;

class SymbolInfo {
    string name, type;
    SymbolInfo * next;

    string func_return_type;
    bool declared = false; // flag to check if the symbol is declared
    vector<pair<string, string>> func_params; // vector of pairs to store parameter name and type

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
            return "< " + name + " : " + "ID" + " >";
        }

        string getFuncReturnType() const {
            return func_return_type;
        }

        void setFuncReturnType(const string return_type) {
            func_return_type = return_type;
        }

        vector<pair<string, string>> getFuncParams() const {
            return func_params;
        }
        
        void setFuncParams(vector<pair<string, string>> params) {
            func_params = params;
        }

        int getFuncParamsSize() const {
            return func_params.size();
        }

        bool getDeclarationStatus() {
            return declared;
        }

        void setDeclarationStatus(bool status) {
            declared = status;
        }
};