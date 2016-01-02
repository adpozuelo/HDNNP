/*
  UOC_TFG - Antonio Díaz Pozuelo - adpozuelo@uoc.edu
  Process input files functions file
  Process files using command line input temperatures to read learning and predict (ab-initio) input files
  Write output files with interleaved learn boxes and predict boxes (raw data)
  Process files using command line input temperatures to generate neural network input files
  Header is specify in proccess_input_files.h
  High-Dimensional Neural Network Potentials (HDNNP)
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "messages.h"
#include "conf.h"

void process_input_files(int number_learning_temperatures, char *learning_history_files[], char *learning_energy_files[], int number_predict_temperatures, char *predict_history_files[], char *predict_energy_files[], int *number_of_atoms_per_box, int *total_learn_timesteps, int *total_predict_timesteps, char *output_filename_learn, char *output_filename_predict) {


	char *tmpBuffer = (char*) malloc(BUFFER_SIZE * sizeof(char)); // Allocate memory buffer

	// Open learn output file in write mode
	FILE *output_learn_file = fopen(output_filename_learn, "w"); 
	if (output_learn_file == NULL) { // Control learn output file open return
		print_opening_file_error_and_exit(); // If it fails, print error and exit
	}

	// Open input learn files (both history and energy) in read mode
	FILE *learning_history_input_files[number_learning_temperatures];
	FILE *learning_energy_input_files[number_learning_temperatures];
	for (int i = 0; i < number_learning_temperatures; i++) {
		learning_history_input_files[i] = fopen(learning_history_files[i], "r");
		learning_energy_input_files[i] = fopen(learning_energy_files[i], "r");
		if (learning_history_input_files[i] == NULL // Control input file open return
			|| learning_energy_input_files[i] == NULL) {
			print_opening_file_error_and_exit(); // If it fails, print error and exit
		}
	}

	// Trash first line of all files (history and energy), due to contains scratch data
	for (int i = 0; i < number_learning_temperatures; i++) {
		if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char),
				  learning_energy_input_files[i]) == NULL) {
			print_no_data_in_file_error_and_exit();
		}
		if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char),
				  learning_history_input_files[i]) == NULL) {
			print_no_data_in_file_error_and_exit();
		}
	}

	printf("\nWriting learning input file \"%s\"\n", output_filename_learn); // Print writing file information

	bool file_end = false; // End file control
  
	while (!file_end) { // While file is not ended
		// Go over all input learn files. !!!! Files are interleaved !!!!
		for (int i = 0; i < number_learning_temperatures && !file_end; i++) {
			// Read line from energy file, if line is empty then file is ended
			if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char),
					  learning_energy_input_files[i]) == NULL) {
				file_end = true;
			} else { // Else, file is not ended
				char *token; // Token variable
				int j = 0; // Token counter
				float energy = 0; // Box energy
				token = strtok(tmpBuffer, DELIM); // Line is chopped in tokens
				while (token) { // While there are tokens
					if (j == 1) { // Get energy value
						energy = atof(token); // Convert energy token value to energy variable
					}
					j++; // Update token counter
					token = strtok('\0', DELIM); // End token control
				}
				fprintf(output_learn_file, "%f\n", energy); // Write energy to output learn file
			}
			// Eead line from learn history file, if line is empty then file is ended
			if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char),
					  learning_history_input_files[i]) == NULL) {
				file_end = true;
			} else { // Else, file is not ended
				if (strstr(tmpBuffer, "timestep") != NULL) { // If line contains "timestep"
					(*total_learn_timesteps)++; // Update timesteps counter
					char *token; // Token variable
					int j = 0; // Token counter
					int number_of_atoms_timestep = 0; // Local number of atoms per timestep
					token = strtok(tmpBuffer, DELIM); // Line is chopped in tokens
					while (token) { // While there are tokens
						if (j == 2) { // Get number of atoms per box
							number_of_atoms_timestep = atoi(token); // Update local value
							// If box is the first in the loop
							if (*number_of_atoms_per_box == 0) {
								*number_of_atoms_per_box = number_of_atoms_timestep; // assign local to global value
							}
							/*
							 * All boxes have to contain the same number of atoms
							 */
							if (*number_of_atoms_per_box // If local value is not equal to global value
								!= number_of_atoms_timestep) {
								print_number_of_atoms_error_and_exit(); // Print error and exit
							}
						}
						j++; // Update token counter
						token = strtok('\0', DELIM); // End token control
					}
					// Get box lengths using its dimensions
					for (int g = 0; g < BOX_DIM; g++) {
						if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char),
								  learning_history_input_files[i]) == NULL) {
							file_end = true;
						} else {
							if (g == 0) { // First length (first line)
								int d = 0;
								char *token;
								token = strtok(tmpBuffer, DELIM);
								while (token) {
									if (d == 0) { // Get first token
										float tmp = atof(token);
										fprintf(output_learn_file, "%.10f ", tmp); // Write x.long to output learn file
									}
									d++;
									token = strtok('\0', DELIM);
								}
							}
							if (g == 1) { // Second length (second line)
								int d = 0;
								char *token;
								token = strtok(tmpBuffer, DELIM);
								while (token) {
									if (d == 1) { // Get second token
										float tmp = atof(token);
										fprintf(output_learn_file, "%.10f ", tmp); // write y.long to output learn file
									}
									d++;
									token = strtok('\0', DELIM);
								}
							}
							if (g == 2) { // Third length (third line)
								int d = 0;
								char *token;
								token = strtok(tmpBuffer, DELIM);
								while (token) {
									if (d == 2) { // Get third token
										float tmp = atof(token);
										fprintf(output_learn_file, "%.10f\n", tmp); // Write z.long to output learn file
									}
									d++;
									token = strtok('\0', DELIM);
								}
							}
						}
					}
					// Get atoms coordinates and forces
					for (int j = 0; j < *number_of_atoms_per_box; j++) { // Go over atoms
						for (int k = 0; k < 4; k++) { // Go over one atom (four lines)
							if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char),
									  learning_history_input_files[i]) == NULL) {
								file_end = true;
							} else {
								if (k == 1) { // Get coordinates (second line)
									char *token;
									token = strtok(tmpBuffer, DELIM);
									while (token) {
										float tmp = atof(token);
										// Write all tokens (coordinates) to output learn file
										fprintf(output_learn_file, "%.10e ", tmp);
										token = strtok('\0', DELIM);
									}
									fprintf(output_learn_file, "\n");
								}
								if (k == 3) { // Get forces (forth line)
									char *token;
									token = strtok(tmpBuffer, DELIM);
									while (token) {
										float tmp = atof(token);
										// Write all tokens (forces) to output learn file
										fprintf(output_learn_file, "%.10e ", tmp);
										token = strtok('\0', DELIM);
									}
									fprintf(output_learn_file, "\n");
								}
							}
						}
					}
				}
			}
		}
	}

	fclose(output_learn_file); // Close output learn file
	// Close all input learn files
	for (int i = 0; i < number_learning_temperatures; i++) {
		fclose(learning_energy_input_files[i]);
		fclose(learning_history_input_files[i]);
	}
	// Print information about output learn file is wrote
	printf("Learning input file \"%s\" wrote\n",
		   output_filename_learn);

	// Open predict output file in write mode
	FILE *output_predict_file = fopen(output_filename_predict, "w"); 
	if (output_predict_file == NULL) { // Control predict output file open return
		print_opening_file_error_and_exit(); // If it fails, print error and exit
	}

	// Open input predict files (both history and energy) in read mode
	FILE *predict_history_input_files[number_predict_temperatures];
	FILE *predict_energy_input_files[number_predict_temperatures];
	for (int i = 0; i < number_predict_temperatures; i++) {
		predict_history_input_files[i] = fopen(predict_history_files[i], "r");
		predict_energy_input_files[i] = fopen(predict_energy_files[i], "r");
		if (predict_history_input_files[i] == NULL // Control input file open return
			|| predict_energy_input_files[i] == NULL) {
			print_opening_file_error_and_exit(); // If it fails, print error and exit
		}
	}

	// Trash first line of both predict files (history and energy)
	for (int i = 0; i < number_predict_temperatures; i++) {
		if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char),
				  predict_energy_input_files[i]) == NULL) {
			print_no_data_in_file_error_and_exit();
		}
		if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char),
				  predict_history_input_files[i]) == NULL) {
			print_no_data_in_file_error_and_exit();
		}
	}

	printf("\nWriting predict input file \"%s\"\n",
		   output_filename_predict); // Print writing file information

	file_end = false; // End file control
  
	while (!file_end) { // While file is not ended
		// Go over all input predict files. !!!! Files are interleaved !!!!
		for (int i = 0; i < number_predict_temperatures && !file_end; i++) {
			// Read line from energy file, if line is empty then file is ended
			if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char),
					  predict_energy_input_files[i]) == NULL) {
				file_end = true;
			} else { // Else, file is not ended
				char *token; // Token variable
				int j = 0; // Token counter
				float energy = 0; // Box energy
				token = strtok(tmpBuffer, DELIM); // Line is chopped in tokens
				while (token) { // While there are tokens
					if (j == 1) { // Get energy value
						energy = atof(token); // Assign energy token value to energy variable
					}
					j++; // Update token counter
					token = strtok('\0', DELIM); // End token control
				}
				fprintf(output_predict_file, "%f\n", energy); // Write energy to output predict file
			}
			// Read line from history predict file, if line is empty then file is ended
			if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char),
					  predict_history_input_files[i]) == NULL) {
				file_end = true;
			} else { // Else, file is not ended
				if (strstr(tmpBuffer, "timestep") != NULL) { // If line contains "timestep"
					(*total_predict_timesteps)++; // Update timesteps counter
					char *token; // Token variable
					int j = 0; // Token counter
					int number_of_atoms_timestep = 0; // Local number of atoms per timestep
					token = strtok(tmpBuffer, DELIM); // Line is chopped in tokens
					while (token) { // While there are tokens
						if (j == 2) { // Get number of atoms per box
							number_of_atoms_timestep = atoi(token); // Update local value
							// If box is the first in the loop
							if (*number_of_atoms_per_box == 0) {
								*number_of_atoms_per_box =
									number_of_atoms_timestep; // assign local to global value
							}
							/*
							 * All boxes have to contain the same number of atoms
							 */
							if (*number_of_atoms_per_box // If local value is not equal to global value
								!= number_of_atoms_timestep) {
								print_number_of_atoms_error_and_exit(); // Print error and exit
							}
						}
						j++; // Update token counter
						token = strtok('\0', DELIM); // End token control
					}
					// Get box lengths using its dimensions
					for (int g = 0; g < BOX_DIM; g++) {
						if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char),
								  predict_history_input_files[i]) == NULL) {
							file_end = true;
						} else {
							if (g == 0) { // First length (first line)
								int d = 0;
								char *token;
								token = strtok(tmpBuffer, DELIM);
								while (token) {
									if (d == 0) { // Get first token
										float tmp = atof(token);
										fprintf(output_predict_file, "%.10f ", tmp); // Write x.long to output predict file
									}
									d++;
									token = strtok('\0', DELIM);
								}
							}
							if (g == 1) { // Second length (second line)
								int d = 0;
								char *token;
								token = strtok(tmpBuffer, DELIM);
								while (token) {
									if (d == 1) { // Get second token
										float tmp = atof(token);
										fprintf(output_predict_file, "%.10f ", tmp); // Write y.long to output predict file
									}
									d++;
									token = strtok('\0', DELIM);
								}
							}
							if (g == 2) { // Third length (third line)
								int d = 0;
								char *token;
								token = strtok(tmpBuffer, DELIM);
								while (token) {
									if (d == 2) { // Get third token
										float tmp = atof(token);
										fprintf(output_predict_file, "%.10f\n", tmp); // Write z.long to output predict file
									}
									d++;
									token = strtok('\0', DELIM);
								}
							}
						}
					}
					// Get atoms coordinates and forces
					for (int j = 0; j < *number_of_atoms_per_box; j++) { // Go over atoms
						for (int k = 0; k < 4; k++) { // Go over one atom (four lines)
							if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char),
									  predict_history_input_files[i]) == NULL) {
								file_end = true;
							} else {
								if (k == 1) { // Get coordinates (second line)
									char *token;
									token = strtok(tmpBuffer, DELIM);
									while (token) {
										float tmp = atof(token);
										// Write all tokens (coordinates) to output predict file
										fprintf(output_predict_file, "%.10e ", tmp);
										token = strtok('\0', DELIM);
									}
									fprintf(output_predict_file, "\n");
								}
								if (k == 3) { // Get forces (forth line)
									char *token;
									token = strtok(tmpBuffer, DELIM);
									while (token) {
										float tmp = atof(token);
										// Erite all tokens (forces) to output predict file
										fprintf(output_predict_file, "%.10e ", tmp);
										token = strtok('\0', DELIM);
									}
									fprintf(output_predict_file, "\n");
								}
							}
						}
					}
				}
			}
		}
	}

	fclose(output_predict_file); // Close output predict file
	// Close all input predict files
	for (int i = 0; i < number_predict_temperatures; i++) {
		fclose(predict_energy_input_files[i]);
		fclose(predict_history_input_files[i]);
	}
	// Print information about output file is wrote
	printf("Predict input file \"%s\" wrote\n",
		   output_filename_predict);

	free(tmpBuffer); // Release buffer memory
}
