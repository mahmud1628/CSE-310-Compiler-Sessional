#pragma once

#include <string>
#include <iostream>
#include "2105120_SymbolInfo.hpp"
#include "2105120_ScopeTable.hpp"

using namespace std;

class SymbolTable {
    private:
        ScopeTable * currentScope;
        int num_buckets;
        int num_scopes;
        int numberOfCollisions;
        string hashName;
        FILE *log_file = nullptr;
    
    public:
        SymbolTable(int num_buckets, string hashName = "sdbm" , bool verbose = false) : num_buckets(num_buckets), hashName(hashName) {
            num_scopes = 0;
            numberOfCollisions = 0;
            currentScope = nullptr;
            enterScope(verbose);
        }

        ~SymbolTable() {
            delete currentScope; // delete the current scope
            // The destructor of ScopeTable will take care of deleting its parent scopes
        }

        void enterScope(bool verbose = false) {
            if(currentScope != nullptr) {
                currentScope->incrementNumChildren();
            }
            num_scopes++;
            ScopeTable * newScope = new ScopeTable(num_buckets, currentScope, hashName , verbose);
            if(log_file != nullptr)
                newScope->setLogFile(log_file);

            currentScope = newScope;
            if(verbose) {
                cout << "\tScopeTable# " << currentScope->getId() << " created" << endl;
            }
        }

        void exitScope(bool verbose = false) {
            if(currentScope->getParentScope() == nullptr) {
                if(verbose) {
                    cout << "\tScopeTable# " << currentScope->getId() << " cannot be exited" << endl;
                }
                return; // cannot exit the global scope
            }
            numberOfCollisions += currentScope->getNumberOfCollisions();
            ScopeTable * parentScope = currentScope->getParentScope();
            currentScope->setParentScope(nullptr); // avoid recursive deletion
            delete currentScope; // delete the current scope
            currentScope = parentScope; // move to the parent scope
        }

        bool insert(string name, string type,int stack_offset = -1, int size = 1, bool verbose = false) {
            bool inserted = currentScope->insert(name, type,stack_offset,size, verbose);
            return inserted;
        }

        bool remove(string name, bool verbose = false) {
            bool removed = currentScope->deleteSymbol(name, verbose);
            return removed;
        }

        SymbolInfo * lookup(string name, bool verbose = false) {
            ScopeTable * scope = currentScope;
            SymbolInfo * symbol;
            while(scope != nullptr) {
                symbol = scope->lookup(name, verbose);
                if(symbol != nullptr) {
                    return symbol;
                }
                scope = scope->getParentScope();
            }
            if(verbose) {
                cout << "\t'" << name << "' not found in any of the ScopeTables" << endl;
            }
            return nullptr; // not found
        }

        SymbolInfo * lookupAtCurrentScope(string name) {
            ScopeTable * scope = currentScope;
            SymbolInfo * symbol = scope->lookup(name);
            if(symbol != nullptr) {
                return symbol; // found in current scope
            }
            return nullptr; // not found in current scope
        }

        void printCurrentScope(bool tabs = false) {
            int numberOfTabs;
            tabs ? numberOfTabs = 1 : numberOfTabs = 0;
            currentScope->print(numberOfTabs);
        }

        void printAllScopes(bool tabs = false) {
            ScopeTable * scope = currentScope;
            int numberOfTabs = 0;
            while(scope != nullptr) {
                tabs ? numberOfTabs++ : 0;
                scope->print(numberOfTabs);
                scope = scope->getParentScope();
            }
        }

        void printAllScopesToLog() {
            ScopeTable * scope = currentScope;
            while(scope != nullptr) {
                scope->print_to_log();
                scope = scope->getParentScope();
            }
            fprintf(log_file, "\n");
        }

        int getNumberOfCollisions() {
            calculateCollisions();
            return numberOfCollisions;
        }

        void calculateCollisions() {
            ScopeTable * scope = currentScope;
            while(scope != nullptr) {
                numberOfCollisions += scope->getNumberOfCollisions();
                scope = scope->getParentScope();
            }
        }

        int getNumScopes() {
            return num_scopes;
        }
        int getNumBuckets() {
            return num_buckets;
        }

        void setLogFile(FILE *log_file) {
            this->log_file = log_file;
            if(currentScope != nullptr) {
                currentScope->setLogFile(log_file);
            }
        }
        string getSymbolTableAsString() {
            string  result = "";
            ScopeTable * scope = currentScope;
            while(scope != nullptr) {
                result += scope->getScopeTableAsString();
                scope = scope->getParentScope();
            }
            //result += "\n";
            return result;
        }

        string getCurrentScopeId() {
            if(currentScope != nullptr) {
                return currentScope->getId();
            }
            return "0"; // no current scope
        }

        int countLocalVarInCurrentScope() {
            return currentScope->getLocalVarCount();
        }
};