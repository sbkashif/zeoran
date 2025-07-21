#include "global.h"

//Unit cell parameters
int Natoms, Tatoms;
double a, b, c;
double alpha, beta, gama;
std::string setting;

//Default merw parameters
int Neqsteps = 100;	//Number of steps to find equilibrium position
int Nvisits = 20;	//Number of visits needed to select a new Al
