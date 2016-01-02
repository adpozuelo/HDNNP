/*
  UOC_TFG - Antonio Díaz Pozuelo - adpozuelo@uoc.edu
  Miscellaneous functions file
  Utility functions without specific area
  Header is specify in misc.h
  High-Dimensional Neural Network Potentials (HDNNP)
*/

#include <regex.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "misc.h"
#include "messages.h"

void application_input_control(int argc, char *argv[], int *number_learning_temperatures_final, int *number_predict_temperatures_final) {

	int number_learning_temperatures = 0; // Local learning temperatures counter
	int number_predict_temperatures = 0; // Local predict temperatures counter

	/*
	  Regular expression allowed, each argument have to:
	  1.- Start with "l" (learn) or "p" (predict)
	  2.- Continue from 1 to 4 digits from 0 to 9 values
	*/
	char pattern[18] = "^(l|p)[0-9]{1,4}$";

	for (int i = 1; i < argc; i++) { // Go over all arguments
		if (regex_match(argv[i], pattern)) { // If argument match previous regular expression
			if (strstr(argv[i], "l") != NULL) { // If string contains "l" (learn)
				number_learning_temperatures++; // Add one to learning temperatures counter
			}
			if (strstr(argv[i], "p") != NULL) { // If string contains "p" (predict)
				number_predict_temperatures++; // Add one to predict temperatures counter
			}
		} else { // Else, string doesn't contain both "l" or "p"
			print_help_and_exit(); // Print help and exit
		}
	}
	// If no learning or predict temperatures, print error message before help and exit
	if (number_learning_temperatures == 0 || number_predict_temperatures == 0) {
		print_both_learning_predict_sets_needed();
		print_help_and_exit();
	}
	// Only one preddict temperature is allowed
	if (number_predict_temperatures > 1) {
		print_only_one_predict_temperature_allowed();
		print_help_and_exit();
	}
	// Update global (passed by reference) both learning and predict temperatures counters
	*number_learning_temperatures_final = number_learning_temperatures;
	*number_predict_temperatures_final = number_predict_temperatures;
}

void generate_filenames(int argc, char *argv[], char *learning_history_files[], char *learning_energy_files[], char *predict_history_files[], char *predict_energy_files[]) {

	int tmp_l = 0; // Local learning temperatures counter
	int tmp_p = 0; // Local predict temperatures counter
	char string_history_begin[17] = "data/HISTORY.Te."; // History filename begin
	char string_energy_begin[11] = "data/E.Te."; // Energy filename begin
	char string_end[2] = "K"; // Both history and energy filenames end

	for (int i = 1; i < argc; i++) { // Go over all arguments
		/*
		  If argument contains "l" (learn) process learning case
		*/
		if (strstr(argv[i], "l") != NULL) {
			char * tmp_str_history_learn; // Local history filename (empty)
			char * tmp_str_energy_learn; // Local energy filename (empty)
			// Allocate memory to both local history and energy filenames
			if ((tmp_str_history_learn = (char*) malloc(
					 strlen(string_history_begin) + strlen(argv[i] + 1)
					 + strlen(string_end) + 1)) != NULL
				&& (tmp_str_energy_learn = (char*) malloc(
						strlen(string_energy_begin) + strlen(argv[i] + 1)
						+ strlen(string_end) + 1)) != NULL) {

				tmp_str_history_learn[0] = '\0'; // Add final string character to local history filename
				// Create history filename as history_begin + argument_temperature + history_end
				strcat(tmp_str_history_learn, string_history_begin);
				strcat(tmp_str_history_learn, argv[i] + 1);
				strcat(tmp_str_history_learn, string_end);
				// Add history filename to global array of history filenames
				learning_history_files[tmp_l] = tmp_str_history_learn;

				tmp_str_energy_learn[0] = '\0'; // Add final string character to local energy filename
				// Create history filename as energy_begin + argument_temperature + energy_end
				strcat(tmp_str_energy_learn, string_energy_begin);
				strcat(tmp_str_energy_learn, argv[i] + 1);
				strcat(tmp_str_energy_learn, string_end);
				// Add energy filename to global array of energy filenames
				learning_energy_files[tmp_l] = tmp_str_energy_learn;
				// Update local learning counter
				tmp_l++;
			} else { // Else, memory allocation fails
				print_memory_allocation_error(); // Print error and exit
			}

		}
		/*
		  If argument contains "p" (predict) process predict case
		  There are no comments because it is the same previous case with same steps
		*/
		if (strstr(argv[i], "p") != NULL) {
			char * tmp_str_history_predict;
			char * tmp_str_energy_predict;
			if ((tmp_str_history_predict = (char*) malloc(
					 strlen(string_history_begin) + strlen(argv[i] + 1)
					 + strlen(string_end) + 1)) != NULL
				&& (tmp_str_energy_predict = (char*) malloc(
						strlen(string_energy_begin) + strlen(argv[i] + 1)
						+ strlen(string_end) + 1)) != NULL) {
				tmp_str_history_predict[0] = '\0';
				strcat(tmp_str_history_predict, string_history_begin);
				strcat(tmp_str_history_predict, argv[i] + 1);
				strcat(tmp_str_history_predict, string_end);
				predict_history_files[tmp_p] = tmp_str_history_predict;

				tmp_str_energy_predict[0] = '\0';
				strcat(tmp_str_energy_predict, string_energy_begin);
				strcat(tmp_str_energy_predict, argv[i] + 1);
				strcat(tmp_str_energy_predict, string_end);
				predict_energy_files[tmp_p] = tmp_str_energy_predict;
				tmp_p++;
			} else {
				print_memory_allocation_error();
			}
		}
	}
}

int regex_match(const char *string, char *pattern) {
	int status; // Status flag
	regex_t re; // Regular expression type
	if (regcomp(&re, pattern, REG_EXTENDED) != 0) { // Compile regular expression and control return value
		print_regex_error_and_exit(); // If compilation fails print error and exit
	}
	status = regexec(&re, string, (size_t) 0, NULL, 0); // Match regular expression in pattern
	regfree(&re); // Free regular expression type
	if (status != 0) { // Regular expression doesn't match in pattern
		return (0); //  Then return 0
	}
	return (1); // Regular expression does match in pattern, then return 1
}

float normalize_float(float value_g, float min, float max) {
	// Return normalized value
	return (float) ((2 * (value_g - min)) / (max - min)) - 1;
}
