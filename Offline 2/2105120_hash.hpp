#ifndef _HASH_HPP_
#define _HASH_HPP_

#include <string>
using namespace std;

class Hash
{
public:
    static unsigned int SDBMHash(string str, unsigned int num_buckets)
    {
        unsigned int hash = 0;
        unsigned int len = str.length();
        for (unsigned int i = 0; i < len; i++)
        {
            hash = ((str[i]) + (hash << 6) + (hash << 16) - hash) %
                   num_buckets;
        }
        return hash;
    }

    static unsigned int BKDRHash(string str, unsigned int num_buckets) // Hash function collected from https://www.partow.net/programming/hashfunctions/#BKDRHashFunction
    {
        unsigned int seed = 131; /* 31 131 1313 13131 131313 etc.. */
        unsigned int hash = 0;
        unsigned int i = 0;
        unsigned int length = str.length();

        for (i = 0; i < length; ++i)
        {
            hash = ((hash * seed) + (str[i])) % num_buckets;
        }

        return hash;
    }

    static unsigned int DJBHash(string str, unsigned int num_buckets) // Hash function collected from https://www.partow.net/programming/hashfunctions/#DJBHashFunction
    {
        unsigned int hash = 5381;
        unsigned int i = 0;
        unsigned int length = str.length();

        for (i = 0; i < length; ++i)
        {
            hash = (((hash << 5) + hash) + (str[i])) % num_buckets; 
        }

        return hash;
    }
};

#endif // _HASH_HPP_