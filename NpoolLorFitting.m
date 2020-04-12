function fittedSpectrum = NpoolLorFitting(fitPar, offsets)
% fittedSpectrum = NpoolLorFitting(par, offsets)
%
% Implementation of an N-pool Lorentzian-lineshape model

count=1;
Npools=numel(fitPar)/3;
tempVar=zeros(numel(offsets),Npools);
for ii=1:Npools
    tempVar(:,ii)=fitPar(count)./(1+((offsets-fitPar(count+2))./fitPar(count+1)).^2+1e-06);
    count=count+3;
end
fittedSpectrum=sum(tempVar,2);
end