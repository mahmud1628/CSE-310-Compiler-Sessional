#ifndef SCOPETABLE_HPP
#define SCOPETABLE_HPP
#include <string>
#include <iostream>
#include <functional>
#include "2105120_SymbolInfo.hpp"
#include "2105120_hash.hpp"
using namespace std;


class ScopeTable {
    private:
        FILE *log_file = nullptr;
        string id;
        int num_buckets; // number of buckets
        int num_children; // number of children
        SymbolInfo ** hash_table;
        ScopeTable * parent_scope;
        bool destructor_verbose;
        // function<unsigned int(string, int)> hash_function;
        function<unsigned int(const char *)> hash_function;
        int numberOfCollisions; // number of collisions
    
    public:
        ScopeTable(int num_buckets, ScopeTable * parent_scope = nullptr,string hashName = "sdbm", bool destructor_verbose = false) : num_buckets(num_buckets), num_children(0), parent_scope(parent_scope), destructor_verbose(destructor_verbose) {
            // if(hashName == "sdbm") {
            //     hash_function = Hash::SDBMHash; 
            // } else if(hashName == "bkdr") {
            //     hash_function = Hash::BKDRHash;
            // } else if(hashName == "djb") {
            //     hash_function = Hash::DJBHash;
            // } else {
            //     //Invalid hash function name. Using default SDBM hash
            //     hash_function = Hash::SDBMHash;
            // }
            if(parent_scope == nullptr) {
                id = "1"; // global scope
            } else {
                id = parent_scope->getId() + "." + to_string(parent_scope->getNumChildren()); // increment the id of the parent scope
            }
            hash_function = Hash::sdbmHash; // default hash function for offline 2
            hash_table = new SymbolInfo*[num_buckets];
            for (int i = 0; i < num_buckets; i++) {
                hash_table[i] = nullptr;
            }
            numberOfCollisions = 0;
            num_children = 0;
        }

        ~ScopeTable() {
            for (int i = 0; i < num_buckets; i++) {
                delete hash_table[i];
            }
            if(destructor_verbose) {
                cout << "\tScopeTable# " << id << " removed" << endl;
            }
            delete[] hash_table;
            if(parent_scope != nullptr) {
                delete parent_scope; // delete the parent scope if it exists
            }
        }

        string getId() const {
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

        // void decrementNumChildren() {
        //     num_children--;
        // }

        int getNumberOfCollisions() const {
            return numberOfCollisions;
        }

        int getBucketIndex(string & name) {
            unsigned int hash = hash_function(name.c_str());
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
                numberOfCollisions++;
                current->setNext(new_symbol);
            }
            if(verbose) {
                cout << "\tInserted in ScopeTable# " << id << " at position " << index + 1 << ", " << position << endl;
            }
            return true;
        }

        SymbolInfo * lookup(string& name, bool verbose = false) {
            int index = getBucketIndex(name);
            int position = 1;
            SymbolInfo * current = hash_table[index];
            while(current != nullptr) {
                if(current->getName() == name) {
                    if(verbose) {
                        cout << "\t'" << name << "' found in ScopeTable# " << id << " at position " << index + 1 << ", " << position << endl;
                    }
                    if(log_file != nullptr)
                        fprintf(log_file, "< %s : %s > already exists in ScopeTable# %s at position %d, %d\n\n", current->getName().c_str(), current->getType().c_str(), id.c_str(), index, position - 1);
                    return current;
                }
                position++;
                current = current->getNext();
            }
            return nullptr;
        }

        bool deleteSymbol(string& name, bool verbose = false) {
            SymbolInfo * toBeDeleted = lookup(name);
            if(toBeDeleted == nullptr) {
                if(verbose) {
                    cout << "\tNot found in the current ScopeTable" << endl;
                }
                return false; // symbol not found
            }
            int index = getBucketIndex(name);
            int position = 1;
            SymbolInfo * current = hash_table[index];
            if(current == toBeDeleted) {
                hash_table[index] = current->getNext();
            } else {
                while(current->getNext() != toBeDeleted) {
                    position++;
                    current = current->getNext();
                }
                position++;
                current->setNext(toBeDeleted->getNext());
            }
            if(verbose) {
                cout << "\tDeleted '" << name << "' from ScopeTable# " << id << " at position " << index + 1 << ", " << position << endl;
            }
            toBeDeleted->setNext(nullptr); // to avoid recursive deletion
            delete toBeDeleted;
            return true;
        }

        void print(int numberOfTabs = 0) {
            string tabs(numberOfTabs, '\t');
            cout << tabs << "ScopeTable# " << id << endl;
            for(int i = 0; i < num_buckets; i++) {
                cout << tabs << i + 1 << "--> ";
                SymbolInfo * current = hash_table[i];
                while(current != nullptr) {
                    cout << *current << " ";
                    current = current->getNext();
                }
                cout << endl;
            }
        }

        void print_to_log() {
            fprintf(log_file, "ScopeTable # %s\n", id.c_str());
            for(int i = 0; i < num_buckets; i++) {
                SymbolInfo * current = hash_table[i];
                if(current == nullptr) {
                    continue; // skip empty buckets
                }
                fprintf(log_file, "%d --> ", i);
                while(current != nullptr) {
                    current->print(log_file);
                    current = current->getNext();
                }
                fprintf(log_file, "\n");
            }
        }

        void setLogFile(FILE *log_file) {
            this->log_file = log_file;
        }
};




#endif // SCOPETABLE_HPP