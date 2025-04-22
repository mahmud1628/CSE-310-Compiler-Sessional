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

};


#endif // SYMBOLTABLE_HPP