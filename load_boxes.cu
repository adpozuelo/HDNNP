/*
  UOC_TFG - Antonio Díaz Pozuelo - adpozuelo@uoc.edu
  Load boxes and generate SF values functions file
  Read one timestep of atoms to form a box of atoms and calculate and write to files both g2 and g3 symmetry functions for both learn and predict raw data
  Header is specify in load_boxes.h
  High-Dimensional Neural Network Potentials (HDNNP)
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "messages.h"
#include "structs.h"
#include "symmetry_functions.h"
#include "conf.h"

void load_boxes_and_generate_symmetry_functions(char *learning_filename, char *predict_filename, int number_of_atoms_per_box, int total_learn_timesteps, int total_predict_timesteps, char *output_filename_g2_learn, char *output_filename_g3_learn, char *output_filename_misc_data, char *output_filename_energy_learn, char *output_filename_g2_predict, char *output_filename_g3_predict, char *output_filename_energy_predict, int *g2_sf_valid, float *g2_sf_min, float *g2_sf_max, int *g3_sf_valid, float *g3_sf_min, float *g3_sf_max) {

	char *tmpBuffer = (char*) malloc(BUFFER_SIZE * sizeof(char)); // Allocate memory to buffer

	printf("\nGenerating learning symmetry functions sets (boxes):");
	/*
	 * G2 symmetry function's variables and their combinations
	 */
	float n[6] = { 0, 0.04, 0.14, 0.32, 0.71, 1.79 };
	float rs[6] = { 0, 1, 2, 3, 4, 5 };
	G2Combination *g2_combination = (G2Combination*) malloc(
		sizeof(G2Combination) * G2_SIZE);
	for (int i = 0; i < 6; i++) { // "n" array variables
		for (int j = 0; j < 6; j++) { // "rs" array variables
			g2_combination[(i * 6) + j].n = n[i];
			g2_combination[(i * 6) + j].rs = rs[j];
		}
	}

	/*
	 * G3 symmetry function's variables and their combinations
	 * "n" previous variable array is used too!!!!
	 */
	int s[4] = { 1, 2, 4, 16 };
	float l[2] = { -1, 1 };
	G3Combination *g3_combination = (G3Combination*) malloc(
		sizeof(G3Combination) * G3_SIZE);
	for (int i = 0; i < 6; i++) { // "n" array variables
		for (int j = 0; j < 4; j++) { // "s" array variables
			for (int k = 0; k < 2; k++) { // "l" array variables
				g3_combination[(i * 8) + (j * 2) + k].n = n[i];
				g3_combination[(i * 8) + (j * 2) + k].s = s[j];
				g3_combination[(i * 8) + (j * 2) + k].l = l[k];
			}
		}
	}

	float global_energy_min = 10E6; // Global minimum energy value for further optimization
	float global_energy_max = -10E6; // Global maximum energy value for further optimization
	float energy_average = 0; // Energy accumulator for further average

	/*
	  G2 and G3 SF accumulator for further feature selection
	 */
	float g2_sf_accumulator[G2_SIZE];
	for (int i=0; i<G2_SIZE; i++){
		g2_sf_accumulator[i]=0;
	}
	float g3_sf_accumulator[G3_SIZE];  
	for (int i=0; i<G3_SIZE; i++){
		g3_sf_accumulator[i]=0;
	}

	Box box_of_atoms; // Box of atoms
	box_of_atoms.number_of_atoms = number_of_atoms_per_box; // Number of atoms per box
	box_of_atoms.atoms = (Atom*) malloc(number_of_atoms_per_box * sizeof(Atom)); // Allocate memory to box of atoms

	// Open leaning file to load boxes in read mode
	FILE *learning_file = fopen(learning_filename, "r");
	if (learning_file == NULL) {
		print_opening_file_error_and_exit();
	}
	// Open G2 symmetry output learn file in write mode
	FILE *output_file_g2_learn = fopen(output_filename_g2_learn, "w");
	if (output_file_g2_learn == NULL) {
		print_opening_file_error_and_exit();
	}
	// Open G3 symmetry output learn file in write mode
	FILE *output_file_g3_learn = fopen(output_filename_g3_learn, "w");
	if (output_file_g3_learn == NULL) {
		print_opening_file_error_and_exit();
	}
	// Write G2 and G3 file headers to output learn files
	fprintf(output_file_g2_learn, "#");
	for (int i = 0; i < 6; i++) {
		for (int j = 0; j < 6; j++) {
			fprintf(output_file_g2_learn, "n=%.2f,rs=%.2f ", n[i], rs[j]);
		}
	}
	fprintf(output_file_g2_learn, "\n");
	fprintf(output_file_g3_learn, "#");
	for (int i = 0; i < 6; i++) {
		for (int j = 0; j < 4; j++) {
			for (int k = 0; k < 2; k++) {
				fprintf(output_file_g3_learn, "n=%.2f,s=%d,l=%2.f ", n[i], s[j], l[k]);
			}
		}
	}
	fprintf(output_file_g3_learn, "\n"); // Add end of line
  
	// Open energy output learn file in write mode
	FILE *output_file_energy_learn = fopen(output_filename_energy_learn, "w");
	if (output_file_energy_learn == NULL) {
		print_opening_file_error_and_exit();
	}

	bool file_end = false; // End line control
	int local_learn_timesteps = 0; // Local timesteps counter

	// While file is not ended and local timestep is less or equal than global learn timesteps
	while (!file_end && local_learn_timesteps < total_learn_timesteps) {
		// Read line (energy line) and control end line case (EOF)
		if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char), learning_file) == NULL) {
			file_end = true;
		} else {
			float energy_temp = atof(tmpBuffer);
			energy_average += energy_temp; // Energy average accumulator
			// Control energy maximum and minimum value
			if (energy_temp > global_energy_max)
				global_energy_max = energy_temp;
			if (energy_temp < global_energy_min)
				global_energy_min = energy_temp;
			// Write box energy to output learn file
			fprintf(output_file_energy_learn, "%s", tmpBuffer);
			fflush(output_file_energy_learn); // Flush file buffer
			local_learn_timesteps++; // Update timestep local counter
		}
		// Read line (box length) and control end line case (EOF)
		if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char), learning_file) == NULL) {
			file_end = true;
		} else {
			int n = 0; // Token counter
			char *token; // Token value
			token = strtok(tmpBuffer, DELIM); // Chopped line in tokens
			while (token) {
				if (n == 0) // First token is x length
					box_of_atoms.long_x = atof(token);
				if (n == 1) // Second token is y length
					box_of_atoms.long_y = atof(token);
				if (n == 2) // Third token is z length
					box_of_atoms.long_z = atof(token);
				n++; // Update token counter
				token = strtok('\0', DELIM);
			}
		}
		for (int i = 0; i < box_of_atoms.number_of_atoms && !file_end; i++) { // Go over all atoms in the box
			// Read line (atom coordinates) and control end line case (EOF)
			if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char),
					  learning_file) == NULL) {
				file_end = true;
			} else {
				int n = 0;
				char *token;
				token = strtok(tmpBuffer, DELIM); // Chopped line in tokens
				while (token) {
					if (n == 0)	// First token is atom's x coordinate
						box_of_atoms.atoms[i].c_x = atof(token);
					if (n == 1) // Second token is atom's y coordinate
						box_of_atoms.atoms[i].c_y = atof(token);
					if (n == 2)	// Third token is atom's z coordinate
						box_of_atoms.atoms[i].c_z = atof(token);
					n++;
					token = strtok('\0', DELIM);
				}
			}
			// Read line (atom forces) and control end line case (EOF)
			if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char),
					  learning_file) == NULL) {
				file_end = true;
			} else {
				int n = 0;
				char *token;
				token = strtok(tmpBuffer, DELIM); // Chopped line in tokens
				while (token) {
					if (n == 0)	// First token is atom's x force
						box_of_atoms.atoms[i].f_x = atof(token);
					if (n == 1) // Second token is atom's y force
						box_of_atoms.atoms[i].f_y = atof(token);
					if (n == 2) // Third token is atom's z force
						box_of_atoms.atoms[i].f_z = atof(token);
					n++;
					token = strtok('\0', DELIM);
				}
			}
		}

		if(!file_end){
			/*
			  calculate symmetry functions for this box of atoms with both G2's and g3's variables combinations
			  !!!! GPU version !!!! 
			*/
			calculate_symmetry_functions(&box_of_atoms, g2_combination, g3_combination);

			// Write G2 symmetry functions in G2 output learn file
			for (int i = 0; i < box_of_atoms.number_of_atoms; i++) {
				for (int j = 0; j < G2_SIZE; j++) {
					// Maximum and minimum control for further normalization
					if (box_of_atoms.atoms[i].g2_symmetry[j] < g2_sf_min[j])
						g2_sf_min[j] = box_of_atoms.atoms[i].g2_symmetry[j];
					if (box_of_atoms.atoms[i].g2_symmetry[j] > g2_sf_max[j])
						g2_sf_max[j] = box_of_atoms.atoms[i].g2_symmetry[j];
					// G2 SF accumulator for further feature selection
					g2_sf_accumulator[j] += box_of_atoms.atoms[i].g2_symmetry[j] * box_of_atoms.atoms[i].g2_symmetry[j];
					// Write G2 SF to output learn G2 file
					fprintf(output_file_g2_learn, "%.10e ",	box_of_atoms.atoms[i].g2_symmetry[j]);
				}
				fprintf(output_file_g2_learn, "\n");
			}

			// write g3 symmetry functions in g3 output file
			for (int i = 0; i < box_of_atoms.number_of_atoms; i++) {
				for (int j = 0; j < G3_SIZE; j++) {
					// maximum and minimum control for further normalization
					if (box_of_atoms.atoms[i].g3_symmetry[j] < g3_sf_min[j])
						g3_sf_min[j] = box_of_atoms.atoms[i].g3_symmetry[j];
					if (box_of_atoms.atoms[i].g3_symmetry[j] > g3_sf_max[j])
						g3_sf_max[j] = box_of_atoms.atoms[i].g3_symmetry[j];
					// G2 SF accumulator for further feature selection
					g3_sf_accumulator[j] += box_of_atoms.atoms[i].g3_symmetry[j] * box_of_atoms.atoms[i].g3_symmetry[j];
					// Write G3 SF to output learn G3 file
					fprintf(output_file_g3_learn, "%.10e ",	box_of_atoms.atoms[i].g3_symmetry[j]);
				}
				fprintf(output_file_g3_learn, "\n");
			}
		}
		// Reading control file *** REMOVE ***
		//if (local_learn_timesteps == 100)
		// file_end = true;
		// Reading control file *** REMOVE ***
	}

	// BEGIN ->> generate graph file with relations between g symmetry functions and forces
	// COMMENT IF DON'T NEED THIS GRAPH
	/*FILE *g_final_output = fopen("data/G_FORCE_RELATION_GRAPH.dat", "w");
	  if (g_final_output == NULL) {
	  print_opening_file_error_and_exit();
	  }
	  for (int i = 0; i < box_of_atoms.number_of_atoms - 1; i++) {
	  for (int j = i + 1; j < box_of_atoms.number_of_atoms; j++) {
	  float force_distance = sqrtf(
	  (box_of_atoms.atoms[i].f_x - box_of_atoms.atoms[j].f_x)
	  * (box_of_atoms.atoms[i].f_x
	  - box_of_atoms.atoms[j].f_x)
	  + (box_of_atoms.atoms[i].f_y
	  - box_of_atoms.atoms[j].f_y)
	  * (box_of_atoms.atoms[i].f_y
	  - box_of_atoms.atoms[j].f_y)
	  + (box_of_atoms.atoms[i].f_z
	  - box_of_atoms.atoms[j].f_z)
	  * (box_of_atoms.atoms[i].f_z
	  - box_of_atoms.atoms[j].f_z));
	  float g_symmetry_distance = 0;
	  for (int k = 0; k < G2_SIZE; k++) {
	  if (g2_sf_valid[k] == true) {
	  g_symmetry_distance += (box_of_atoms.atoms[i].g2_symmetry[k]
	  - box_of_atoms.atoms[j].g2_symmetry[k])
	  * (box_of_atoms.atoms[i].g2_symmetry[k]
	  - box_of_atoms.atoms[j].g2_symmetry[k]);
	  }
	  }
	  for (int k = 0; k < G3_SIZE; k++) {
	  if (g3_sf_valid[k] == true) {
	  g_symmetry_distance += (box_of_atoms.atoms[i].g3_symmetry[k]
	  - box_of_atoms.atoms[j].g3_symmetry[k])
	  * (box_of_atoms.atoms[i].g3_symmetry[k]
	  - box_of_atoms.atoms[j].g3_symmetry[k]);
	  }
	  }
	  g_symmetry_distance = sqrtf(g_symmetry_distance);
	  fprintf(g_final_output, "%.10e %.10e\n", g_symmetry_distance,
	  force_distance);
	  }
	  }
	  fclose(g_final_output);
	  printf("\n\nGraph file G_FORCES relationship \"%s\" generated\n",
	  "data/G_FORCE_RELATION_GRAPH.dat");*/
	// END ->> generate graph file with relations between g symmetry functions and forces
	// COMMENT IF DON'T NEED THIS GRAPH

	// closing learning files files
	fclose(learning_file);
	fclose(output_file_g2_learn);
	fclose(output_file_g3_learn);
	fclose(output_file_energy_learn);

	// Open predict file to load boxes in read mode
	FILE *predict_file = fopen(predict_filename, "r");
	if (predict_file == NULL) {
		print_opening_file_error_and_exit();
	}
	// Open G2 symmetry output predict file in write mode
	FILE *output_file_g2_predict = fopen(output_filename_g2_predict, "w");
	if (output_file_g2_predict == NULL) {
		print_opening_file_error_and_exit();
	}
	// Open G3 symmetry output predict file in write mode
	FILE *output_file_g3_predict = fopen(output_filename_g3_predict, "w");
	if (output_file_g3_predict == NULL) {
		print_opening_file_error_and_exit();
	}
	// Write G2 and G3 file headers
	fprintf(output_file_g2_predict, "#");
	for (int i = 0; i < 6; i++) {
		for (int j = 0; j < 6; j++) {
			fprintf(output_file_g2_predict, "n=%.2f,rs=%.2f ", n[i], rs[j]);
		}
	}
	fprintf(output_file_g2_predict, "\n");
	fprintf(output_file_g3_predict, "#");
	for (int i = 0; i < 6; i++) {
		for (int j = 0; j < 4; j++) {
			for (int k = 0; k < 2; k++) {
				fprintf(output_file_g3_predict, "n=%.2f,s=%d,l=%2.f ", n[i], s[j], l[k]);
			}
		}
	}
	fprintf(output_file_g3_predict, "\n");
  
	// Open energy output predict file in write mode
	FILE *output_file_energy_predict = fopen(output_filename_energy_predict, "w");
	if (output_file_energy_predict == NULL) {
		print_opening_file_error_and_exit();
	}

	file_end = false; // End line control
	int local_predict_timesteps = 0; // Local predict timesteps counter

	// While file is not ended and local timestep is less or equal than global predict timesteps
	while (!file_end && local_predict_timesteps < total_predict_timesteps) {
		// Read line (energy line) and control end line case (EOF)
		if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char), predict_file) == NULL) {
			file_end = true;
		} else {
			// Write box energy to output predict file
			fprintf(output_file_energy_predict, "%s", tmpBuffer);
			fflush(output_file_energy_predict); // Flush file buffer
			local_predict_timesteps++; // Update timestep local counter
		}
		// Read line (box length) and control end line case (EOF)
		if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char), predict_file) == NULL) {
			file_end = true;
		} else {
			int n = 0; // Token counter
			char *token; // Token value
			token = strtok(tmpBuffer, DELIM); // Chopped line in tokens
			while (token) {
				if (n == 0) // First token is x length
					box_of_atoms.long_x = atof(token);
				if (n == 1) // Second token is y length
					box_of_atoms.long_y = atof(token);
				if (n == 2) // Third token is z length
					box_of_atoms.long_z = atof(token);
				n++; // Update token counter
				token = strtok('\0', DELIM);
			}
		}
		for (int i = 0; i < box_of_atoms.number_of_atoms && !file_end; i++) { // Go over all atoms in the box
			// Read line (atom coordinates) and control end line case (EOF)
			if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char),
					  predict_file) == NULL) {
				file_end = true;
			} else {
				int n = 0;
				char *token;
				token = strtok(tmpBuffer, DELIM); // Chopped line in tokens
				while (token) {
					if (n == 0)	// First token is atom's x coordinate
						box_of_atoms.atoms[i].c_x = atof(token);
					if (n == 1) // Second token is atom's y coordinate
						box_of_atoms.atoms[i].c_y = atof(token);
					if (n == 2)	// Third token is atom's z coordinate
						box_of_atoms.atoms[i].c_z = atof(token);
					n++;
					token = strtok('\0', DELIM);
				}
			}
			// Read line (atom forces) and control end line case (EOF)
			if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char),
					  predict_file) == NULL) {
				file_end = true;
			} else {
				int n = 0;
				char *token;
				token = strtok(tmpBuffer, DELIM); // Chopped line in tokens
				while (token) {
					if (n == 0)	// First token is atom's x force
						box_of_atoms.atoms[i].f_x = atof(token);
					if (n == 1) // Second token is atom's y force
						box_of_atoms.atoms[i].f_y = atof(token);
					if (n == 2) // Third token is atom's z force
						box_of_atoms.atoms[i].f_z = atof(token);
					n++;
					token = strtok('\0', DELIM);
				}
			}
		}

		if (!file_end) {
			/*
			  calculate symmetry functions for this box of atoms with both G2's and g3's variables combinations
			  !!!! GPU version !!!! 
			*/
			calculate_symmetry_functions(&box_of_atoms, g2_combination, g3_combination);
      
			// write g2 symmetry functions in g2 output predict file
			for (int i = 0; i < box_of_atoms.number_of_atoms; i++) {
				for (int j = 0; j < G2_SIZE; j++) {
					// maximum and minimum control for further normalization
					if (box_of_atoms.atoms[i].g2_symmetry[j] < g2_sf_min[j])
						g2_sf_min[j] = box_of_atoms.atoms[i].g2_symmetry[j];
					if (box_of_atoms.atoms[i].g2_symmetry[j] > g2_sf_max[j])
						g2_sf_max[j] = box_of_atoms.atoms[i].g2_symmetry[j];
					// G2 SF accumulator for further feature selection
					g2_sf_accumulator[j] += box_of_atoms.atoms[i].g2_symmetry[j] * box_of_atoms.atoms[i].g2_symmetry[j];
					// Write G2 SF to output learn G2 file
					fprintf(output_file_g2_predict, "%.10e ",	box_of_atoms.atoms[i].g2_symmetry[j]);
				}
				fprintf(output_file_g2_predict, "\n");
			}

			// write g3 symmetry functions in g3 output file
			for (int i = 0; i < box_of_atoms.number_of_atoms; i++) {
				for (int j = 0; j < G3_SIZE; j++) {
					// maximum and minimum control for further normalization
					if (box_of_atoms.atoms[i].g3_symmetry[j] < g3_sf_min[j])
						g3_sf_min[j] = box_of_atoms.atoms[i].g3_symmetry[j];
					if (box_of_atoms.atoms[i].g3_symmetry[j] > g3_sf_max[j])
						g3_sf_max[j] = box_of_atoms.atoms[i].g3_symmetry[j];
					// G3 SF accumulator for further feature selection
					g3_sf_accumulator[j] += box_of_atoms.atoms[i].g3_symmetry[j] * box_of_atoms.atoms[i].g3_symmetry[j];
					// Write G3 SF to output learn G3 file
					fprintf(output_file_g3_predict, "%.10e ",	box_of_atoms.atoms[i].g3_symmetry[j]);
				}
				fprintf(output_file_g3_predict, "\n");
			}
		}
		// Reading control file *** REMOVE ***
		//if (local_predict_timesteps == 100)
		//file_end = true;
		// Reading control file *** REMOVE ***
	}

	// closing predict files
	fclose(predict_file);
	fclose(output_file_g2_predict);
	fclose(output_file_g3_predict);
	fclose(output_file_energy_predict);

	/*
	 * Reducing data dimension (feature selection)
	 */
	float treshold = 1.0E-8; // Vector's modulus threshold

	for (int i = 0; i < G2_SIZE; i++) {
		if (i < 5) { // G2 symmetry functions with n=0 have the same value, remove first forth
			g2_sf_valid[i] = 0;
		} else {    
			g2_sf_accumulator[i] = sqrtf(g2_sf_accumulator[i]); // Modulus acumulator vector
			if (g2_sf_accumulator[i] < treshold) { // If modulus is less than treshold
				g2_sf_valid[i] = 0; // This G2 SF is not valid
			}
		}
	}
	// The same feature selection for G3 SF
	for (int i = 0; i < G3_SIZE; i++) {
		g3_sf_accumulator[i] = sqrtf(g3_sf_accumulator[i]);
		if (g3_sf_accumulator[i] < treshold) {
			g3_sf_valid[i] = 0;
		}
	}

	// Releasing memory
	free(box_of_atoms.atoms);
	free(g2_combination);
	free(g3_combination);
	free(tmpBuffer);

	// Open miscelanea data file (in write mode) to write global values for further normalization and averages
	FILE *misc_data_file = fopen(output_filename_misc_data, "w");
	if (misc_data_file == NULL) {
		print_opening_file_error_and_exit();
	}

	// Write energy average value to miscelanea output file
	fprintf(misc_data_file, "%.10e\n", energy_average / local_learn_timesteps);
	// Write energy maximum and minimum values to miscelanea output file
	fprintf(misc_data_file, "%.10e %.10e\n", global_energy_min, global_energy_max);
	// Write number of atoms per box and both total learn and predict timesteps (boxes) to miscelanea output file
	fprintf(misc_data_file, "%d\n", total_learn_timesteps);
	fprintf(misc_data_file, "%d\n", total_predict_timesteps);
	fprintf(misc_data_file, "%d\n", number_of_atoms_per_box);
	// Close miscelanea output file
	fclose(misc_data_file);

	//print information about timesteps (boxes) processed
	printf("\nLearn symmetry functions sets (boxes) generated: %d\n", local_learn_timesteps);
	printf("Predict symmetry functions sets (boxes) generated: %d\n", local_predict_timesteps);
}
