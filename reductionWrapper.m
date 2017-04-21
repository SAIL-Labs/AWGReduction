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
s2r = chrislib.misprint('44_CALS_1000000_HALOGEN_RED','reference','44_CALS_1000000_HALOGEN_RED',...
    'plotAlot',true,'numOfOrders',1,'numOfFibers',9,...
    'forceTrace',false,'forceExtract',true,...
    'forceDefineMaskEdge',false,'needsMask',true,...
    'treatFibresAsOrders',true,...
    'clipping',[10 0 0 0],...
    'peakcut',0.0001,...
    'usecurrentfolderonly',true,'OXmethod','MPDoptimalExt',...MPDoptimalExtDCBack
    'numTraceCol',311,'firstCol',1,'lastCol',311,...
    'parallel',false,'wavesolution','wavecal.mat');

% s2r.imdata(s2r.imdata<0)=0;clar

% set mask to clip incomplete orders
try
    load('mask_full.mat')
catch err
    imagesc(log10(s2r.imdata-min2(s2r.imdata)+1))
    [xi, yi]=getpts;
    BW1 = roipoly(s2r.imdata,xi,yi);
    save('mask_full.mat','BW1','xi','yi')
end
s2r.mask=BW1(max([1 s2r.clipping(2)]):end-s2r.clipping(4),max([1 s2r.clipping(1)]):end-s2r.clipping(3));
s2r.wavefit=s2r.wavefit(:,max([1 s2r.clipping(1)]):end-s2r.clipping(3),:);

%s2r.getBadPixelMask()

% imagesc(imdataraw);hold on
% [x,y]=find(s2r.badpixelmask);
% plot(y,x,'wo')
% hold off

% trace spectra (or load reference)
s2r.traceSpectra;

s2r.specWidth=ones(size(s2r.specWidth));

s2r.specWidth=s2r.fittedWidth;
% check allingment


%
if s2r.useReference
    maximdata=max2(s2r.imdata);
    IN=(s2r.imdata/maximdata);
    maxflatimdata=max2(s2r.flatImdata);
    REF=(s2r.flatImdata/maxflatimdata);
    if 1
        [optimizer, metric] = imregconfig('monomodal');
        if 1
            [movingRegistered] = imregister(IN, REF, 'translation', optimizer, metric);
            s2r.imdata=movingRegistered*maximdata;
        else
            [movingRegistered] = imregister(REF,IN, 'similarity', optimizer, metric);
            s2r.flatImdata=movingRegistered*maxflatimdata;
        end
    else
        
        
        imagesc([IN+(REF)])
        %out=dftregistration(fft2(IN),fft2(REF),10)
        %sprintf('SHIFT X: %f, Y: %f',out(3),out(4))
        out(3)=-1;
        out(4)=0;
        s2r.specCenters=s2r.polyfitwork(s2r.imdim,s2r.fittedCenters,s2r.fittedCol+out(4),2)+out(3);
        %s2r.specWidth=s2r.polyfitwork(s2r.imdim,s2r.fittedWidth,s2r.fittedCol+out(4),3);
    end
end

%s2r.specWidth=3*ones(size(s2r.specWidth));

s2r.extractSpectra;

%s2r.getP2PVariationsAndBlaze;
if s2r.useReference
    flatBlaze=permute(s2r.referenceSpectraValues,[2 1]);
    s2r.flatBlaze(1,:,:)=bsxfun(@rdivide,flatBlaze,max(flatBlaze));
else
    s2r.flatBlaze=ones(size(s2r.spectraValues));
end
%s2r.spectraValues=s2r.flatBlaze;
%s2r.flatBlaze=ones(size(s2r.spectraValues));


%s2r.spectraValues=s2r.spectraValues-bsxfun(@times,s2r.flatBlaze,max(s2r.spectraValues))+3;
%s2r.spectraValues(1,:,2)=s2r.spectraValues(1,:,2)-smooth(s2r.spectraValues(1,:,2),20)'+max(s2r.spectraValues(1,:,2));
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
