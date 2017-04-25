clc;clear;close all
spectraFiles=dirFilenames('*WAVECAL_RED.fit');
%%
clear imdata
k=0;
for i=1:58 %i=4:46
    k=k+1;
    imdata(:,:,k)=fitsread(spectraFiles{i});
    imdata(:,:,k)=imdata(:,:,k)/max2(imdata(:,:,k));
end
fitswrite(sum(imdata,3),'WAVECAL_04to061_20160719.fit')
figure
imagesc(sum(imdata,3))

imdata(imdata<0.001)=0;
fitswrite(sum(imdata,3),'WAVECAL_04to061_20160719_lowclip.fit')
figure
imagesc(sum(imdata,3))

%%
clear imdata
k=0;
for i=4:46
    k=k+1;
    imdata(:,:,k)=fitsread(spectraFiles{i});
    imdata(:,:,k)=imdata(:,:,k)/max2(imdata(:,:,k));
end
fitswrite(sum(imdata,3),'WAVECAL_07to049_20160719.fit')
figure
imagesc(sum(imdata,3))

imdata(imdata<0.001)=0;
fitswrite(sum(imdata,3),'WAVECAL_07to049_20160719_lowclip.fit')
figure
imagesc(sum(imdata,3))
%%
clear imdata
k=0;
for i=4:46
    k=k+1;
    imdata(:,:,k)=fitsread(spectraFiles{i});
    imdata(:,:,k)=imdata(:,:,k)/max2(imdata(:,:,k)); 
end
imdata(:,:,i+1)=fitsread('003_CALS_50000_HENE1523_RED.fit');
imdata(:,:,i+1)=imdata(:,:,i+1)/max2(imdata(:,:,i+1));

fitswrite(sum(imdata,3),'WAVECAL-HENE_03-07to049_20160719.fit')
figure
imagesc(sum(imdata,3))

imdata(imdata<0.001)=0;
fitswrite(sum(imdata,3),'WAVECAL-HENE_03-07to049_20160719_lowclip.fit')
figure
imagesc(sum(imdata,3))

%%
clear imdata
k=0;
for i=1:58
    k=k+1;
    imdata(:,:,k)=fitsread(spectraFiles{i});
    imdata(:,:,k)=imdata(:,:,k)/max2(imdata(:,:,k)); 
end
imdata(:,:,i+1)=fitsread('003_CALS_50000_HENE1523_RED.fit');
imdata(:,:,i+1)=imdata(:,:,i+1)/max2(imdata(:,:,i+1));

fitswrite(sum(imdata,3),'WAVECAL-HENE_03to049_20160719.fit')
figure
imagesc(sum(imdata,3))

imdata(imdata<0.001)=0;
fitswrite(sum(imdata,3),'WAVECAL-HENE_03to049_20160719_lowclip.fit')
figure
imagesc(sum(imdata,3))