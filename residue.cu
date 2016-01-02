/*
  UOC_TFG - Antonio Díaz Pozuelo - adpozuelo@uoc.edu
  Neural network epochs functions file
  Execute neural network epochs
  Header is specify in residue.h
  High-Dimensional Neural Network Potentials (HDNNP)
*/

#include <stdio.h>
#include <math.h>
#include "conf.h"

// GPU function to calculate sigmoid (neural stimulation)
__device__ float sigmoid(float value) {
	return (float) 1 / (1 + __expf(-value));
}

// GPU function to execute neural network epoch
__global__ void nn_epoch_gpu(float *dev_symmetry_functions, float *dev_energies_fit, float *dev_parameters, const int symmetry_functions_number, const int input_layer_size, const int parameters_number, const int atoms_number) { 

	int tid = blockIdx.x; // Block of atoms (every box is a box of atoms)
	int tjd = threadIdx.x; // Atom inside box of atoms (every thread is a atom)
	/*
	  Each atoms is a neural network itself.
	  Finally, all atoms (NNs) adds their output neurons (atomic energies) to get total energy
	*/

	__shared__ float atomic_energies[MAX_ATOMS_NUMBER]; // Atomic energies of the box
 
	float input_layer[G_TOTAL_SIZE]; // Atomic neural network input layer
	// Deserialize symmetry functions data vector to get atom input layer
	for (int i=0; i < input_layer_size; i++)
		input_layer[i] = dev_symmetry_functions[(tid * atoms_number * input_layer_size) + (tjd * input_layer_size) + i];

	// BIAS parameters start
	int bias_start = parameters_number - 1 - (2 * HIDDEN_LAYER_SIZE);

	// First neural network hidden layer
	float hidden_layer_one[HIDDEN_LAYER_SIZE];
	// Initialize it to zero
	for (int i = 0; i < HIDDEN_LAYER_SIZE; i++)
		hidden_layer_one[i] = 0;
	// Calculus to stimulated neurons values for first hidden layer
	for (int i = 0; i < HIDDEN_LAYER_SIZE; i++){
		for (int j = 0; j < input_layer_size; j++){
			// Summation input layer values plus parameters
			hidden_layer_one[i] += input_layer[j] * dev_parameters[(i * input_layer_size) + j];
		}
		hidden_layer_one[i] += dev_parameters[bias_start + i]; // Add BIAS parameter
		hidden_layer_one[i] = sigmoid(hidden_layer_one[i]); // Simulate neuron
	}

	// Second hidden layer parameters start
	int second_hidden_layer_parameters_start = input_layer_size * HIDDEN_LAYER_SIZE;
	// Second neural network hidden layer
	float hidden_layer_two[HIDDEN_LAYER_SIZE];
	// Initialize it to zero
	for (int i = 0; i < HIDDEN_LAYER_SIZE; i++)
		hidden_layer_two[i] = 0;
	// Calculus to stimulated neurons values for second hidden layer
	for (int i = 0; i < HIDDEN_LAYER_SIZE; i++){
		for (int j = 0; j < HIDDEN_LAYER_SIZE; j++){
			// Summation first hidden layer neurons values plus parameters
			hidden_layer_two[i] += hidden_layer_one[j] * dev_parameters[second_hidden_layer_parameters_start + (i * HIDDEN_LAYER_SIZE) + j];
		}
		hidden_layer_two[i] += dev_parameters[bias_start + HIDDEN_LAYER_SIZE + i]; // Add BIAS parameter
		hidden_layer_two[i] = sigmoid(hidden_layer_two[i]); // Stimulate neuron
	}

	// Output neuron parameters start
	int output_neuron_parameters_start = second_hidden_layer_parameters_start + (HIDDEN_LAYER_SIZE * HIDDEN_LAYER_SIZE);
	// Initilize output neuron to zero
	float output_neuron = 0;
	// Calculus to stimulated neurons values for output neuron
	for (int i = 0; i < HIDDEN_LAYER_SIZE; i++) {
		// Summation second hidden layer neurons values plus parameters
		output_neuron += hidden_layer_two[i] * dev_parameters[output_neuron_parameters_start + i];
	}
	output_neuron += dev_parameters[parameters_number - 1]; // Add BIAS parameter

	// Each neural network (atoms) assign output neuron value (atomic energy) to box atomic energies
	atomic_energies[tjd] = output_neuron;
	__syncthreads(); // Threads syncronization

	// Use a binary reduction to sum all atomic energies
	int i = atoms_number / 2;
	while (i != 0) {
		if (tjd < i)
			atomic_energies[tjd] = atomic_energies[tjd + i] + atomic_energies[tjd];
		__syncthreads();
		i /= 2;
	}

	// Atom 0 (NN 0) assign box energy to energies fitted (predicted)
	if (tjd == 0) {
		dev_energies_fit[tid] = atomic_energies[0];
	}
}

extern "C" void residue_(int *symmetry_functions_number, float *symmetry_functions, float *energies, float *energies_fit, int *energies_number, float *parameters, int *parameters_number,int *iteration,float *residue, int *mode, int *atoms_number, int *input_layer_size){ 

	static float sum; // Temporal residue
	float sump[*energies_number]; // Cuadratic error energies per box

	// Device (GPU) variables: symmetry functions, energies fitted and parameters
	static float *dev_symmetry_functions, *dev_energies_fit, *dev_parameters;

	/*
	  In the first iteration allocating device memory (GPU)
	  Copy from CPU to GPU symmetry functions (data serialized vector)
	*/
	if (*iteration < 2) {
		cudaMalloc( (void**)&dev_symmetry_functions, *symmetry_functions_number * sizeof(float) );
		cudaMalloc( (void**)&dev_energies_fit, *energies_number * sizeof(float) );
		cudaMalloc( (void**)&dev_parameters, *parameters_number *sizeof(float) );
		cudaMemcpy( dev_symmetry_functions, symmetry_functions, *symmetry_functions_number * sizeof(float),cudaMemcpyHostToDevice );
	}

	// Copy from CPU to GPU parameters
	cudaMemcpy( dev_parameters, parameters, *parameters_number * sizeof(float),cudaMemcpyHostToDevice );

	// Kernel Call (GPU Kernel)
	nn_epoch_gpu<<<*energies_number, *atoms_number>>>(dev_symmetry_functions, dev_energies_fit, dev_parameters, *symmetry_functions_number, *input_layer_size, *parameters_number, *atoms_number);
	cudaMemcpy(energies_fit, dev_energies_fit, *energies_number *sizeof(float),cudaMemcpyDeviceToHost );

	/*
	  Neural network learning mode
	*/
	if (*mode == 1) {
		// Cuadratic error calculus for each box of atoms
		for (int i = 0; i < *energies_number; i++){
			sump[i] = (energies_fit[i] - energies[i]) * (energies_fit[i] - energies[i]);
		}
		sum = 0;
		// Sum all cuadratic errors
		for (int i = 0; i < *energies_number; i++) {
			sum += sump[i];
		}
		// Residue calculus
		sum /= *energies_number;
	} else {      
		/*
		  Neural network predict mode
		 */
		cudaFree(dev_symmetry_functions);
		cudaFree(dev_parameters);
	}
	*residue = sum; // Assign residue to input argument
}
