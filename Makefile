OBJ_ALL = main.o messages.o misc.o process_input_files.o load_boxes.o symmetry_functions.o nn_preconditioning.o nn_start.o residue.o final_results.o wrapper.o
FC = ifort
FFLAGS = -O2 -CB -c
CC = nvcc
CFLAGS = -w -c -O2 -use_fast_math
LIBPATH = -L/usr/local/cuda/lib64

%.o: %.f90 %.cu %.mod %.h

.SUFFIXES : .o .f90 .cu

.f90.o:
	$(FC) $(FFLAGS) $<

.cu.o:  
	$(CC) $(CFLAGS) $<

nonlfit_gpu : $(OBJ_ALL)
	$(FC) $(LIBPATH) -o HDNNP  $(OBJ_ALL) -limsl -lcudart -lstdc++ -nofor-main

clean:
	rm -f  $(OBJ_ALL)
	rm -f *.mod
	rm -f HDNNP




