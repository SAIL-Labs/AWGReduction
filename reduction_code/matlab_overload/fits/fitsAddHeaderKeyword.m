function fitsAddHeaderKeyword(filename,keyword,value,comment)
if ~iscell(filename)
    filename={filename};
end
import matlab.io.*
for i=1:length(filename)
    try
        fptr = fits.openFile(filename{i},'readwrite');
        fits.writeKey(fptr,keyword,value,comment);
    catch me
        fits.closeFile(fptr);
        rethrow(me);
    end
    
    fits.closeFile(fptr);
end
