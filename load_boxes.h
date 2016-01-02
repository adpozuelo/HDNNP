/*
  UOC_TFG - Antonio Díaz Pozuelo - adpozuelo@uoc.edu
  Load boxes and generate SF values functions header
  Read one timestep of atoms to form a box of atoms and calculate and write to files both g2 and g3 symmetry functions for both learn and predict raw data
  Code is deployed in load_boxes.cu
  High-Dimensional Neural Network Potentials (HDNNP)
*/

#ifndef LOAD_BOXES_H
#define LOAD_BOXES_H

/*
  Read one timestep of atoms to form a box of atoms and calculate and write to files both g2 and g3 symmetry functions for both learn and predict raw data
  @arguments:
  char *learning_filename: interleaved boxes filename to learn (raw data)
  char *predict_filename: boxes filename to predict (raw data)
  int number_of_atoms_per_box: number of atoms per box
  int total_learn_timesteps: total learn timesteps
  int total_predict_timesteps: total predict timesteps
  char *output_filename_g2_learn: G2 symmetry functions filename to learn
  char *output_filename_g3_learn: G3 symmetry functions filename to learn
  char *output_filename_misc_data: miscelanea data filename
  char *output_filename_energy_learn: supervised learn energy filename
  char *output_filename_g2_predict: G2 symmetry functions filename to predict
  char *output_filename_g3_predict: G3 symmetry functions filename to predict
  char *output_filename_energy_predict: supervised predict energy filename
  int *g2_sf_valid: @return valid G2 symmetry functions
  float *g2_sf_min: @return G2 symmetry functions minimum
  float *g2_sf_max: @return G2 symmetry functions maximum
  int *g3_sf_valid: @return valid G3 symmetry functions
  float *g3_sf_min: @return G3 symmetry functions minimum
  float *g3_sf_max: @return G3 symmetry functions maximum
*/
void load_boxes_and_generate_symmetry_functions(char *learning_filename, char *predict_filename, int number_of_atoms_per_box, int total_learn_timesteps, int total_predict_timesteps, char *output_filename_g2_learn, char *output_filename_g3_learn, char *output_filename_misc_data, char *output_filename_energy_learn, char *output_filename_g2_predict, char *output_filename_g3_predict, char *output_filename_energy_predict, int *g2_sf_valid, float *g2_sf_min, float *g2_sf_max, int *g3_sf_valid, float *g3_sf_min, float *g3_sf_max);

#endif
