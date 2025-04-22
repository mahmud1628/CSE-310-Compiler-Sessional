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
    
    public:
        SymbolTable(int num_buckets) : num_buckets(num_buckets) {
            num_scopes = 0;
            currentScope = nullptr;
            enterScope();
        }

        ~SymbolTable() {
            delete currentScope; // delete the current scope
            // The destructor of ScopeTable will take care of deleting its parent scopes
        }

        void enterScope() {
            ScopeTable * newScope = new ScopeTable(++num_scopes, num_buckets, currentScope);
            currentScope = newScope;
            cout << "New ScopeTable with id " << newScope->getId() << " created." << endl;
        }

        void exitScope() {
            if(currentScope->getParentScope() == nullptr) {
                return; // cannot exit the global scope
            }
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

};


#endif // SYMBOLTABLE_HPP