function [ampMaps, areaMaps, fwhmMaps, offsetMaps,indxSlices,poolNamesCellArr] = ...
    cestMapsFitLorModel(cestNormB0corData, offsets,indxSlices)
% [ampMaps, areaMaps, fwhmMaps, offsetMaps,indxSlices,poolNamesCellArr] = ...
%    cestMapsFitLorModel(cestNormB0corData, offsets,indxSlices)
%
% Script to do fit an N-pool Lorentzian-lineshape model to densely-sampled brain CEST-MRI data
%
% INPUT:
% cestNormB0corData - normalized and B0-corrected CEST data
% offsets - [ppm] frequency offsets
% indxSlices -  indices of slices to fit
%
% OUTPUT:
% ampMaps - [0 - 1] amplitude maps [dim1 x dim2 x Nslices x Npools]
% areaMaps - [a.u.] area maps [dim1 x dim2 x Nslices x Npools]
% fwhmMaps - [ppm] fwhm maps [dim1 x dim2 x Nslices x Npools]
% offsetMaps - [ppm] offsets maps [dim1 x dim2 x Nslices x Npools]
% indxSlices -  slices to fit
% poolNamesCellArr - names of fitted pools

% (c) Vitaliy Khlebnikov, PhD
% vital.khlebnikov@gmail.com

startScript=tic;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Number of pools to fit can be readily modified here (*** the only part of code to be editted ***)
%% Basis set for fitting an N-pool Lorentzian-lineshape model to densely-sampled brain CEST-MRI data
%% Fit parameters: [p1 p2 p3], where p1 - [0 - 1] amplitude, p2 - [ppm] FWHM, p3 - [ppm] freq offset with respect to water at 0

% Amide
poolNamesCellArr{1}='Amide pool';
par1=      [0.025    1   3.5]; % initial guess
lb1=       [0        0.3    3.3]; % lower limits
ub1=       [0.3      2.5  3.7]; % upper limits

% NOE
poolNamesCellArr{2}='NOE pool';
par2=      [0.2    3       -3.5];
lb2=        [0     0.3     -4];
ub2=        [0.8   5     -2.5];

% Water
poolNamesCellArr{3}='Water pool';
par3=      [0.9     1     0];
lb3=        [0.2  0.2     -1];
ub3=        [1     3      1];

% MT
poolNamesCellArr{4}='MT pool';
par4=      [0.1       15     -2.5];
lb4=        [0        5       -3.5];
ub4=        [1       100        0];

% Amine
poolNamesCellArr{5}='Amine pool';
par5=      [0.050     1     2];
lb5=        [0       0.3   1.7];
ub5=        [0.3     2.5   2.2];

% constant offset (FWHM=inf and CS=0)
poolNamesCellArr{6}='Const pool';
par6=      [0     10e6     0];
lb6=        [0     10e6   0];
ub6=        [0.2   10e6   0];

% putting all parameters together
par0=[par1 par2 par3 par4 par5 par6];
lb=[lb1 lb2 lb3 lb4 lb5 lb6];
ub=[ub1 ub2 ub3 ub4 ub5 ub6];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Npools=numel(poolNamesCellArr);
cestNormB0corData=cestNormB0corData(:,:,indxSlices,:);
[dim1, dim2, Nslices, Noffsets]=size(cestNormB0corData);

% memory preallocation for fitted maps
ampMaps=zeros(dim1,dim2,Nslices,Npools);
areaMaps=zeros(dim1,dim2,Nslices,Npools);
fwhmMaps=zeros(dim1,dim2,Nslices,Npools);
offsetMaps=zeros(dim1,dim2,Nslices,Npools);

f = waitbar(0,'1','Name','Fitting progress',...
    'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
setappdata(f,'canceling',0);

for sliceNo=1:Nslices
    [r, c]= find(reshape(cestNormB0corData(:,:,sliceNo,end),[dim1,dim2]));    
    for indx=drange(1: length(r))
        if getappdata(f,'canceling')
            break;
        end
        waitbar(indx/(numel(r)),f,sprintf('slice # %d (out of %d) voxels fitted # %d (out of %d)',sliceNo, Nslices, indx,numel(r)))
        
        spectrum=1-reshape(cestNormB0corData(r(indx),c(indx),sliceNo,:),[Noffsets, 1]);
        options=optimset('MaxFunEvals',1000,'MaxIter',300,'TolFun',1e-12,'TolX',1e-12,  'Display',  'off' );
        fitPar=lsqcurvefit(@NpoolLorFitting,par0, offsets(:),spectrum(:),lb,ub,options);
        
        temp=1;
        for poolNo=1:Npools
           ampMaps(r(indx),c(indx),sliceNo,poolNo)=fitPar(temp);
           areaMaps(r(indx),c(indx),sliceNo,poolNo)=fitPar(temp).*fitPar(temp+1).*pi;
           fwhmMaps(r(indx),c(indx),sliceNo,poolNo)=fitPar(temp+1);
           offsetMaps(r(indx),c(indx),sliceNo,poolNo)=fitPar(temp+2);
           temp=temp+3;
        end
    end
end
delete(f)

stopScript=toc(startScript);
fprintf('Fitting done!\nElapsed time is %d minutes and %f seconds\n',floor(stopScript/60),rem(stopScript,60))
end
