/*
  UOC_TFG - Antonio Díaz Pozuelo - adpozuelo@uoc.edu
  Miscellaneous functions header
  Utility functions without specific area
  Code is deployed in misc.cu
  High-Dimensional Neural Network Potentials (HDNNP)
*/

#ifndef MISC_H
#define MISC_H

/*
  Control application command line input to avoid invalid data
  @arguments:
  int argc: number of arguments
  char *argv[]: arguments array
  int *number_learning_temperatures_final: @return learning temperatures counter
  int *number_predict_temperatures_final: @return predict temperatures counter
*/
void application_input_control(int argc, char *argv[], int *number_learning_temperatures_final, int *number_predict_temperatures_final);

/*
  Generate filenames to read input data files
  @arguments:
  int argc: number of arguments
  char *argv[]: arguments array
  char *learning_history_files[]: @return learning history filenames
  char *learning_energy_files[]: @return learning energy history filenames
  char *predict_history_files[]: @return predict history filenames
  char *predict_energy_files[]: @return predict energy filenames
*/
void generate_filenames(int argc, char *argv[], char *learning_history_files[], char *learning_energy_files[], char *predict_history_files[], char *predict_energy_files[]);

/*
  Match regular expression pattern in string
  @arguments:
  const char *string: string to match regular expression
  char *pattern: regular expression pattern
  @return:
  1: regular expression pattern does match in string
  0: regular expression pattern doesn't match in string
*/
int regex_match(const char *string, char *pattern);

/*
  Normalize a value
  @arguments:
  float value_g: value to normalize
  float min: global minimum value
  float max: global maximum value
  @return:
  value_g normalized
*/
float normalize_float(float value_g, float min, float max);

#endif
