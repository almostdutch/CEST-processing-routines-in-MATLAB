% Master script with a collection of sub-routines for visualizing and
%       processing of densely-sampled CEST-MRI brain data
% A test dataset [testData.mat] is provided in folder ./test-data, which
% contains:
%       (1) [rawData] - 4D CEST-MRI data from the healthy human brain, 1 slice with 93
%       frequency offsets. Dimensions - [dim1 x dim2 x Nslices x Noffsets]
%       (2) [offsets] - [ppm] frequency offsets

warning off;
currentPath=pwd;
addpath(genpath(currentPath))

% Simple GUI for quick assessment of quality of the data. 
showSpectra

% Data normalization and B0 correction via spline interpolation
inputFilePath=strcat(pwd,'/test-data');
inputFileName='testData.mat';
fieldStrength=298;
bkgdThreshold=0.1;
[cestNormB0corData, b0Map, offsets]=...
    cestNormB0correction(inputFilePath, inputFileName, fieldStrength, bkgdThreshold);

% Generate CEST contrast maps by fitting an N-pool Lorentzian-lineshape model to densely-sampled brain CEST-MRI data
indxSlices=1;
[ampMaps, areaMaps, fwhmMaps, offsetMaps, indxSlices,poolNamesCellArr] = ...
    cestMapsFitLorModel(cestNormB0corData, offsets,indxSlices);

% Simple script to visualize fitted Lorentzian maps 
data=ampMaps; % amplitude maps
indxSlice=1;
checkFitMaps(data,indxSlice,poolNamesCellArr)

% Generate spectra: CEST and MTR asym
indxSlice=1;
NofROIs=2;
drawImageAtOffset=3.5;
[spectrumAvg, spectrumAvgStd, MTRavg, MTRavgStd,indxSlice,poolNamesCellArr, maskROIs]=...
    cestSpectraMTR(cestNormB0corData, offsets, indxSlice, NofROIs,drawImageAtOffset);

% Decompose CEST spectra into N-pools with Lorentzian-lineshape modeling
indxSlice=1;
NofROIs=1;
drawImageAtOffset=3.5;
[spectrumAvg, spectrumAvgStd, spectrumLorFit,spectrumLorFitPerPool,indxSlice,poolNamesCellArr, maskROIs]=...
    cestSpectraFitLorModel(cestNormB0corData, offsets, indxSlice, NofROIs, drawImageAtOffset);
