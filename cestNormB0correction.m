function [cestNormB0corData, b0Map, offsets] = ...
    cestNormB0correction(inputFilePath, inputFileName, fieldStrength, bkgdThreshold)
% [cestNormB0corData, b0Map, offsets] = ...
%    cestNormB0correction(inputFilePath, inputFileName, fieldStrength, bkgdThreshold)
%
% Script to do normalization (with outtermost offsets) of CEST-MRI data followed by B0 correction via
% spline interpolation
%
% INPUT:
% inputFilePath - path to input file
% inputFileName - name of input file
% fieldStrenth -  field strength in MHz
% bkgdThreshold - [0 - 1] background threshold (optional)
%
% OUTPUT:
% cestB0corData - normalized and BO-corrected CEST data [dim1,dim2,Nslices,Noffsets]
% b0Map - [ppm] B0 map [dim1,dim2,Nslices]

% (c) Vitaliy Khlebnikov, PhD
% vital.khlebnikov@gmail.com

startScript=tic;
if nargin<3
    fprintf('Not enough input arguments\n')
    return;
end

% A simple way to exclude background voxels containing no useful
% information
if nargin==3
    bkgdThreshold=0.1;
end

% Read raw data
filePath=inputFilePath;
fileName=inputFileName;
filePathName=fullfile(filePath,fileName);
rawData=[];
offsets=[];
load(filePathName);
cestRawData=double(rawData);
offsets=double(offsets);
n_offsetAt0=find(offsets==0);

[dim1, dim2, Nslices,Noffsets]=size(cestRawData);
b0Map=zeros(dim1,dim2,Nslices);
cestNormB0corData=zeros(dim1,dim2,Nslices,Noffsets);

% range for B0 search
LeftLimit=-3; % ppm left limit for min search
RightLimit=3; % ppm right limit for min search
FS=fieldStrength;
threshold=bkgdThreshold;
for sliceNo=1:Nslices
    [row, col]= find(mat2gray(reshape(cestRawData(:,:,sliceNo,10),[dim1,dim2]))>threshold);
    for indx=drange(1:length(row))
        spectrum=reshape(cestRawData(row(indx), col(indx), sliceNo, :),[Noffsets 1]);
        if any(isnan(spectrum))
            continue;
        end
        
        % limits for search of min of CEST spectrum
        [~, n_left]=min(abs(LeftLimit-offsets));
        [~, n_right]=min(abs(RightLimit-offsets));
        
        % interpolation of CEST-spectrum to a resolution of 1 Hz
        offsetsInterp=[offsets(n_left)*FS:1:offsets(n_right)*FS]./FS;
        %spline(offsets(n_left:n_right), spectrum(n_left:n_right),offsetsInterp)
        %spectrum(n_left:n_right)
        [~, n_min]=min(spline(offsets(n_left:n_right), spectrum(n_left:n_right),offsetsInterp));
        
        % generating B0 map
        b0Map(row(indx), col(indx),sliceNo)=offsetsInterp(n_min);
        
        % CEST data normalization
        cestNormB0corData(row(indx),col(indx),sliceNo,1:n_offsetAt0)=cestRawData(row(indx),col(indx),sliceNo,1:n_offsetAt0)...
            ./(cestRawData(row(indx),col(indx),sliceNo,1)+1e-06);
        cestNormB0corData(row(indx),col(indx),sliceNo,n_offsetAt0+1:end)=cestRawData(row(indx),col(indx),sliceNo,n_offsetAt0+1:end)...
            ./(cestRawData(row(indx),col(indx),sliceNo,end)+1e-06);

        % CEST data B0 correction
        spectrum=reshape(cestNormB0corData(row(indx), col(indx), sliceNo, :),[Noffsets 1]);
        b0Shift=b0Map(row(indx), col(indx),sliceNo);
        cestNormB0corData(row(indx), col(indx),sliceNo,:) = interp1(offsets-b0Shift,spectrum,offsets,'spline');
    end
end

elapsedTime=toc(startScript);
fprintf('B0 correction done!\nElapsed time is %d minutes and %f seconds\n',floor(elapsedTime/60),rem(elapsedTime,60))