/*
  UOC_TFG - Antonio Díaz Pozuelo - adpozuelo@uoc.edu
  Preconditioning G2 and G2 SF values functions file
  Preconditioning (feature selection and normalized) G2 and G3 SF values before run neural network
  Code is deployed in nn_preconditioning.cu
  High-Dimensional Neural Network Potentials (HDNNP)
*/

#ifndef NN_PRECONDITIONING_H
#define NN_PRECONDITIONING_H

/*
  Read box energy, G2 and G3 symmetry box values (max and min too) from files and do:
  1.- Reduce dimensionality (feature selection)
  2.- Normalize data before run neural network
  @arguments:
  char *input_filename_g2_learn: G2 SF filename to learn 
  char *input_filename_g3_learn: G3 SF filename to learn
  char *output_filename_g_normalized_learn: G SF normalized filename to learn
  int *g2_sf_valid: valid G2 SF
  float *g2_sf_min: G2 SF minimum values
  float *g2_sf_max: G2 SF maximum values
  int *g3_sf_valid: valid G3 SF
  float *g3_sf_min: G3 SF minimun values
  float *g3_sf_max: G3 SF maximum values
  int number_of_atoms_per_box: number of atoms per box
  int total_learn_timesteps: total learn timesteps (boxes)
  int total_predict_timesteps: total predict timesteps (boxes)
  char *input_filename_g2_predict: G2 SF filename to predict
  char *input_filename_g3_predict: G3 SF filename to predict
  char *output_filename_g_normalized_predict: G SF normalized filename to predict
*/
void nn_preconditioning(char *input_filename_g2_learn, char *input_filename_g3_learn, char *output_filename_g_normalized_learn, int *g2_sf_valid, float *g2_sf_min, float *g2_sf_max, int *g3_sf_valid, float *g3_sf_min, float *g3_sf_max, int number_of_atoms_per_box, int total_learn_timesteps, int total_predict_timesteps, char *input_filename_g2_predict, char *input_filename_g3_predict, char *output_filename_g_normalized_predict);

#endif
