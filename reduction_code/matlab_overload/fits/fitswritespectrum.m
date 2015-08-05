function fitswritespectrum(imagedata,filename,varargin)
%FITSWRITE Write image to FITS file.
%   fitswrite(IMAGEDATA,FILENAME) writes IMAGEDATA to the FITS file
%   specified by FILENAME.  If FILENAME does not exist, it is created as a
%   simple FITS file.  If FILENAME does exist, it is either overwritten or
%   the image is appended to the end of the file.
%
%   fitswrite(...,'PARAM','VALUE') writes IMAGEDATA to the FITS file
%   according to the specified parameter value pairs.  The parameter names
%   are as follows:
%
%       'WriteMode'    One of these strings: 'overwrite' (the default)
%                      or 'append'. 
%
%       'Compression'  One of these strings: 'none' (the default), 'gzip', 
%                      'gzip2', 'rice', 'hcompress', or 'plio'.
%
%   Please read the file cfitsiocopyright.txt for more information.
%
%   Example:  Create a FITS file the red channel of an RGB image.
%       X = imread('ngc6543a.jpg');
%       R = X(:,:,1); 
%       fitswrite(R,'myfile.fits');
%       fitsdisp('myfile.fits');
%
%   Example:  Create a FITS file with three images constructed from the
%   channels of an RGB image.
%       X = imread('ngc6543a.jpg');
%       R = X(:,:,1);  G = X(:,:,2);  B = X(:,:,3);
%       fitswrite(R,'myfile.fits');
%       fitswrite(G,'myfile.fits','writemode','append');
%       fitswrite(B,'myfile.fits','writemode','append');
%       fitsdisp('myfile.fits');
%
%   See also FITSREAD, FITSINFO, MATLAB.IO.FITS.

%   Copyright 2011-2013 The MathWorks, Inc.


p = inputParser;

datatypes = {'uint8','int16','int32','int64','single','double'};
p.addRequired('imagedata',@(x) validateattributes(x,datatypes,{'nonempty'}));
p.addRequired('filename', ...
    @(x) validateattributes(x,{'char'},{'nonempty'},'','FILENAME'));

p.addParamValue('writemode','overwrite', ...
    @(x) validateattributes(x,{'char'},{'nonempty'},'','WRITEMODE'));

p.addParamValue('compression','none', ...
     @(x) validateattributes(x,{'char'},{'nonempty'},'','COMPRESSION'));

p.addOptional('keywords', [],@(x)  validateattributes(x,{'cell'},{'ncols', 3}))
 
p.parse(imagedata,filename,varargin{:});

mode = validatestring(p.Results.writemode,{'overwrite','append'});
compscheme = validatestring(p.Results.compression, ...
    {'gzip','gzip2','rice','hcompress','plio','none'});
keywords=p.Results.keywords;

import matlab.io.*
if strcmpi(mode,'append')
    fptr = fits.openFile(filename,'readwrite');
else
    if exist(filename,'file')
        delete(filename);
    end
    fptr = fits.createFile(filename);
end


try
    if ~strcmpi(compscheme,'none')
        fits.setCompressionType(fptr,compscheme);
    end
    % create HDU
    %createImg
    NAXIS=size(imagedata);
    NAXIS(NAXIS==1)=[];
    %fits.insertImg(fptr,class(imagedata),NAXIS);
    fits.createImg(fptr,class(imagedata),NAXIS);
    fits.writeImg(fptr,imagedata);
    
    % add header words
    for i=1:size(keywords,1)     
        if strcmpi(keywords{i,1},'comment')
            fits.writeComment(fptr,keywords{i,2})
        else
            fits.writeKey(fptr,keywords{i,1},keywords{i,2},keywords{i,3});
        end
    end
    fits.writeDate(fptr);
    
catch me
    fits.closeFile(fptr);
    rethrow(me);
end

fits.closeFile(fptr);
