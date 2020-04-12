function checkFitMaps(data,indxSlice,poolNamesCellArr)
% checkFitMaps(data,sliceNo,poolNamesCellArr)
%
% Program to visualize fitted maps
%
% data - fitted maps (e.g. ampMap, areaMap, fwhmMap, offsetMap)
% indxSlice - slice index
% poolNamesCellArr - fitted basis set

figure
for ii=1:numel(poolNamesCellArr)
    subplot(3,3,ii)
    imshow(data(:,:,indxSlice,ii),[]),axis off, axis equal, colormap parula
    title(poolNamesCellArr(ii))
end
end