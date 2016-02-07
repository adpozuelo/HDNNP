/*
  UOC_TFG - Antonio Díaz Pozuelo - adpozuelo@uoc.edu
  Application main file
  High-Dimensional Neural Network Potentials (HDNNP)
	Testing Git Branch
*/

#include <stdio.h>
#include <string.h>
#include "misc.h"
#include "process_input_files.h"
#include "load_boxes.h"
#include "nn_preconditioning.h"
#include "nn_start.h"
#include "conf.h"
#include "messages.h"
#include "final_results.h"

int main(int argc, char *argv[]) {

	if (argc < 2) { // Not allowed less than two arguments (learning and predict temperatures)
		print_help_and_exit();
	} else {

		int number_learning_temperatures; // Global learning temperatures counter
		int number_predict_temperatures; // Global learning temperatures counter

		/*
		  Application input arguments control function
		*/
		application_input_control(argc, argv, &number_learning_temperatures, &number_predict_temperatures);

		/*
		  Learning and predict filenames
		*/
		char *learning_history_files[number_learning_temperatures];
		char *learning_energy_files[number_learning_temperatures];
		char *predict_history_files[number_predict_temperatures];
		char *predict_energy_files[number_predict_temperatures];

		/*
		  Generate filenames respect arguments function
		*/
		generate_filenames(argc, argv, learning_history_files, learning_energy_files, predict_history_files, predict_energy_files);

		/*
		  Information about files to process
		*/
		printf("\nNumber of learning history / energy files: %d\n", number_learning_temperatures);
		printf("Number of predict history / energy files: %d\n", number_predict_temperatures);
		printf("\nLearn filenames:\n");
		for (int i = 0; i < number_learning_temperatures; i++)
			printf("%s -> %s\n", learning_history_files[i],
				   learning_energy_files[i]);
		printf("\nPredict filenames:\n");
		for (int i = 0; i < number_predict_temperatures; i++)
			printf("%s -> %s\n", predict_history_files[i],
				   predict_energy_files[i]);

		/*
		  Global counters
		*/
		int number_of_atoms_per_box = 0; // Global number of atoms per box counter
		int total_learn_timesteps = 0; // Global number of learn timesteps
		int total_predict_timesteps = 0; // Global number of predict timesteps

		/*
		  Process input files (ab-initio) to calculate global counters and generate interleaved boxes file to learn and boxes file to predict
		*/
		process_input_files(number_learning_temperatures, learning_history_files, learning_energy_files, number_predict_temperatures, predict_history_files, predict_energy_files, &number_of_atoms_per_box, &total_learn_timesteps, &total_predict_timesteps, OUTPUT_FILENAME_LEARN, OUTPUT_FILENAME_PREDICT);

		/*
		  Information about global counters
		*/
		printf("\nTotal learn timesteps: %d\n", total_learn_timesteps);
		printf("Total predict timesteps: %d\n", total_predict_timesteps);
		printf("\nNumber of atoms per box: %d\n", number_of_atoms_per_box);

		/*
		  Feature selection and normalize vectors for G2 and G3 symmetry functions (SF)
		*/
		int g2_sf_valid[G2_SIZE]; // Valid G2 SF (1==true, 0==false)
		float g2_sf_min[G2_SIZE]; // G2 SF minimum values
		float g2_sf_max[G2_SIZE]; // G2 SF maximum values
		for (int i=0; i<G2_SIZE; i++){ // Initialize data
			g2_sf_min[i]=10E6;
			g2_sf_max[i]=-1;
			g2_sf_valid[i] = 1;
		}
		int g3_sf_valid[G3_SIZE]; // Valid G2 SF (1==true, 0==false)
		float g3_sf_min[G3_SIZE]; // G3 SF minimun values
		float g3_sf_max[G3_SIZE]; // G3 SF minimum values
		for (int i=0; i<G3_SIZE; i++){ // Initialize data
			g3_sf_min[i]=10E6;
			g3_sf_max[i]=-1;
			g3_sf_valid[i] = 1;
		}

		/*
		  Generate symmetry functions atom's representation values for learn and predict boxes
		*/
		load_boxes_and_generate_symmetry_functions(OUTPUT_FILENAME_LEARN, OUTPUT_FILENAME_PREDICT, number_of_atoms_per_box, total_learn_timesteps, total_predict_timesteps, OUTPUT_FILENAME_G2_LEARN, OUTPUT_FILENAME_G3_LEARN, OUTPUT_FILENAME_MISC_DATA, OUTPUT_FILENAME_ENERGY_LEARN, OUTPUT_FILENAME_G2_PREDICT, OUTPUT_FILENAME_G3_PREDICT, OUTPUT_FILENAME_ENERGY_PREDICT, g2_sf_valid, g2_sf_min, g2_sf_max, g3_sf_valid, g3_sf_min, g3_sf_max);

		/*
		  Preconditioning (feature selection and normalized) learn and predict atom's representation values
		*/
		nn_preconditioning(OUTPUT_FILENAME_G2_LEARN, OUTPUT_FILENAME_G3_LEARN, OUTPUT_FILENAME_G_NORMALIZED_LEARN, g2_sf_valid, g2_sf_min, g2_sf_max, g3_sf_valid, g3_sf_min, g3_sf_max, number_of_atoms_per_box, total_learn_timesteps, total_predict_timesteps, OUTPUT_FILENAME_G2_PREDICT, OUTPUT_FILENAME_G3_PREDICT, OUTPUT_FILENAME_G_NORMALIZED_PREDICT);

		/*
		  Neural network start to learn
		*/
		nn_start(OUTPUT_FILENAME_G_NORMALIZED_LEARN, OUTPUT_FILENAME_ENERGY_LEARN, OUTPUT_FILENAME_MISC_DATA, OUTPUT_FILENAME_LEARNING_PROCESS, OUTPUT_FILENAME_G_NORMALIZED_PREDICT, OUTPUT_FILENAME_PREDICT_FINAL);

		/*
		  Print application final results
		 */
		final_results(OUTPUT_FILENAME_ENERGY_PREDICT, OUTPUT_FILENAME_PREDICT_FINAL);
	}
	printf("\n");
	return 0;
}
