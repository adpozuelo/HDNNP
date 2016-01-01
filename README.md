High-Dimensional Neural Network Potentials
===========

<p> Developer: </p>
        Antonio Díaz Pozuelo (adpozuelo@uoc.edu)
        
HDNNP is my UOC's (Universitat Oberta de Catalunya) final project degree (TFG).

Requisites
==========

- Software:

  * NVIDIA CUDA Compiler (nvcc)
  * Intel Fortran Compiler (ifort) or GNU Fortran Compiler (gfortran).
  * IMSL Fortran compiled library
  * GNUplot

- Hardware:

  * NVIDIA VGA CUDA capable arquitecture.

Install
=======

<p> Download HDNNP application: </p>

        git clone https://github.com/adpozuelo/HDNNP.git
        cd HDNNP
        
<p> Compile (Makefile is ready for Intel Fortran Compiler)</b>: </p>

        make

<p> Execute HDNNP application (execution examples in HDNNP.sh): </p>

        ./HDNNP.sh
        
<p> Demo data is included in "data" directorie (50 boxes are included in each temperature data file) </p>

