#ifndef SCOPETABLE_HPP
#define SCOPETABLE_HPP
#include <string>
#include <iostream>
#include "2105120_SymbolInfo.hpp"
#include "2105120_hash.hpp"
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

        int getBucketIndex(string & name) {
            unsigned int hash = Hash::SDBMHash(name, num_buckets);
            return hash % num_buckets;
        }

        bool insert(string& name, string& type, bool verbose = false) {
            SymbolInfo * exists = lookup(name);
            if(exists != nullptr) {
                if(verbose) {
                    cout << "\t'" << name << "' already exists in the current ScopeTable" << endl;
                }
                return false; // symbol already exists
            }
            int index = getBucketIndex(name);
            int position = 1;
            SymbolInfo * new_symbol = new SymbolInfo(name, type);
            if(hash_table[index] == nullptr) {
                hash_table[index] = new_symbol;
            } else {
                SymbolInfo * current = hash_table[index];
                while(current->getNext() != nullptr) {
                    current = current->getNext();
                    position++;
                }
                position++;
                current->setNext(new_symbol);
            }
            if(verbose) {
                cout << "\tInserted in ScopeTable# " << id << " at position " << index + 1 << ", " << position << endl;
            }
            return true;
        }

        SymbolInfo * lookup(string& name) {
            int index = getBucketIndex(name);
            SymbolInfo * current = hash_table[index];
            while(current != nullptr) {
                if(current->getName() == name) {
                    return current;
                }
                current = current->getNext();
            }
            return nullptr;
        }

        bool deleteSymbol(string& name) {
            SymbolInfo * toBeDeleted = lookup(name);
            if(toBeDeleted == nullptr) {
                return false; // symbol not found
            }
            int index = getBucketIndex(name);
            SymbolInfo * current = hash_table[index];
            if(current == toBeDeleted) {
                hash_table[index] = current->getNext();
            } else {
                while(current->getNext() != toBeDeleted) {
                    current = current->getNext();
                }
                current->setNext(toBeDeleted->getNext());
            }
            toBeDeleted->setNext(nullptr); // to avoid recursive deletion
            delete toBeDeleted;
            return true;
        }

        void print(int numberOfTabs = 0) {
            string tabs(numberOfTabs, '\t');
            cout << tabs << "ScopeTable# " << id << endl;
            for(int i = 0; i < num_buckets; i++) {
                cout << tabs << i << "--> ";
                SymbolInfo * current = hash_table[i];
                while(current != nullptr) {
                    cout << current << " ";
                    current = current->getNext();
                }
                cout << endl;
            }
        }
};




#endif // SCOPETABLE_HPP