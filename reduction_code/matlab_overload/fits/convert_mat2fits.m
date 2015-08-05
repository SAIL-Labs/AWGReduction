% convert all tiffs to fits

basefilename='1x7-001-dark';
files=dir([basefilename '.tif']);
filenames={files.name}';


extra=createcards('source','16bit word tif file converted to fits',' ');
extra.addcard('tif2fits','T',' ');
extra.addcard('EXPOSURE',10,' ');
extra.addcard('GAIN',0.46,' ');
extra.addcard('READNOIS',10,' ');

%extra.addcard('IMAGETYP','LIGHT',' ');
extra.addcard('IMAGETYP','DARK',' ');
%extra.addcard('IMAGETYP','BIAS',' ');
extra.addcard('DISPAXIS','2',' '); % specta horizontal


fitswrite(double(imread(filenames{1})),[filenames{1}(1:end-4) '.fit'],extra.cards)
