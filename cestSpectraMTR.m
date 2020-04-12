function [spectrumAvg, spectrumAvgStd, MTRavg, MTRavgStd,indxSlice,maskROIs]=...
    cestSpectraMTR(cestNormB0corData, offsets, indxSlice, NofROIs,drawImageAtOffset)
% [spectrumAvg, spectrumAvgStd, MTRavg, MTRavgStd,indxSlice,maskROIs]=...
%    cestSpectraMTR(cestNormB0corData, offsets, indxSlice, NofROIs,drawImageAtOffset)
%
% Script to do generate normalized and B0-corrected spectra: CEST spectrum (left subplot) and MTRasym (right subplot)
%
% INPUT:
% cestNormB0corData - normalized and B0-corrected CEST data
% offsets - [ppm] frequency offsets
% indxSlice -  slice index
% NofROIs - number of ROIs to draw
% drawImageAtOffset - [ppm] draw image at this freq offset
%
% OUTPUT:
% spectrumAvg - [0 - 1] CEST spectra [CEST Noffsets x NofROIs]
% spectrumAvgStd - [0 - 1] CEST spectra std deviation [CEST Noffsets x NofROIs]
% indxSlice -  slice index
% maskROIs - defined ROIs
%% MTR asym spectra make sense only for symetric frequency offsets
% MTRavg - [0 - 1] MTR asym spectra [MTR asym Noffsets x NofROIs]
% MTRavgStd - [0 - 1] MTR asym std deviation [MTR asym Noffsets x NofROIs]

% (c) Vitaliy Khlebnikov, PhD
% vital.khlebnikov@gmail.com

startScript=tic;
close all
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [ppm] X [0 - 1] Y limits for plots
XYscaleSpectrum=[-6 6 0 1.1];
XYscaleMTR=[0 6 -0.5 0.5];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
    
    %saveas(h1,'refImageROIs','fig')
end

n_offsetAt0=find(offsets==0);
offsetsMTR=offsets(n_offsetAt0:end);
spectrumAvg=zeros(Noffsets,ROIsNo);
spectrumAvgStd=zeros(Noffsets,ROIsNo);
MTRavg_1=zeros(numel(offsetsMTR),ROIsNo); % MTR asym standard
MTRavg_2=zeros(numel(offsetsMTR),ROIsNo);
MTRavgStd_1=zeros(numel(offsetsMTR),ROIsNo); % MTR asym typically used for paraCEST agents
MTRavgStd_2=zeros(numel(offsetsMTR),ROIsNo);

for ROIsNo=1:NofROIs
    cestROIavgData=zeros(size(cestNormB0corData));
    indxNonZero=find(maskROIs(:,:,ROIsNo)>0);
    
    for offsetNo=1:Noffsets
        cestROIavgData(:,:,offsetNo)=reshape(cestNormB0corData(:,:,offsetNo),[dim1,dim2]).* reshape(maskROIs(:,:,ROIsNo),[dim1,dim2]);
        temp=reshape(cestROIavgData(:,:, offsetNo),[dim1,dim2]);
        spectrumAvg(offsetNo,ROIsNo)=mean2(temp(indxNonZero));
        spectrumAvgStd(offsetNo,ROIsNo)=std2(temp(indxNonZero));
    end
    
    for tempIndx=1:n_offsetAt0-1
        temp=reshape(cestROIavgData(:,:,n_offsetAt0-tempIndx),[dim1,dim2])-reshape(cestROIavgData(:,:,n_offsetAt0+tempIndx),[dim1,dim2]);
        MTRavg_1(tempIndx+1,ROIsNo)=mean2(temp(indxNonZero));
        MTRavgStd_1(tempIndx+1,ROIsNo)=std2(temp(indxNonZero));
        temp=1-reshape(cestROIavgData(:,:,n_offsetAt0+tempIndx),[dim1,dim2])./reshape(cestROIavgData(:,:,n_offsetAt0-tempIndx),[dim1,dim2]);
        MTRavg_2(tempIndx+1,ROIsNo)=mean2(temp(indxNonZero));
        MTRavgStd_2(tempIndx+1,ROIsNo)=std2(temp(indxNonZero));
    end
    
    % chosing which MTR asym to use
    MTRavg=MTRavg_1;
    MTRavgStd=MTRavgStd_1;
    
    figName=strcat('CESTandMTRasym-ROI-',num2str(ROIsNo));
    h=figure;
    set(gcf,'name',sprintf('%s',figName),'numbertitle','off')
    subplot(121)
    plot(offsets, spectrumAvg(:, ROIsNo), 'b.','MarkerSize',10)
    hold on, grid on
    plot(offsets, spectrumAvg(:, ROIsNo), 'b','LineWidth',1)
    errorbar(offsets, spectrumAvg(:, ROIsNo),spectrumAvgStd(:, ROIsNo)/2,'.b','LineWidth',1)
    ylabel('M_z/M_0')
    xlabel('Frequency offset [ppm]')
    axis(XYscaleSpectrum)
    set(gca, 'Xdir', 'reverse')
    set(gca,'FontSize',14)
    subplot(122)
    plot(offsetsMTR, MTRavg(:,ROIsNo), 'b.','MarkerSize',10)
    hold on, grid on
    plot(offsetsMTR, MTRavg(:,ROIsNo), 'b','LineWidth',1)
    errorbar(offsetsMTR, MTRavg(:,ROIsNo),MTRavgStd(:, ROIsNo)/2,'.b','LineWidth',1)
    ylabel('MTRasym')
    xlabel('Frequency offset [ppm]')
    axis(XYscaleMTR)
    set(gca,'FontSize',14)
    
    %saveas(h,figName,'fig')
end

stopScript=toc(startScript);
fprintf('Processing done!\nElapsed time is %d minutes and %f seconds\n',floor(stopScript/60),rem(stopScript,60))
end
