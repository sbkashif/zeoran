#ifndef OUTPUT_H
#define OUTPUT_H

#include <string>
#include <vector>
#include "global.h"

using namespace std;

// Function declarations for output module
void print_structure(atom *list, vector<int> Als, int struc, string name_zeo, string name_alg, string out_name);
void print_gro_structure(atom *list, vector<int> Als, int struc, string name_zeo, string name_alg, string out_name);

#endif // OUTPUT_H
