/*
  UOC_TFG - Antonio Díaz Pozuelo - adpozuelo@uoc.edu
  Start neural network functions file
  Start neural network epochs and optimizing (learning process) variables between neurons and bias
  Header is specify in nn_start.h
  High-Dimensional Neural Network Potentials (HDNNP)
*/

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <math.h>
#include "messages.h"
#include "conf.h"

// Extern functions
extern"C" {
// wrapper function to call IMSL FORTRAN optimization library
	void wrapper_(int *np, int *nop, int *niter, int *icalc, float *x, float *y, float *yy, int *npar, float *xg, int *ib, float *xlb, float *xub, float *ftol, int *maxfcn, float *xfin, float *fvec, int *noa, int *ils, int *first);
	// residue function (Neural Network epochs)
	void residue_(int *symmetry_functions_number, float *symmetry_functions, float *energies, float *energies_fit, int *energies_number, float *parameters, int *parameters_number,int *iteration,float *residue, int *mode, int *atoms_number, int *input_layer_size);
}

void nn_start(char *input_filename_g_normalized_learn, char *input_filename_energy_learn, char *input_filename_misc_data, char *output_filename_learning_process, char *input_filename_g_normalized_predict, char *output_filename_predict) {

	char *tmpBuffer = (char*) malloc(BUFFER_SIZE * sizeof(char)); // Allocate memory buffer

	// Open G normalized symmetry functions learn file in read mode
	FILE *input_file_g_learn = fopen(input_filename_g_normalized_learn, "r");
	if (input_file_g_learn == NULL) {
		print_opening_file_error_and_exit();
	}
	// Read input layer size
	int input_layer_size;
	if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char), input_file_g_learn) == NULL) {
		print_no_data_in_file_error_and_exit();
	} else {
		input_layer_size = atoi(++tmpBuffer);
	}

	// Energy average, min and max values for las bias parameter
	float energy_average;
	float min_energy;
	float max_energy;

	// Open miscelanea file
	FILE *input_file_misc = fopen(input_filename_misc_data, "r");
	if (input_file_misc == NULL) {
		print_opening_file_error_and_exit();
	}
	if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char), input_file_misc) == NULL) {
		print_no_data_in_file_error_and_exit();
	} else {
		energy_average = atof(tmpBuffer); // Read energy average
	}
	if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char), input_file_misc) == NULL) {
		print_no_data_in_file_error_and_exit();
	} else {
		int n = 0;
		char *token;
		token = strtok(tmpBuffer, DELIM);
		while (token) {
			if (n == 0) // First token is energy minimum value                                                  
				min_energy = atof(token);
			if (n == 1) // Second token is energy maximum value                                                  
				max_energy = atof(token);
			n++;
			token = strtok('\0', DELIM);
		}
	}
	// Control total (learn and predict) timesteps
	int total_learn_timesteps = 0; 
	if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char), input_file_misc) == NULL) {
		print_no_data_in_file_error_and_exit();
	} else {
		total_learn_timesteps = atoi(tmpBuffer); // Read learn timesteps
	}
	int total_predict_timesteps = 0;
	if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char), input_file_misc) == NULL) {
		print_no_data_in_file_error_and_exit();
	} else {
		total_predict_timesteps = atoi(tmpBuffer); // Read predict timesteps
	}
	// Control number of atoms per box
	int number_of_atoms_per_box = 0;
	if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char), input_file_misc) == NULL) {
		print_no_data_in_file_error_and_exit();
	} else {
		number_of_atoms_per_box = atoi(tmpBuffer); // Read number of atoms per box
	}
	fclose(input_file_misc); // Close miscelanea file

	/*
	  Neural network parameters
	*/
	int parameters_number = ((input_layer_size * HIDDEN_LAYER_SIZE) + HIDDEN_LAYER_SIZE) +
		((HIDDEN_LAYER_SIZE * HIDDEN_LAYER_SIZE) + HIDDEN_LAYER_SIZE) + HIDDEN_LAYER_SIZE + 1;
	float parameters[parameters_number]; // Initial parameters (at last it will be fitted)
	float parameters_fit[parameters_number]; // Fitted parameters
	// Initialize parameters with random number (-1, 1)
	srand(time(NULL));
	float a = 2.0;
	for (int i = 0; i < parameters_number; i++){
		parameters[i] = (float) (rand() / (float) ((RAND_MAX)) * a) - 1;
	}
	// Lowest and highest parameters values
	float xlb[parameters_number];
	float xub[parameters_number];
	// Initialize lowest and highest values (-1, 1)
	for (int i = 0; i < parameters_number - 1; i++){
		xlb[i]=-1;
		xub[i]=1;
	}
	/* 
	   Last parameter is bias weight to output neuron guide it to correct optimization.
	   It is initialized with energy average and its limits are bound to maximum and minimum energies values
	*/
	xlb[parameters_number-1] = min_energy / number_of_atoms_per_box;
	xub[parameters_number-1] = max_energy / number_of_atoms_per_box;
	parameters[parameters_number-1] = energy_average / number_of_atoms_per_box;

	/*
	  IMSL parameters
	*/
	float ftol = FTOL; // OPT tolerance
	int ib = IB; // OPT option
	int maxfcn = MAXFCN; // OPT maximum functions to call
	int mode; // Neural network mode: 1 to learn, 0 to predict
	float fvec = 0; // Cost function's residue for IMSL optimization
	int nop = NUMBER_OF_BOXES_TO_OPT; // Number of boxes to optimize in paralell mode
	int first_exe = 1; // First wrapper execution control to IWKIN FORTRAN parameter
	
	/*
	  Energies
	*/
	float energies[NUMBER_OF_BOXES_TO_OPT]; // Supervised energies
	float energies_fit[NUMBER_OF_BOXES_TO_OPT]; // Predicted energies
	// Open energy learn file in read mode
	FILE *input_file_energy_learn = fopen(input_filename_energy_learn, "r");
	if (input_file_energy_learn == NULL) {
		print_opening_file_error_and_exit();
	}
	
	/*
	  Symmetry functions (input layer)
	*/
	int symmetry_functions_number = input_layer_size * number_of_atoms_per_box * NUMBER_OF_BOXES_TO_OPT;
	float symmetry_functions[symmetry_functions_number];

	// File control variables
	int local_timestep = 0; // Local timesteps counter
	bool file_end = false; // End line control
	
	// Open learning process output file (graph)
	FILE *output_file_learning_process = fopen(output_filename_learning_process, "w");
	if (output_file_learning_process == NULL) {
		print_opening_file_error_and_exit();
	}
	// Write header to learning process output file
	fprintf(output_file_learning_process, "Energy_Predicted Energy_Supervised\n");

	// Print process information
	printf("Neural network start\nNeural network learning!\n");
	
	/*
	  Neural network learning mode
	 */
	while (!file_end && local_timestep < total_learn_timesteps) { // Go over all input learn file
	 	int niter = 0; // Local iterations for ISML optimization
		for (int j = 0; j < NUMBER_OF_BOXES_TO_OPT; j++) { // Go over number of boxes to process and optimize
			for (int i = 0; i < number_of_atoms_per_box; i++) { // Read atoms from G normalized learn file
				if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char),
						  input_file_g_learn) == NULL) {
					file_end = true;
				} else {
					int n = 0;
					char *token;
					token = strtok(tmpBuffer, DELIM);
					while (token && n < input_layer_size) {
						// read each representation value of atom and store them into vector (serialized data)
						symmetry_functions[(j * number_of_atoms_per_box * input_layer_size) +
										   (i * input_layer_size) + n] = atof(token);
						n++;
						token = strtok('\0', DELIM);
					}
				}
			}
			// Read energy from learn file
			if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char),
					  input_file_energy_learn) == NULL) {
				file_end = true;
			} else {
				energies[j] = atof(tmpBuffer); // Read energy
			}
		}
		// Neural network in learning process start
		if (!file_end) {
			// Call to FORTRAN WRAPPER (NN in learning mode)
			wrapper_(&symmetry_functions_number, &nop, &niter, &mode, symmetry_functions, energies, energies_fit, &parameters_number, parameters, &ib, xlb, xub, &ftol, &maxfcn, parameters_fit, &fvec, &number_of_atoms_per_box, &input_layer_size, &first_exe); 
			// Write learning process to output file (graph)
			for (int i = 0; i < nop; i++)
				fprintf(output_file_learning_process, "%.10e %.10e\n", energies_fit[i], energies[i]);
			fflush(output_file_learning_process); // Flush file stream

			local_timestep+=NUMBER_OF_BOXES_TO_OPT; // Update timestep local counter
			first_exe = 0; // Set first execution control variable to 0
		}
		// Reading control file *** REMOVE ***
		// if (local_timestep == 500)
		// 	file_end=true;
		// Reading control file *** REMOVE ***
	}
	// Closing learning files
	fclose(input_file_g_learn);
	fclose(input_file_energy_learn);
	fclose(output_file_learning_process);

	// Open G normalized symmetry functions predict file in read mode
	FILE *input_file_g_predict = fopen(input_filename_g_normalized_predict, "r");
	if (input_file_g_predict == NULL) {
		print_opening_file_error_and_exit();
	}
  
	// Open output predict file in write mode 
	FILE *output_file_predict = fopen(output_filename_predict, "w");
	if (output_file_predict == NULL) {
		print_opening_file_error_and_exit();
	}

	// Print process information
	printf("\nNeural network predicting!\n");
	
	local_timestep = 0; // Reset local timesteps
	file_end = false; // Reset file end control
	/*
	  Neural network predicting mode
	 */
	while (!file_end && local_timestep < total_predict_timesteps) { // Go over all input predict file
		for (int j = 0; j < NUMBER_OF_BOXES_TO_OPT; j++) { // Go over number of boxes to process and optimize
			for (int i = 0; i < number_of_atoms_per_box; i++) { // Read atoms from G normalized learn file
				if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char),
						  input_file_g_predict) == NULL) {
					file_end = true;
				} else {
					int n = 0;
					char *token;
					token = strtok(tmpBuffer, DELIM);
					while (token && n < input_layer_size) {
						// read each representation value of atom and store them into vector (serialized data)
						symmetry_functions[(j * number_of_atoms_per_box * input_layer_size) +
										   (i * input_layer_size) + n] = atof(token);
						n++;
						token = strtok('\0', DELIM);
					}
				}
			}
		}
		// Neural network in predicting process start
		if (!file_end) {
			mode = 0; // Set mode to NN prediction
			int niter = 0; // Reset local iteration
			// Call to GPU neural network epoch in predict mode
			residue_(&symmetry_functions_number, symmetry_functions, energies, energies_fit, &nop, parameters, &parameters_number, &niter, &fvec, &mode, &number_of_atoms_per_box, &input_layer_size);
			// Write energies predicted to output energies file
			for (int i=0; i<nop; i++)
				fprintf(output_file_predict, "%.10e\n", energies_fit[i]);
			fflush(output_file_predict); // Flush file stream

			local_timestep+=NUMBER_OF_BOXES_TO_OPT; // Update timestep local counter
		}
		// Reading control file *** REMOVE ***
		// if (local_timestep == 500)
		// 	file_end=true;
		// Reading control file *** REMOVE ***
	}
  
	// Closing predict files
	fclose(input_file_g_predict);
	fclose(output_file_predict);

	// Print process information
	printf("Neural network stop\n");
}
