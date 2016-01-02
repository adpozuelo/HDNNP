/*
  UOC_TFG - Antonio Díaz Pozuelo - adpozuelo@uoc.edu
  Symmetry functions file
  Symmetry functions to generate atom's cutoff representation
  Header is specify in symmetry_functions.h
  High-Dimensional Neural Network Potentials (HDNNP)
*/

#include <math.h>
#include <stdio.h>
#include "structs.h"
#include "messages.h"

// GPU function to calculate distance between two atoms into a periodic box
__device__ float atoms_distance_periodic(float c_x_atom1, float c_y_atom1, float c_z_atom1, float c_x_atom2, float c_y_atom2, float c_z_atom2, float long_x, float long_y, float long_z) {

	// Atoms distances calculus
	float diff_x = c_x_atom1 - c_x_atom2;
	float diff_y = c_y_atom1 - c_y_atom2;
	float diff_z = c_z_atom1 - c_z_atom2;
	// Box periodic conditions
	if (diff_x >= 0.5 * long_x)
		diff_x -= long_x;
	else if (diff_x < -0.5 * long_x)
		diff_x += long_x;
	if (diff_y >= 0.5 * long_y)
		diff_y -= long_y;
	else if (diff_y < -0.5 * long_y)
		diff_y += long_y;
	if (diff_z >= 0.5 * long_z)
		diff_z -= long_z;
	else if (diff_z < -0.5 * long_z)
		diff_z += long_z;
	// Return distance between two atoms
	return (float) (diff_x * diff_x) + (diff_y * diff_y) + (diff_z * diff_z);
}

// FC symmetry function
__device__ float fc_symmetry(float r_ij) {
	float rc = 36;
	float result = 0;
	if (r_ij <= rc)
		result = (float) 0.5 * (__cosf((M_PI * r_ij) / rc) + 1);
	return result;
}

// G2 symmetry function
__device__ float g2_symmetry(float n, float r_s, float r_ij) {
	float result = 0;
	result = (float) __expf(-n * ((r_ij - r_s) * (r_ij - r_s))) * fc_symmetry(r_ij);
	return result;
}

// G3 symmetry function
__device__ float g3_symmetry(float n, int s, float l, float r_ij, float r_ik, float r_jk) {
	float result = 0;
	float sqrt_r_ij = __fsqrt_rd(r_ij);
	float sqrt_r_ik = __fsqrt_rd(r_ik);
	float sqrt_r_jk = __fsqrt_rd(r_jk);
	float cos_ijk = (float) ((sqrt_r_ij * sqrt_r_ij) + (sqrt_r_ik * sqrt_r_ik) - (sqrt_r_jk * sqrt_r_jk)) / (2 * sqrt_r_ij * sqrt_r_ik);
	if (cos_ijk < -1.0)
		cos_ijk = -1.0;
	if (cos_ijk > 1.0)
		cos_ijk = 1.0;
	result = (float) __powf((1 + (l * cos_ijk)), s);
	result *= (float) __expf((-n) * ((sqrt_r_ij * sqrt_r_ij) + (sqrt_r_ik * sqrt_r_ik) + (sqrt_r_jk * sqrt_r_jk)));
	result *= (float) fc_symmetry(r_ij) * fc_symmetry(r_ik) * fc_symmetry(r_jk);
	return result;
}

__global__ void kernel_symmetry_functions(G2Combination *dev_g2_combination, G3Combination *dev_g3_combination, Atom *dev_atoms, int *dev_number_of_atoms, float *dev_long_x, float *dev_long_y, float *dev_long_z) {

	int tid = blockIdx.x; // First atom
	int tjd = threadIdx.x; // Second atom
	__shared__ float accumulator; // Accumulator register
	float rc = 36; // Cutoff radius (6A ^ 2)

	for (int i = 0; i < G2_SIZE; i++) { // Go over G2 SF combinations
		float n = dev_g2_combination[i].n;
		float rs = dev_g2_combination[i].rs;
		if (tjd == 0) // Initialize accumulator
			accumulator = 0;
		__syncthreads(); // Threads syncronization
		if (tid != tjd) { // If atoms are different (atom1 and atom2)
			// Calculate distance between atoms (atom1 and atom2)
			float r_ij = atoms_distance_periodic(dev_atoms[tid].c_x, dev_atoms[tid].c_y, dev_atoms[tid].c_z, dev_atoms[tjd].c_x, dev_atoms[tjd].c_y, dev_atoms[tjd].c_z, *dev_long_x, *dev_long_y, *dev_long_z);
			if (r_ij <= rc) { // If atoms are into cutoff
				// Add g2 symmetry function value to accumulator
				atomicAdd(&accumulator, g2_symmetry(n, rs, r_ij));
			}
			__syncthreads();
		}
		// Store G2 accumulator to G2 SF value in atom1 structure
		dev_atoms[tid].g2_symmetry[i] = accumulator;
	}

	for (int i = 0; i < G3_SIZE; i++) { // Go over G3 SF combinations
		float n = dev_g3_combination[i].n;
		int s = dev_g3_combination[i].s;
		float l = dev_g3_combination[i].l;
		if (tjd == 0) // Initialize accumulator
			accumulator = 0;
		__syncthreads();
		if (tid != tjd) { // If atoms are different (atom1 and atom2)
			// Calculate distance between atoms (atom1 and atom2)
			float r_ij = atoms_distance_periodic(dev_atoms[tid].c_x, dev_atoms[tid].c_y, dev_atoms[tid].c_z, dev_atoms[tjd].c_x, dev_atoms[tjd].c_y, dev_atoms[tjd].c_z, *dev_long_x, *dev_long_y, *dev_long_z);
			if (r_ij <= rc) { // If atoms are into cutoff
				for (int k = 0; k < *dev_number_of_atoms; k++) { // Go over all atoms
					if (k != tjd && k != tid) { // If atom3 is different of atom1 and atom2
						// Calculate distance between atoms (atom1 and atom3)
						float r_ik = atoms_distance_periodic(dev_atoms[tid].c_x, dev_atoms[tid].c_y, dev_atoms[tid].c_z, dev_atoms[k].c_x, dev_atoms[k].c_y, dev_atoms[k].c_z, *dev_long_x, *dev_long_y, *dev_long_z);
						if (r_ik <= rc) { // If atoms are into cutoff
							// Calculate distance between atoms (atom2 and atom3)
							float r_jk = atoms_distance_periodic(dev_atoms[tjd].c_x, dev_atoms[tjd].c_y, dev_atoms[tjd].c_z, dev_atoms[k].c_x, dev_atoms[k].c_y, dev_atoms[k].c_z, *dev_long_x, *dev_long_y, *dev_long_z);
							// Add G3 SF value to accumulator
							atomicAdd(&accumulator, g3_symmetry(n, s, l, r_ij, r_ik, r_jk));
						}
						__syncthreads();
					}
				}
			}
		}
		// Store g3 accumulator to g3 symmetry value in atom1 structure
		dev_atoms[tid].g3_symmetry[i] = __powf(2, 1 - s) * accumulator;
	}
}

void calculate_symmetry_functions(Box *box_of_atoms, G2Combination *g2_combination, G3Combination *g3_combination) {

	// Device (GPU) G2 SF combination variables
	G2Combination *dev_g2_combination; // GPU pointer
	cudaMalloc((void**) &dev_g2_combination, sizeof(G2Combination) * G2_SIZE); // GPU memory allocation
	cudaMemcpy(dev_g2_combination, g2_combination, sizeof(G2Combination) * G2_SIZE, cudaMemcpyHostToDevice); // CPU to GPU memory copy

	// Device (GPU) G3 SF combination variables
	G3Combination *dev_g3_combination;
	cudaMalloc((void**) &dev_g3_combination, sizeof(G3Combination) * G3_SIZE);
	cudaMemcpy(dev_g3_combination, g3_combination, sizeof(G3Combination) * G3_SIZE, cudaMemcpyHostToDevice);

	// Device (GPU) box atoms
	Atom *dev_atoms;
	cudaMalloc((void**) &dev_atoms, sizeof(Atom) * box_of_atoms->number_of_atoms);
	cudaMemcpy(dev_atoms, box_of_atoms->atoms, sizeof(Atom) * box_of_atoms->number_of_atoms, cudaMemcpyHostToDevice);

	// Device (GPU) number of atoms in the box
	int *dev_number_of_atoms;
	cudaMalloc((void**) &dev_number_of_atoms, sizeof(int));
	cudaMemcpy(dev_number_of_atoms, &box_of_atoms->number_of_atoms, sizeof(int), cudaMemcpyHostToDevice);

	// Device (GPU) length of the box
	float *dev_long_x, *dev_long_y, *dev_long_z;
	cudaMalloc((void**) &dev_long_x, sizeof(float));
	cudaMalloc((void**) &dev_long_y, sizeof(float));
	cudaMalloc((void**) &dev_long_z, sizeof(float));
	cudaMemcpy(dev_long_x, &box_of_atoms->long_x, sizeof(float), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_long_y, &box_of_atoms->long_y, sizeof(float), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_long_z, &box_of_atoms->long_z, sizeof(float), cudaMemcpyHostToDevice);

	// Kernel call (GPU kernel)
	kernel_symmetry_functions<<<box_of_atoms->number_of_atoms, box_of_atoms->number_of_atoms>>>(dev_g2_combination, dev_g3_combination, dev_atoms, dev_number_of_atoms, dev_long_x, dev_long_y, dev_long_z);

	/*
	 * Copy from GPU to CPU memory all atoms of the box with both G2 and G3 SF calculated
	 */
	cudaMemcpy(box_of_atoms->atoms, dev_atoms, sizeof(Atom) * box_of_atoms->number_of_atoms, cudaMemcpyDeviceToHost);

	// Release GPU memory
	cudaFree(dev_g2_combination);
	cudaFree(dev_g3_combination);
	cudaFree(dev_atoms);
	cudaFree(dev_number_of_atoms);
	cudaFree(dev_long_x);
	cudaFree(dev_long_y);
	cudaFree(dev_long_z);
}
