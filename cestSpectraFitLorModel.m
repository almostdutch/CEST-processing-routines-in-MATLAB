function [spectrumAvg, spectrumAvgStd, spectrumLorFit,spectrumLorFitPerPool,indxSlice,poolNamesCellArr,maskROIs]=...
    cestSpectraFitLorModel(cestNormB0corData, offsets, indxSlice, NofROIs,drawImageAtOffset)
% [spectrumAvg, spectrumAvgStd, spectrumLorFit,spectrumLorFitPerPool,indxSlice,poolNamesCellArr,maskROIs]=...
%    cestSpectraFitLorModel(cestNormB0corData, offsets, indxSlice, NofROIs,drawImageAtOffset)
%
% Script to do fit an N-pool Lorentzian-lineshape model to densely-sampled
% brain CEST spectra.
% Script will generate normalized and B0-corrected spectra and an N-pool
% Lorentzian fit.
%
% INPUT:
% cestNormB0corData - normalized and B0-corrected CEST data
% offsets - [ppm] frequency offsets
% indxSlice -  slice index
% NofROIs - number of ROIs to draw
% drawImageAtOffset - [ppm] draw image at this freq offset for ROI
% definition
%
% OUTPUT:
% spectrumAvg - [0 - 1] CEST spectra [CEST Noffsets x NofROIs]
% spectrumAvgStd - [0 - 1] CEST spectra std deviation [CEST Noffsets x NofROIs]
% spectrumLorFit - [0 - 1] CEST Lorentzian cumulative fit [CEST Noffsets x NofROIs]
% spectrumLorFitPerPool - [0 - 1] CEST Lorentzian fit per pool [CEST Noffsets x NofROIs x Npools]
% indxSlice -  slice index
% poolNamesCellArr - names of fitted pools
% maskROIs - defined ROIs

% (c) Vitaliy Khlebnikov, PhD
% vital.khlebnikov@gmail.com

startScript=tic;
close all
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [ppm] X [0 - 1] Y limits for plots
XYscaleSpectrum=[-6 6 0 1.1];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
colors = distinguishable_colors(50);
colors = colors(:,:);

%% Drawing ROIs
[~, n_ref]=min(abs(drawImageAtOffset-offsets));
cestNormB0corData=squeeze(cestNormB0corData(:,:,indxSlice,:));
[dim1, dim2, Noffsets]=size(cestNormB0corData);

h1=figure(1);
imshow(cestNormB0corData(:,:,n_ref),[0.2 1]), axis off, axis equal
set(h1, 'name','ROI selection','numbertitle','off')
pause(0.5)
maskROIs=zeros(dim1,dim2,NofROIs);
for ROIsNo=1:NofROIs
    title(sprintf('Draw ROI # %d (out of %d)', ROIsNo,NofROIs))
    [x, y, BW, xi, yi]=roipoly;
    for tempIndx = 1:length(xi)
        x = xi;
        y = yi;
        patch(x, y, 'r', 'FaceAlpha', 0.00,'EdgeColor',[1 0 0])
    end
    maskROIs(:,:,ROIsNo)=BW;
    text(min(x(:))-1,min(y(:))-1,sprintf('ROI %d',ROIsNo),'FontSize',10, 'Color',[1 0 0])
    
    [r, c]= find(mat2gray(squeeze(cestNormB0corData(:,:,1))).*BW>0);
    ROIsSizeInPixels(ROIsNo)=numel(r);
    saveas(h1,'refImageROIs','fig')
end

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
spectrumAvg=zeros(Noffsets,NofROIs);
spectrumAvgStd=zeros(Noffsets,NofROIs);
spectrumLorFit=zeros(Noffsets,NofROIs);
spectrumLorFitPerPool=zeros(Noffsets,NofROIs,Npools);

for ROIsNo=1:NofROIs
    cestROIavgData=zeros(size(cestNormB0corData));
    indxNonZero=find(maskROIs(:,:,ROIsNo)>0);
    
    for offsetNo=1:Noffsets
        cestROIavgData(:,:,offsetNo)=reshape(cestNormB0corData(:,:,offsetNo),[dim1,dim2]).* reshape(maskROIs(:,:,ROIsNo),[dim1,dim2]);
        temp=reshape(cestROIavgData(:,:, offsetNo),[dim1,dim2]);
        spectrumAvg(offsetNo,ROIsNo)=mean2(temp(indxNonZero));
        spectrumAvgStd(offsetNo,ROIsNo)=std2(temp(indxNonZero));
    end
    
    spectrum=1-spectrumAvg(:,ROIsNo);
    options=optimset('MaxFunEvals',1000,'MaxIter',300,'TolFun',1e-08,'TolX',1e-08,  'Display',  'off' );
    fitPar=lsqcurvefit(@NpoolLorFitting,par0, offsets(:),spectrum(:),lb,ub,options);
    spectrumLorFit(:,ROIsNo)=1-NpoolLorFitting(fitPar, offsets);
    
    temp=1;
    for poolNo=1:Npools
        parOnlyCurrentPool=zeros(size(fitPar));
        parOnlyCurrentPool(temp:temp+2)=fitPar(temp:temp+2);
        spectrumLorFitPerPool(:,ROIsNo,poolNo)=NpoolLorFitting(parOnlyCurrentPool, offsets);
        temp=temp+3;
    end
end

for ROIsNo=1:NofROIs
    
    figName=strcat('CESTandLorFit-ROI-',num2str(ROIsNo));
    h=figure;
    set(gcf,'name',sprintf('%s',figName),'numbertitle','off')
    lgnd(1)=plot(offsets, spectrumAvg(:, ROIsNo), 'b.','MarkerSize',10, 'DisplayName','Data');
    hold on, grid on
    errorbar(offsets, spectrumAvg(:, ROIsNo),spectrumAvgStd(:, ROIsNo)/2,'.b','LineWidth',1)
    lgnd(2)=plot(offsets, spectrumLorFit(:, ROIsNo), 'k','LineWidth',1, 'DisplayName','full Lor fit');
    ylabel('M_z/M_0')
    xlabel('Frequency offset [ppm]')
    axis(XYscaleSpectrum)
    set(gca, 'Xdir', 'reverse')
    set(gca,'FontSize',14)
    
    for poolNo=1:Npools
        lgnd(poolNo+2)=plot(offsets, spectrumLorFitPerPool(:, ROIsNo,poolNo),'-','Color',colors(poolNo,:),'LineWidth',2,'DisplayName',poolNamesCellArr{poolNo});
    end
    legend(lgnd);
    
    %saveas(h,figName,'fig')
end

stopScript=toc(startScript);
fprintf('Fitting done!\nElapsed time is %d minutes and %f seconds\n',floor(stopScript/60),rem(stopScript,60))
end
