/*
  UOC_TFG - Antonio Díaz Pozuelo - adpozuelo@uoc.edu
  Process input files functions header
  Process files using command line input temperatures to read learning and predict (ab-initio) input files
  Write output files with interleaved learn boxes and predict boxes (raw data)
  Code is deployed in process_input_files.cu
  High-Dimensional Neural Network Potentials (HDNNP)
*/

#ifndef PROCESS_INPUT_FILES_H
#define PROCESS_INPUT_FILES_H

/*
  Process files using command line input temperatures to learning and predict (raw data) input files
  Write output files with interleaved learn boxes and predict boxes (raw data)
  @arguments:
  int number_learning_temperatures: learning temperatures counter
  char *learning_history_files[] : learning history filenames
  char *learning_energy_files[]: learning energy filenames
  int number_predict_temperatures: predict temperatures counter
  char *predict_history_files[]: predict history filenames
  char *predict_energy_files[]: predict energy filenames
  int *number_of_atoms_per_box: number of atoms per box
  int *total_learn_timesteps: total learn timesteps (boxes)
  int *total_predict_timesteps: total predict timesteps (boxes)
  char *output_filename_learn: output filename to write interleaved learn boxes (raw data)
  char *output_filename_predict: output filename to write predict boxes (raw data)
*/
void process_input_files(int number_learning_temperatures, char *learning_history_files[], char *learning_energy_files[], int number_predict_temperatures, char *predict_history_files[], char *predict_energy_files[], int *number_of_atoms_per_box, int *total_learn_timesteps, int *total_predict_timesteps, char *output_filename_learn, char *output_filename_predict);

#endif
