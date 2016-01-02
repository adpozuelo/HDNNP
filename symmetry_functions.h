/*
  UOC_TFG - Antonio Díaz Pozuelo - adpozuelo@uoc.edu
  Symmetry functions header
  Symmetry functions to generate atom's cutoff representation
  Code is deployed in symmetry_functions.cu
  High-Dimensional Neural Network Potentials (HDNNP)
*/

#ifndef SYMMETRY_FUNCTIONS_H
#define SYMMETRY_FUNCTIONS_H

/*
  Calculate both G2 and G3 symmetry functions for a box of atoms
  @arguments:
  Box *box_of_atoms: @return box of atoms
  G2Combination *g2_combination: G2 SF combination
  G3Combination *g3_combination: G3 SF combination
*/
void calculate_symmetry_functions(Box *box_of_atoms, G2Combination *g2_combination, G3Combination *g3_combination);

#endif
