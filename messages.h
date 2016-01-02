/*
  UOC_TFG - Antonio Díaz Pozuelo - adpozuelo@uoc.edu
  Messages functions header
  Message control center to possible (future) location text
  Code is deployed in messages.cu
  High-Dimensional Neural Network Potentials (HDNNP)
*/

#ifndef MESSAGES_H
#define MESSAGES_H

/*
  Print command line help and exit application
*/
void print_help_and_exit(void);

/*
  Print warning about the need of both learning and predict set in command line arguments
*/
void print_both_learning_predict_sets_needed(void);

/*
  Print regular expression compilation error and exit application
*/
void print_regex_error_and_exit(void);

/*
  Print memory allocation error
*/
void print_memory_allocation_error(void);

/*
  Print opening file error and exit application
*/
void print_opening_file_error_and_exit(void);

/*
  Print number of atoms error and exit application
*/
void print_number_of_atoms_error_and_exit(void);

/*
  Print no data to read from file error and exit
*/
void print_no_data_in_file_error_and_exit(void);

/*
  Printf only one predict temperature is allowed
*/
void print_only_one_predict_temperature_allowed(void);

#endif
