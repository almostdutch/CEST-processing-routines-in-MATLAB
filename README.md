# CEST-processing-routines-in-MATLAB
A collection of sub-routines written in MATLAB for visualizing and processing of densely-sampled CEST-MRI brain data

cest_master.m is a master script containing all of the sub-routines with examples of running them.

Sub-routines:

1. showSpectra - Simple GUI for quick assessment of quality of the data
2. cestNormB0correction.m - Data normalization and B0 correction via spline interpolation
3. cestMapsFitLorModel.m - Generate CEST contrast maps by fitting an N-pool Lorentzian-lineshape model to densely-sampled brain CEST-MRI data
4. cestSpectraMTR.m - Generate spectra: CEST and MTR asym
5. cestSpectraFitLorModel.m - Decompose CEST spectra into N-pools with Lorentzian-lineshape modeling

**Screenshots:**

Simple GUI for quick assessment of quality of the data
![](https://github.com/almostdutch/CEST-processing-routines-in-MATLAB/blob/master/test-data/gui.jpg)

Analysis of densely-sampled CEST spectra in terms of Lorentzian-lineshape basis functions
![](https://github.com/almostdutch/CEST-processing-routines-in-MATLAB/blob/master/test-data/CEST_Npool_lorFitting.jpg)
