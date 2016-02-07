/*
  UOC_TFG - Antonio Díaz Pozuelo - adpozuelo@uoc.edu
  Preconditioning G2 and G2 SF values functions file
  Preconditioning (feature selection and normalized) G2 and G3 SF values before run neural network
  Header is specify in nn_preconditioning.h
  High-Dimensional Neural Network Potentials (HDNNP)
*/

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include "messages.h"
#include "conf.h"
#include "misc.h"

void nn_preconditioning(char *input_filename_g2_learn, char *input_filename_g3_learn, char *output_filename_g_normalized_learn, int *g2_sf_valid, float *g2_sf_min, float *g2_sf_max, int *g3_sf_valid, float *g3_sf_min, float *g3_sf_max,int number_of_atoms_per_box, int total_learn_timesteps, int total_predict_timesteps, char *input_filename_g2_predict, char *input_filename_g3_predict, char *output_filename_g_normalized_predict) {

	printf("\nPreconditioning symmetry functions data\n");

	char *tmpBuffer = (char*) malloc(BUFFER_SIZE * sizeof(char)); // Allocate memory buffer

	// Open G2 symmetry functions learn file in read mode
	FILE *input_file_g2_learn = fopen(input_filename_g2_learn, "r");
	if (input_file_g2_learn == NULL) {
		print_opening_file_error_and_exit();
	}
	// Trash G2 file first line
	if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char), input_file_g2_learn) == NULL) {
		print_no_data_in_file_error_and_exit();
	}

	// Open G3 symmetry functions learn file in read mode
	FILE *input_file_g3_learn = fopen(input_filename_g3_learn, "r");
	if (input_file_g3_learn == NULL) {
		print_opening_file_error_and_exit();
	}
	// Trash G3 file first line
	if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char), input_file_g3_learn) == NULL) {
		print_no_data_in_file_error_and_exit();
	}

	// Open output symmetry functions learn file in write mode (graph)
	FILE *output_file_learn = fopen(G2G3SYMFILE, "w");
	if (output_file_learn == NULL) {
		print_opening_file_error_and_exit();
	}

	// Open output symmetry functions normalized learn file in write mode
	FILE *output_file_normalized_learn = fopen(output_filename_g_normalized_learn, "w");
	if (output_file_normalized_learn == NULL) {
		print_opening_file_error_and_exit();
	}

	// Count valid G2 and G3 SF
	int g2_sf_valid_counter=0;
	for (int i=0; i<G2_SIZE; i++){
		if (g2_sf_valid[i]==1)
			g2_sf_valid_counter++;
	}
	int g3_sf_valid_counter=0;
	for (int i=0; i<G3_SIZE; i++){
		if (g3_sf_valid[i]==1)
			g3_sf_valid_counter++;
	}

	// Control neural network input layer size
	int g_total_valid_counter=0;
	if (MAX_G_SIZE_TO_OPT != 0)
		g_total_valid_counter = MAX_G_SIZE_TO_OPT;
	else
		g_total_valid_counter = G_TOTAL_SIZE;

	// Write NN input layer size to output normalized learn file
	fprintf(output_file_normalized_learn, "#%d\n", g_total_valid_counter);

	int local_timestep = 0; // Local timestep counter
	bool file_end = false; // File end control

	// Vectors to normalize G2 and G3 values
	float g2_sf[G2_SIZE];
	float g3_sf[G3_SIZE];
	float g2_sf_normalized[G2_SIZE];
	float g3_sf_normalized[G3_SIZE];

	// Go over input SF learn files
	while (!file_end && local_timestep < total_learn_timesteps * number_of_atoms_per_box) {
		for (int i = 0; i < number_of_atoms_per_box; i++) { // Go over all atoms
			// Read atom line from G2 file
			if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char), input_file_g2_learn) == NULL) {
				file_end = true;
			} else {
				local_timestep++; // Update timestep local counter
				int n = 0;
				char *token;
				token = strtok(tmpBuffer, DELIM);
				while (token) {
					if (n < G2_SIZE) {
						g2_sf[n]=atof(token); // Get G2 value and save it into vector (not normalized)
					}
					n++;
					token = strtok('\0', DELIM);
				}
			}
			// Read atom line from G3 file
			if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char), input_file_g3_learn) == NULL) {
				file_end = true;
			} else {
				int n = 0;
				char *token;
				token = strtok(tmpBuffer, DELIM);
				while (token) {
					if (n < G3_SIZE) {
						g3_sf[n]=atof(token); // Get G3 value and save it into vector (not normalized)
					}
					n++;
					token = strtok('\0', DELIM);
				}
			}

			if (!file_end){
				// Normalizating G2 and G3 values
				for (int i=0; i<G2_SIZE; i++){
					g2_sf_normalized[i]=normalize_float(g2_sf[i],g2_sf_min[i],g2_sf_max[i]);
				}
				for (int i=0; i<G3_SIZE; i++){
					g3_sf_normalized[i]=normalize_float(g3_sf[i],g3_sf_min[i],g3_sf_max[i]);
				}
				// Feature selection, only save valid G2 and G3 SF
				float g2_sf_final[g2_sf_valid_counter];
				float g2_sf_final_normalized[g2_sf_valid_counter];
				int m = 0;
				for (int i=0; i<G2_SIZE; i++){
					if (g2_sf_valid[i]==1){
						g2_sf_final[m]=g2_sf[i];
						g2_sf_final_normalized[m]=g2_sf_normalized[i];
						m++;
					}
				}
				float g3_sf_final[g3_sf_valid_counter];
				float g3_sf_final_normalized[g3_sf_valid_counter];
				m = 0;
				for (int i=0; i<G3_SIZE; i++){
					if (g3_sf_valid[i]==1){
						g3_sf_final[m]=g3_sf[i];
						g3_sf_final_normalized[m]=g3_sf_normalized[i];
						m++;
					}
				}
				// Write to G normalized learn output file valid and normalized G2 and G3 values
				for(int j = 0; j < g_total_valid_counter; j++){
					if (j < g2_sf_valid_counter) {
						fprintf(output_file_learn, "%.10e ", g2_sf_final[j]); // only for graph
						fprintf(output_file_normalized_learn, "%.10e ", g2_sf_final_normalized[j]);
					}
					if (j < g3_sf_valid_counter) {
						fprintf(output_file_learn, "%.10e ", g3_sf_final[j]); // only for graph
						fprintf(output_file_normalized_learn, "%.10e ", g3_sf_final_normalized[j]);
					}
				}
				// Add end line to output learn files
				fprintf(output_file_learn, "\n");
				fprintf(output_file_normalized_learn, "\n");
			}

		}
	}
	// Closing learn files
	fclose(input_file_g2_learn);
	fclose(input_file_g3_learn);
	fclose(output_file_learn);
	fclose(output_file_normalized_learn);

	// Printf information
	printf("Symmetry functions data preconditioned files created \"%s\" and \"%s\"\n", output_filename_g_normalized_learn, G2G3SYMFILE);

	// Open G2 symmetry functions predict file in read mode
	FILE *input_file_g2_predict = fopen(input_filename_g2_predict, "r");
	if (input_file_g2_predict == NULL) {
		print_opening_file_error_and_exit();
	}
	// Trash G2 file first line
	if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char), input_file_g2_predict) == NULL) {
		print_no_data_in_file_error_and_exit();
	}

	// Open G3 symmetry functions predict file in read mode
	FILE *input_file_g3_predict = fopen(input_filename_g3_predict, "r");
	if (input_file_g3_predict == NULL) {
		print_opening_file_error_and_exit();
	}
	// Trash G3 file first line
	if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char), input_file_g3_predict) == NULL) {
		print_no_data_in_file_error_and_exit();
	}

	// Open output symmetry functions normalized predict file in write mode
	FILE *output_file_normalized_predict = fopen(output_filename_g_normalized_predict, "w");
	if (output_file_normalized_predict == NULL) {
		print_opening_file_error_and_exit();
	}
	// Write NN input layer size to normalized predict output file
	fprintf(output_file_normalized_predict, "#%d\n", g_total_valid_counter);

	local_timestep = 0; // Local timestep counter
	file_end = false; // File end control

	// Go over predict files
	while (!file_end && local_timestep < total_predict_timesteps * number_of_atoms_per_box) {
		for (int i = 0; i < number_of_atoms_per_box; i++) { // Go over all atoms
			// Read atom line from G2 file
			if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char), input_file_g2_predict) == NULL) {
				file_end = true;
			} else {
				local_timestep++;
				int n = 0;
				char *token;
				token = strtok(tmpBuffer, DELIM);
				while (token) {
					if (n < G2_SIZE) {
						g2_sf[n]=atof(token); // Get G2 value and save it into G2 vector (not normalized)
					}
					n++;
					token = strtok('\0', DELIM);
				}
			}
			// Read atom line from G3 file
			if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char), input_file_g3_predict) == NULL) {
				file_end = true;
			} else {
				int n = 0;
				char *token;
				token = strtok(tmpBuffer, DELIM);
				while (token) {
					if (n < G3_SIZE) {
						g3_sf[n]=atof(token); // Get G3 value and save it into G3 vector (not normalized)
					}
					n++;
					token = strtok('\0', DELIM);
				}
			}

			if (!file_end){
				// Normalizating G2 and G3 values
				for (int i=0; i<G2_SIZE; i++){
					g2_sf_normalized[i]=normalize_float(g2_sf[i],g2_sf_min[i],g2_sf_max[i]);
				}
				for (int i=0; i<G3_SIZE; i++){
					g3_sf_normalized[i]=normalize_float(g3_sf[i],g3_sf_min[i],g3_sf_max[i]);
				}
				// Feature selection, only save valid G2 and G3 SF
				float g2_sf_final_normalized[g2_sf_valid_counter];
				int m = 0;
				for (int i=0; i<G2_SIZE; i++){
					if (g2_sf_valid[i]==1){
						g2_sf_final_normalized[m]=g2_sf_normalized[i];
						m++;
					}
				}
				float g3_sf_final_normalized[g3_sf_valid_counter];
				m = 0;
				for (int i=0; i<G3_SIZE; i++){
					if (g3_sf_valid[i]==1){
						g3_sf_final_normalized[m]=g3_sf_normalized[i];
						m++;
					}
				}
				// Write to G normalized predict output file valid and normalized G2 and G3 values
				for(int j = 0; j < g_total_valid_counter / 2; j++){
					if (j < g2_sf_valid_counter) {
						fprintf(output_file_normalized_predict, "%.10e ", g2_sf_final_normalized[j]);
					}
					if (j < g3_sf_valid_counter) {
						fprintf(output_file_normalized_predict, "%.10e ", g3_sf_final_normalized[j]);
					}
				}
				// Add end line to output predict file
				fprintf(output_file_normalized_predict, "\n");
			}

		}
	}
	// Closing predict files
	fclose(input_file_g2_predict);
	fclose(input_file_g3_predict);
	fclose(output_file_normalized_predict);

	// Releasing memory
	free(tmpBuffer);

	// Print information about preconditioning process
	printf("Symmetry functions data preconditioned files created \"%s\"\n", output_filename_g_normalized_predict);
}
