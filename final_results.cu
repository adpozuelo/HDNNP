/*
  UOC_TFG - Antonio Díaz Pozuelo - adpozuelo@uoc.edu
  Print application final results
  Header is specify in final_results.h
  High-Dimensional Neural Network Potentials (HDNNP)
*/

#include <stdio.h>
#include <stdlib.h>
#include "messages.h"
#include "conf.h"

void final_results(char *input_filename_supervised_energy_predict, char *input_filename_final_energy_predict){

	char *tmpBuffer = (char*) malloc(BUFFER_SIZE * sizeof(char)); // Allocate memory to buffer

	// Open supervised energy file
	FILE *supervised_energy_file = fopen(input_filename_supervised_energy_predict, "r");
	if (supervised_energy_file == NULL) {
		print_opening_file_error_and_exit();
	}
	// Open predicted energy file
	FILE *predicted_energy_file = fopen(input_filename_final_energy_predict, "r");
	if (predicted_energy_file == NULL) {
		print_opening_file_error_and_exit();
	}

	// Control variables and accumulators to average calculus
	bool file_end = false;
	int supervised_timesteps = 0;
	int predicted_timesteps = 0;
	float supervised_energy_accumulator = 0;
	float predicted_energy_accumulator = 0;

	// Read energies and accumulate them
	while (!file_end) {
		if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char), supervised_energy_file) == NULL) {
			file_end = true;
		} else {
			supervised_energy_accumulator += atof(tmpBuffer);
			supervised_timesteps++;
		}
		if (fgets(tmpBuffer, BUFFER_SIZE * sizeof(char), predicted_energy_file) == NULL) {
			file_end = true;
		} else {
			predicted_energy_accumulator += atof(tmpBuffer);
			predicted_timesteps++;
		}
	}

	// Close file and release memory
	fclose(supervised_energy_file);
	fclose(predicted_energy_file);
	free(tmpBuffer);

	// Average calculus
	predicted_energy_accumulator /= predicted_timesteps;
	supervised_energy_accumulator /= supervised_timesteps;

	// Print results
	printf("\nSupervised energy average = %f\n", supervised_energy_accumulator);
	printf("Predicted energy average = %f\n", predicted_energy_accumulator);
	printf("Error energy average prediction = %f\n", supervised_energy_accumulator - predicted_energy_accumulator);
	// Plotting results
	printf("\nPlotting results (GNUplot is required!)\n");
	system("gnuplot < gnuplot_plot_results.in");
	printf("LEARNING_PROCESS.png and FINAL_PREDICTION.png files created!\n");
}
