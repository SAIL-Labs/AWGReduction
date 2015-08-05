clc; clear; set(0,'DefaultFigureWindowStyle','docked')
%import chrislib.misprint
%import chrislib.utilities.*

%% reduce frames (dark subtract)
%prepareAWGfits('superK_no_filter_200us.fits','200us_darks.fits');


%% Init
s2r = misprint('PreCals_500000_coadded_Halogen_RED','reference','',...
    'plotAlot',true,'numOfOrders',1,'numOfFibers',9,...
    'forceTrace',true,'forceExtract',false,...
    'forceDefineMaskEdge',false,'needsMask',true,...
    'treatFibresAsOrders',true,...
    'clipping',[0 0 0 0],...
    'peakcut',0.04,...
    'usecurrentfolderonly',true,'OXmethod','MPDoptimalExt',...MPDoptimalExtDCBack
    'numTraceCol',20,'firstCol',10,'lastCol',290,...
    'parallel',false);


% set mask to clip incomplete orders
try
    load('mask_full.mat')
catch err
    imagesc(log10(s2r.imdata-min2(s2r.imdata)+1))
    [xi, yi]=getpts;
    BW1 = roipoly(s2r.imdata,xi,yi);
    save('mask_full.mat','BW1','xi','yi')
end
s2r.mask=BW1;

s2r.getBadPixelMask()

% imagesc(imdataraw);hold on
% [x,y]=find(s2r.badpixelmask);
% plot(y,x,'wo')
% hold off

% trace spectra (or load reference)
s2r.traceSpectra;


% check allingment

if s2r.useReference
    out=dftregistration(fft2(s2r.imdata/max2(s2r.imdata)),fft2(s2r.flatImdata/max2(s2r.flatImdata)),100)'
    sprintf('SHIFT X: %f, Y: %f',out(3),out(4))
    s2r.specCenters=s2r.polyfitwork(s2r.imdim,s2r.fittedCenters,s2r.fittedCol+out(4),2)+out(3);
    s2r.specWidth=s2r.polyfitwork(s2r.imdim,s2r.fittedWidth,s2r.fittedCol+out(4),3);
end

s2r.extractSpectra;

%s2r.getP2PVariationsAndBlaze;
if s2r.useReference
    flatBlaze=permute(s2r.referenceSpectraValues,[2 1]);
    s2r.flatBlaze(1,:,:)=bsxfun(@rdivide,flatBlaze,max(flatBlaze));
else
    s2r.flatBlaze=ones(size(s2r.spectraValues));
end
%s2r.spectraValues=s2r.flatBlaze;

%s2r.spectraValues=s2r.spectraValues-bsxfun(@times,s2r.flatBlaze,max(s2r.spectraValues))+3;
%s2r.spectraValues(1,:,2)=s2r.spectraValues(1,:,2)-smooth(s2r.spectraValues(1,:,2),20)'+max(s2r.spectraValues(1,:,2));
%%
s2r.plotSpectraValuesFor(1:9,true,false,[1 320],[0 1.5])
figure(10)
plot(1:320*9,reshape(s2r.spectraValues,[1 320*9]),...
    1:320*9,reshape(s2r.spectraValues./s2r.flatBlaze,[1 320*9]),...
    1:320*9,reshape(s2r.flatBlaze,[1 320*9])*max(s2r.spectraValues(:)))
ylim([0 mean(s2r.spectraValues(:))*6])

legend({'raw spectra', 'flate divided spectra', 'flat spectra (rescalled)'})