function [spectra, wave]=readfitsspec(filename,numOfSpec)

fileinfo=fitsinfo(filename);
if nargin==1
    numOfSpec=size(fileinfo.Contents,2);
end

fitsheader=fits_info(filename);
%spectra=ones(numOfSpec,fitsheader.NAXIS1);
%wave=ones(numOfSpec,fitsheader.NAXIS1);

for i=1:numOfSpec
    extname=fileinfo.Contents(i);
    
    if strcmp(extname,'Primary')
        datain=fitsread(filename);
    else
        datain=fitsread(filename,'image',i-1);
    end
    
    spectra{i}=datain(1,:);
    wave{i}=datain(2,:);
end

% datain=fitsread(filename);
% spectra(1,:)=datain(1,:);
% wave(2,:)=datain(2,:);
%
% if numOfSpec>1
%     for i=2:numOfSpec
%         spectra(i,:)=
%     end
% end