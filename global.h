#ifndef GLOBAL_H
#define GLOBAL_H

#include <string>

//Unit cell parameters
extern int Natoms, Tatoms;
extern double a, b, c;
extern double alpha, beta, gama;
extern std::string setting;

//Default merw parameters
extern int Neqsteps;	//Number of steps to find equilibrium position
extern int Nvisits;		//Number of visits needed to select a new Al

//atom structure
typedef struct{
  char id[5], at[5];
  double x, y, z, q;
} atom;

#endif // GLOBAL_H