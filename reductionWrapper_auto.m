clc; clear; set(0,'DefaultFigureWindowStyle','docked')

    if ~isdir(fullfile(pwd,'PDFs'))
        mkdir(fullfile(pwd,'PDFs'))
    end

coaddedfiles=dirFilenames('*coadded*.fit');

for i=1:length(coaddedfiles)
    [~,name,~] = fileparts(coaddedfiles{i});
    if ~isdir(fullfile(pwd,'reduced'))
        mkdir(fullfile('PDFs',name))
    end
    
    %% Init
    s2r = misprint(name,'reference','Endcals__2000000_coadded_Halogenf_RED',...
        'plotAlot',true,'numOfOrders',1,'numOfFibers',9,...
        'forceTrace',false,'forceExtract',true,...
        'forceDefineMaskEdge',false,'needsMask',true,...
        'treatFibresAsOrders',true,...
        'clipping',[0 0 0 0],...
        'peakcut',0.06,...
        'usecurrentfolderonly',true,'OXmethod','MPDoptimalExt',...
        'numTraceCol',20,'firstCol',10,'lastCol',285,...
        'parallel',false);
    
    %% attempted to remove hot pixels (no perfect)
%     imdatafilt=medfilt2(s2r.imdata,[1 4]);
%     diffimage=s2r.imdata-imdatafilt;
%     badpixel=abs(diffimage-mean2(diffimage)) > std2(diffimage)*5;
%     sum(badpixel(:))
%     s2r.imdata(badpixel)=NaN;
%     s2r.imdata(s2r.imdata<0)=NaN;
%     s2r.imdata=inpaint_nans(s2r.imdata,3);
%     
    s2r.imdata=s2r.imdata-median(s2r.imdata(:)); % important, must remove DC offset
    %s2r.imdata(s2r.imdata<0)=0;
    
    imagesc(s2r.imdata)
    
    % set mask to clip incomplete orders
    try
        load('mask_full.mat')
    catch err
        imagesc(log10(s2r.imdata))
        [xi, yi]=getpts;
        BW1 = roipoly(s2r.imdata,xi,yi);
        save('mask_full.mat','BW1')
    end
    s2r.mask=BW1;
    
    % trace spectra (or load reference)
    s2r.traceSpectra;
    
    
    % check allingment
    out=dftregistration(fft2(s2r.imdata/max2(s2r.imdata)),fft2(s2r.flatImdata/max2(s2r.flatImdata)),100)'
    
    if s2r.useReference
        
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
    plot(1:320*9,reshape(s2r.spectraValues,[1 320*9]))%,...
    figure(11)
    h=plot(1:320*9,reshape(s2r.spectraValues./s2r.flatBlaze,[1 320*9]));
    ylim([0 max(h.YData(100:200))*2])
    
%     1:320*9,reshape(s2r.spectraValues./s2r.flatBlaze,[1 320*9]),...
%         1:320*9,reshape(s2r.flatBlaze,[1 320*9])*max(s2r.spectraValues(:)))
%     ylim([0 mean(s2r.spectraValues(:))*4])
    
    legend({'raw spectra', 'flate divided spectra', 'flat spectra (rescalled)'})
    
    for i=1:9
        save2pdf(fullfile('PDFs',name,[num2str(i) '.pdf']),i,150)
    end
    save2pdf(fullfile('PDFs',name,'all_raw.pdf'),10,150)
    save2pdf(fullfile('PDFs',name,'all_flat.pdf'),11,150)
end