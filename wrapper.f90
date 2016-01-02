! UOC_TFG - Antonio Díaz Pozuelo - adpozuelo@uoc.edu
! Wrapper file
! Neural network learning process start
! Call to IMSL BCPOL function to optimize parameters
! High-Dimensional Neural Network Potentials (HDNNP)

! Module cfcn
! @arguments
! np: maximum symmetry functions number
! npy: maximum energies number
! nop: number of energies
! npi: symmetry functions number
! niter: iteration counter
! icalc: neural network mode (1 to learn, 0 to predict)
! noa: number of atoms per box
! ils: input layer size
! x: symmetry functions (data vector serialized)
! y: energies (vector)
! yy: energies fitted (vector)
module cfcn
  integer, parameter :: np=1000000, npy=100
  Integer :: nop, npp, niter, icalc, noa, ils
  real (kind=4) :: x(np) ,y(npy),yy(npy) 
end module cfcn

! Wrapper function called from C
! wrapper_(&symmetry_functions_number, &nop, &niter, &mode, symmetry_functions, energies, energies_fit, &parameters_number, parameters, &ib, xlb, xub, &ftol, &maxfcn, parameters_fit, &fvec, &number_of_atoms_per_box, &input_layer_size, &first_exe)
Subroutine wrapper(npi, nopi, niteri, icalci, xi, yi, yyi, npar, xg, ib, xlb, xub,&
     & ftol, maxfcni, xfin, fvec, noai, ilsi,first)
  use cfcn
  implicit none
  Integer :: npi, nopi, niteri, icalci, npar, ib, maxfcn, maxfcni, noai, ilsi, first
  real (kind=4), dimension(npi) :: xi, yi, yyi
  real (kind=4) :: xfin(npar),xg(npar),xlb(npar), xub(npar)
  real (kind=4) :: ftol, fvec
  External fcn, bcpol
  ! FORTRAN environment parameters (for high dimension)
  COMMON /WORKSP/  RWKSP
  REAL RWKSP(339915)
  ! First execution control
  if (first .eq. 1) then
     CALL IWKIN(339915)
  endif
  ! Limits control (for memory bounds)
  if (npi .gt. np) then
     print *, " error : np must be > in wrapper and in main cod&
          &e "
     stop
  endif
  if (nopi .gt. npy) then
     print *, " error : npy must be > nop"
     stop
  endif
  ! Assign wrapper arguments to local variables
  noa = noai
  ils = ilsi
  nop = nopi
  npp = npi
  niter = niteri
  icalci = icalc
  x(1:npi) = xi(1:npi)
  y(1:nop) = yi(1:nop)
  maxfcn = maxfcni
  ! Enable neural network learning mode
  icalc = 1
  ! Call BCPOL to NN learning start
  call bcpol(fcn,npar,xg,ib,xlb,xub,ftol,maxfcn,xfin,fvec)
  ! Enable neural network predict mode (for graph)
  icalc = 0
  ! Call cost function (NN prediction)
  Call fcn(npar,xfin,fvec)
  ! Update iteration counter
  niteri = niter
  ! Energies fitted
  yyi(1:nop) = yy(1:nop)
  ! Parameters fitted
  xg(1:npar) = xfin (1:npar)
end subroutine wrapper

! Cost function (NN prediction)
! @arguments
! npar: number of parameters
! xpar: paramteres (vector)
! f: residue 
subroutine fcn(npar,xpar,f)
  use cfcn
  implicit none
  integer, intent(IN) :: npar
  real (kind=4), intent(IN) :: xpar(npar)
  real (kind=4), intent(OUT) :: f
  ! Update iteration counter
  niter = niter + 1
  ! Call to NN prediction (cost function)
  ! residue_(&symmetry_functions_number, symmetry_functions, energies, energies_fit, &nop, parameters, &parameters_number, &niter, &fvec, &mode, &number_of_atoms_per_box, &input_layer_size);
  Call residue(npp, x, y, yy , nop, xpar, npar, niter, f, icalc, noa, ils)
end subroutine fcn
