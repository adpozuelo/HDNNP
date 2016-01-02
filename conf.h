/*
  UOC_TFG - Antonio Díaz Pozuelo - adpozuelo@uoc.edu
  Global configuration header file
  High-Dimensional Neural Network Potentials (HDNNP)
*/

#ifndef CONF_H
#define CONF_H

/*
  Symmetry functions (SF)
*/
#define G2_SIZE 36 // G2 SF size
#define G3_SIZE 48 // G3 SF size
#define G_TOTAL_SIZE G2_SIZE + G3_SIZE // G total SF size (G2 + G3) 
#define G2G3SYMFILE "data/G_GRAPH.dat" // Not normalized G SF values filename (to graph only)

/*
  Neural network (NN)
*/
#define MAX_G_SIZE_TO_OPT 30 // NN maximum input layer size
#define NUMBER_OF_BOXES_TO_OPT 50 // Number of boxes to process in learning and predict mode
#define HIDDEN_LAYER_SIZE 4 // NN hidden layer number of neurons
#define MAX_ATOMS_NUMBER 64 // NN maximum number of atoms per box

/*
  Global
*/
#define BUFFER_SIZE (2<<10) // Buffer size to read file lines
#define DELIM " " // CSV delimitator
#define BOX_DIM 3 // Atom's box dimension

/*
  IMSL BCPOL (OPT)
*/
#define FTOL 0.0000005 // OPT tolerance
#define MAXFCN 80000 // OPT maximum functions to call
#define IB 0 // OPT option

/*
  Input / Output files
*/
#define OUTPUT_FILENAME_LEARN "data/LEARNING_DATA.dat" // Interleaved boxes to learn (raw data)
#define OUTPUT_FILENAME_PREDICT "data/PREDICT_DATA.dat" // Boxes to predict (raw data)
#define OUTPUT_FILENAME_G2_LEARN "data/G2_SYMMETRY_LEARN.dat" // G2 SF to learn
#define OUTPUT_FILENAME_G3_LEARN "data/G3_SYMMETRY_LEARN.dat" // G3 SF to learn
#define OUTPUT_FILENAME_MISC_DATA "data/MISC_DATA.dat" // Miscelanea data file (application modules comunication)
#define OUTPUT_FILENAME_ENERGY_LEARN "data/ENERGY_LEARN.dat" // Supervised learn energy
#define OUTPUT_FILENAME_G2_PREDICT "data/G2_SYMMETRY_PREDICT.dat" // G2 SF to predict
#define OUTPUT_FILENAME_G3_PREDICT "data/G3_SYMMETRY_PREDICT.dat" // G3 SF to predict
#define OUTPUT_FILENAME_ENERGY_PREDICT "data/ENERGY_PREDICT.dat" // Supervised predict energy
#define OUTPUT_FILENAME_G_NORMALIZED_LEARN "data/G_NORMALIZED_LEARN.dat" // G SF normalized learn values
#define OUTPUT_FILENAME_G_NORMALIZED_PREDICT "data/G_NORMALIZED_PREDICT.dat" // G SF normalized predict values
#define OUTPUT_FILENAME_LEARNING_PROCESS "data/LEARNING_PROCESS.dat" // Learning process adjust (to graph)
#define OUTPUT_FILENAME_PREDICT_FINAL "data/PREDICT_FINAL_OUTPUT.dat" // Final predict energy

#endif
