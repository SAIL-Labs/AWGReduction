clc; clear; set(0,'DefaultFigureWindowStyle','docked')
%import chrislib.misprint
%import chrislib.utilities.*

% %% reduce frames (dark subtract)
% superK=dirFilenames('*SUPERK*.fit');
% for ii=2:length(superK)
%     imdata(:,:,ii)=fitsread(superK{ii});
% end
% header=fitsheader(superK{2});
% oldheader=fitstructure2cell(header);
% fitswrite(sum(imdata,3),'wavecal.fit',oldheader(7:end,:))

%% Init
s2r = chrislib.misprint('42_CALS_500000_HALOGEN_RED','reference','43_CALS_750000_HALOGEN_RED',...
    'plotAlot',false,'numOfOrders',1,'numOfFibers',9,...
    'forceTrace',false,'forceExtract',true,...
    'forceDefineMaskEdge',false,'needsMask',true,...
    'treatFibresAsOrders',true,...
    'clipping',[0 0 0 0],...
    'peakcut',0.0001,...
    'usecurrentfolderonly',true,'OXmethod','MPDoptimalExt',...MPDoptimalExtDCBack
    'numTraceCol',320,'firstCol',1,'lastCol',320,...
    'parallel',false,'wavesolution','wavecal_good_20160719.mat');

% s2r.imdata(s2r.imdata<0)=0;

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

s2r.specWidth=s2r.fittedWidth;

if s2r.useReference
    out=dftregistration(fft2(s2r.flatImdata),fft2(s2r.imdata),100);
    sprintf('SHIFT X: %f, Y: %f',out(3),out(4))
    out(3)=0;
    out(4)=0;
    s2r.specCenters=s2r.polyfitwork(s2r.imdim,s2r.fittedCenters,s2r.fittedCol,2,out(3:4));
end

s2r.extractSpectra;

if s2r.useReference
    flatBlaze=permute(s2r.referenceSpectraValues,[2 1]);
    s2r.flatBlaze(1,:,:)=flatBlaze;
    %s2r.flatBlaze(1,:,:)=bsxfun(@rdivide,flatBlaze,mean(flatBlaze));
else
    s2r.flatBlaze=ones(size(s2r.spectraValues));
end

s2r.plotSpectraValuesFor(1:9,true,false) %[1 320],[0 1.5]

figure(10)
plot(1:s2r.imdim(2)*9,reshape(s2r.spectraValues,[1 s2r.imdim(2)*9]),...
    1:s2r.imdim(2)*9,reshape(s2r.spectraValues./s2r.flatBlaze,[1 s2r.imdim(2)*9]),...
    1:s2r.imdim(2)*9,reshape(s2r.flatBlaze,[1 s2r.imdim(2)*9])*max(s2r.spectraValues(:)))

plot(s2r.wavefit(:),reshape(s2r.spectraValues,[1 s2r.imdim(2)*9]),...
    s2r.wavefit(:),reshape(s2r.spectraValues./s2r.flatBlaze,[1 s2r.imdim(2)*9]),...
    s2r.wavefit(:),reshape(s2r.flatBlaze,[1 s2r.imdim(2)*9])*max(s2r.spectraValues(:)))

ylim([0 mean(s2r.spectraValues(:))*6])

figure(11)
legend({'raw spectra', 'flate divided spectra', 'flat spectra (rescalled)'})
s2r.lineariseAndCombineSpectrum(true)
s2r.plotFinalSpectra
return
%%
wave=squeeze(s2r.wavefit);
dwave=-diff(wave);
dwave(end+1,:)=dwave(end,:);

specWidth=squeeze(s2r.specWidth)'*2*sqrt(2*log(2));
R_est=wave./(specWidth.*dwave);
plot(wave,R_est)

save([s2r.targetBaseFilename 'resolution_map.mat'],'wave','dwave','specWidth','R_est')

%%
wave=squeeze(s2r.wavefit);
spec=squeeze(s2r.spectraValues);

combineWave=s2r.finalWave;
combinSpec=s2r.finalSpec;

save([s2r.targetBaseFilename 'spectraandwave.mat'],'wave','spec','combineWave','combinSpec')
