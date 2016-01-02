/*
  UOC_TFG - Antonio Díaz Pozuelo - adpozuelo@uoc.edu
  Structures file header
  High-Dimensional Neural Network Potentials (HDNNP)
*/

#include "conf.h"

/*
  Atom structure
*/
typedef struct Atom {
	float c_x, c_y, c_z; // Atom coordinates
	float f_x, f_y, f_z; // Atom forces
	float g2_symmetry[G2_SIZE]; // Atom G2 symmetry function values
	float g3_symmetry[G3_SIZE]; // Atom G3 symmetry function values
} Atom;

/*
  Box of atoms structure
*/
typedef struct {
	float long_x, long_y, long_z; // Box length
	int number_of_atoms; // Number of atoms in box
	Atom *atoms; // Atoms in the box
} Box;

/*
  G2 symmetry function variables to form a combination of them
*/
typedef struct G2Combination {
	float n, rs;
} G2Combination;

/*
  G3 symmetry function variables to form a combination of them
*/
typedef struct G3Combination {
	float n, l;
	int s;
} G3Combination;
