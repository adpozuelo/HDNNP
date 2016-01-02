/*
  UOC_TFG - Antonio Díaz Pozuelo - adpozuelo@uoc.edu
  Messages functions file
  Message control center to possible (future) location text
  Header is specify in messages.h
  High-Dimensional Neural Network Potentials (HDNNP)
*/

#include <stdio.h>
#include <stdlib.h>

void print_help_and_exit(void) {
	printf("Usage: HDNNP ARGUMENTS...\n");
	printf("Arguments:\n");
	printf("	l   temperature (Kelvin, from 0 to 9999) systems which neural network will learn\n");
	printf("	p   temperature (Kelvin, from 0 to 9999) systems which neural network will predict (only one predict temperature is allowed)\n");
	printf("Examples:\n");
	printf("	HDNNP l456 l654 p333\n");
	printf("	HDNNP l234 l469 l567 l555 p667\n");
	exit(1);
}

void print_both_learning_predict_sets_needed(void) {
	printf("Error: both learning and predict sets are needed!\n");
}

void print_regex_error_and_exit(void) {
	printf("Error: regular expression problem!\n");
	exit(1);
}

void print_memory_allocation_error(void) {
	printf("Error: memory allocation problem!\n");
}

void print_opening_file_error_and_exit(void) {
	printf("File open error");
	exit(1);
}

void print_number_of_atoms_error_and_exit(void) {
	printf("Error: number of atoms have to be the same in all timesteps!\n");
	exit(1);
}

void print_no_data_in_file_error_and_exit(void) {
	printf("Error: no data to read from file!\n");
	exit(1);
}

void print_only_one_predict_temperature_allowed() {
	printf("Error: only one predict temperature is allowed!\n");
}
