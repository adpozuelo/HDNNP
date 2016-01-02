High-Dimensional Neural Network Potentials
===========

<p> Developer: </p>
        Antonio Díaz Pozuelo (adpozuelo@uoc.edu)
        
<p> HDNNP is my UOC's (Universitat Oberta de Catalunya) final project degree (TFG). </p>

HDNNP is a feed forward neural network (FFNN) that calculates the macroscopic properties
(energy, pressure, conductivity, etc.) of an atom's system. It does so as follows:

- It learns from the properties of certain sets of systems of atoms (positions in a time sequence and energy for a given temperature and density).

- It predicts the macroscopic properties of another system of different atoms, under temperature and / or density, to those used for learning.

There are examples of atom's systems in "data" directory (50 boxes are included for each temperature data file).

Design & Arquitecture
==========

HDNNP is designed to use the massive parallel paradigm for intensive computation like symmetry functions calculus or neural network epochs. Thus, HDNNP needs a NVIDIA's VGA with CUDA arquitecture which must support compute capability 2.0 or higher.

Implementation
==========
HDNNP is implemented with NVIDIA CUDA SDK 6.5 and it uses the IMSL library for parameters optimization. Therefore it implements a fortran wrapper for languages intercommunication.

Requisites
==========

- Software:

  * NVIDIA CUDA Compiler (nvcc).
  * Intel Fortran Compiler (ifort) or GNU Fortran Compiler (gfortran).
  * IMSL Fortran compiled library.
  * GNUplot.

- Hardware:

  * NVIDIA's VGA CUDA capable arquitecture which must support compute capability 2.0 or higher.

Install
=======

<p> Download HDNNP application: </p>

        git clone https://github.com/adpozuelo/HDNNP.git
        cd HDNNP
        
<p> Compile (Makefile is ready for Intel Fortran Compiler)</b>: </p>

        make

<p> Execute HDNNP application (there are execution examples in HDNNP.sh): </p>

        ./HDNNP.sh
