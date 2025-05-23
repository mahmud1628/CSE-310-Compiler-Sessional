#ifndef SYMBOLTABLE_HPP
#define SYMBOLTABLE_HPP
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
            ScopeTable * newScope = new ScopeTable(++num_scopes, num_buckets, currentScope, hashName , verbose);
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

        bool insert(string name, string type, bool verbose = false) {
            bool inserted = currentScope->insert(name, type, verbose);
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
        

};


#endif // SYMBOLTABLE_HPP