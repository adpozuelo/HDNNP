/*
  UOC_TFG - Antonio Díaz Pozuelo - adpozuelo@uoc.edu
  Start neural network functions file
  Start neural network epochs and optimizing (learning process) variables between neurons and bias
  Code is deployed in nn_start.cu
  High-Dimensional Neural Network Potentials (HDNNP)
*/

#ifndef NN_START_H
#define NN_START_H

/*
  Start neural network epochs and optimizing (learning process) variables between neurons and bias
  @arguments:
  char *input_filename_g_normalized_learn: G SF normalized learn values filename
  char *input_filename_energy_learn: supervised energy learn filename
  char *input_filename_misc_data: miscelanea data filename
  char *output_filename_learning_process: learning process adjust (to graph) filename
  char *input_filename_g_normalized_predict: G SF normalized predict values filename
  char *output_filename_predict: final predict energy values
*/
void nn_start(char *input_filename_g_normalized_learn, char *input_filename_energy_learn, char *input_filename_misc_data, char *output_filename_learning_process, char *input_filename_g_normalized_predict, char *output_filename_predict);

#endif
