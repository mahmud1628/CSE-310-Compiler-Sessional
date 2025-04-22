#ifndef SCOPETABLE_HPP
#define SCOPETABLE_HPP
#include <string>
#include "2105120_SymbolInfo.hpp"
using namespace std;


class ScopeTable {
    private:
        int id;
        int num_buckets; // number of buckets
        int num_children; // number of children
        SymbolInfo ** hash_table;
        ScopeTable * parent_scope;
    
    public:
        ScopeTable(int id, int num_buckets, ScopeTable * parent_scope = nullptr) : id(id), num_buckets(num_buckets), num_children(0), parent_scope(parent_scope) {
            hash_table = new SymbolInfo*[num_buckets];
            for (int i = 0; i < num_buckets; i++) {
                hash_table[i] = nullptr;
            }
        }

        ~ScopeTable() {
            for (int i = 0; i < num_buckets; i++) {
                delete hash_table[i];
            }
            delete[] hash_table;
            if(parent_scope != nullptr) {
                delete parent_scope; // delete the parent scope if it exists
            }
        }

        int getId() const {
            return id;
        }

        int getNumBuckets() const {
            return num_buckets;
        }

        int getNumChildren() const {
            return num_children;
        }

        ScopeTable * getParentScope() const {
            return parent_scope;
        }

        void setParentScope(ScopeTable * parent_scope) {
            this->parent_scope = parent_scope;
        }

        void incrementNumChildren() {
            num_children++;
        }

        void decrementNumChildren() {
            num_children--;
        }

        bool insert(string& name, string& type) {

        }

        SymbolInfo * lookup(string& name) {

        }

        bool deleteSymbol(string& name) {
            
        }

        void print() {
            
        }
};




#endif // SCOPETABLE_HPP