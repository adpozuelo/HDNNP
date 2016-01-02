/*
  UOC_TFG - Antonio Díaz Pozuelo - adpozuelo@uoc.edu
  Neural network epochs header file
  Execute neural network epochs
  Code is deployed in residue.cu
  High-Dimensional Neural Network Potentials (HDNNP)
*/

#ifndef RESIDUE_H
#define RESIDUE_H

/*
  Execute neural network epochs
  @arguments:
  int *symmetry_functions_number: number of symmetry functions
  float *symmetry_functions: symmetry functions (data vector serialized)
  float *energies: energies
  float *energies_fit: @return energies fitted
  int *energies_number: number of energies
  float *parameters: @return parameters
  int *parameters_number: number of parameters
  int *iteration: iteration
  float *residue: @return cost funtion residue
  int *mode: neural network mode (1 to learn, 0 to predict)
  int *atoms_number: number of atoms
  int *input_layer_size: input layer size
*/
void residue_(int *symmetry_functions_number, float *symmetry_functions, float *energies, float *energies_fit, int *energies_number, float *parameters, int *parameters_number,int *iteration,float *residue, int *mode, int *atoms_number, int *input_layer_size);

#endif
