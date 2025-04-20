#ifndef _HASH_HPP_
#define _HASH_HPP_

#include <string>
using namespace std;

class Hash {
    public:
        static unsigned int SDBMHash(string str) {
            unsigned int hash = 0;
            unsigned int i = 0;
            unsigned int len = str.length();
        
            for (i = 0; i < len; i++)
            {
                hash = (str[i]) + (hash << 6) + (hash << 16) - hash;
            }
        
            return hash;
        }
};



#endif // _HASH_HPP_