function prepareAWGfits(scienceDirString,darkDirString)
    %clc;clear all
    
    if ~isdir(fullfile(pwd,'reduced'))
        mkdir('reduced')
        %addpath(fullfile(pwd,'reduced'))
    end
    
    %flatdarkCubeMat=load('/Users/chrisbetters/Dropbox/postdoc/awg/awg-April9th/xenicsFlats/flat_dk_8000.mat','imagecube');
    %flatCubeMat=load('/Users/chrisbetters/Dropbox/postdoc/awg/awg-April9th/xenicsFlats/sldflat_8000.mat','imagecube');
%     darkDirString='200us_darks.fits';
%     scienceDirString='HeNe_200us.fits';
    
    lightFilenames=dirFilenames(scienceDirString);
    darkFilenames=dirFilenames(darkDirString);
    
    %% make master dark
    [~,name,ext] = fileparts(darkFilenames{1});
    
    switch ext
        case '.mat'
            loadfn=@(filename) loadWrapper(filename);
            savefn=@(data,filename,header) save([filename '.mat'],'masterdark','header');
            headerfn=@(filename) makeheader;
        case '.fits'
            loadfn=@(filename) fitsread(filename);
            savefn=@(data,filename,header) fitswrite(data,[filename '.fit'],header(8:end,:));
            headerfn=@(filename) fitsheader(filename);
        otherwise
            error('Don''t go Here')
    end
    
    try
        loadfn(['reduced/' name '-masterdark' ext])
    catch err
        for i=1:length(darkFilenames)
            header=headerfn(darkFilenames{i});
            header.DISPAXIS=2;
            imagecube=loadfn(darkFilenames{i});
            
            darkImdata(:,:,i)=median(imagecube,3); % median combine image cube
        end
        
        masterdark=median(darkImdata,3); % median combine all image cubes
        
        savefn(masterdark,['reduced/' name '-masterdark'],fitstructure2cell(header))
    end
    
    %% make dark subtracted light frame, and combine frames
    finalflat=1;
    for i=1:length(lightFilenames)
        [~,name,~] = fileparts(lightFilenames{i});
        
        header=headerfn(lightFilenames{i});
        header.DISPAXIS=2;
        imagecube=loadfn(lightFilenames{i});
        
        imagecube_darksub=bsxfun(@minus,imagecube,masterdark); % subtract dark from each frame
        imagecube_darksub_fullflat=bsxfun(@rdivide,imagecube_darksub,finalflat);
        
        badpixels=bsxfun(@gt,abs(bsxfun(@minus,imagecube_darksub_fullflat,mean(imagecube_darksub_fullflat,3))),2*std(imagecube_darksub_fullflat,1,3));
        sum(badpixels(:));
        imagecube_darksub_fullflat(badpixels)=NaN;
        for j=1:size(badpixels,3)
            imagecube_darksub_fullflat(:,:,j)=inpaint_nans(imagecube_darksub_fullflat(:,:,j));
        end
        
        imdata(:,:,i)=sum(imagecube_darksub_fullflat,3); % combine dark subtracted and flattened image cube
        imagescubesize(i)=size(imagecube,3); % save image cube size for noise estimate
        savefn(imdata(:,:,i),[pwd '/reduced/' name '-RED'],fitstructure2cell(header));
        
        %figure('Name',lightFilenames{i}(23:end-4));imagesc(imdata(:,:,i))
        %set(gca,'CLim',[0 2^14*100])
    end

    %%pixelsToReplace = abs(imdata - mean(imdata,3)) > (5 * std(imdata,1,3))
    %outputImage(pixelsToReplace) = whatever you want them to be
    
    return
    %%
    imdata_mean=sum(imdata,3);
    % %imdata_std=std(imdata,1,3);
    %
    % imstdplus=repmat(imdata_mean+imdata_std*4,[1 1 length(lightFilenames)]);
    % imstdminus=repmat(imdata_mean-imdata_std*4,[1 1 length(lightFilenames)]);
    %
    % badpixl=logical(sum(imdata>imstdplus,3)) | logical(sum(imdata<imstdminus,3));
    %
    % imdata_mean(badpixl)=NaN;
    %
    % imdata_mean=inpaint_nans(imdata_mean);
    
    imdata_mean(imdata_mean<0)=0;
    for i=1:length(lightFilenames)
        figure('Name',lightFilenames{i}(23:end-4));
        
        subplot(1,2,1)
        set(gca,'CLim',[0 2^14*100])
        imagesc(imdata(:,:,i))
        
        subplot(1,2,2)
        imagesc(imdata_mean-imdata(:,:,i))
        %set(gca,'CLim',[0 2^14*100])
    end
    
    
    
    
    % header.DISPAXIS=2;
    % header.READNOIS=std(masterdark(:)); % readnoise from masterdark
    % header.GAIN=1;
    % header.EXPOSURE=10e-6;
    
    %fitswrite(imdata_mean,[pwd '/reduced/' lightFilenames{1}(1:end-4) '-comb.fit'],fitstructure2cell(header));
end

function imdata=loadWrapper(matfilename)
    matpayload=load('matfilename',imagecube);
    imdata=matpayload.imagecube;
end

function header=makeheader
        header.DISPAXIS=2;
    header.READNOIS=std(masterdark(:)); % readnoise from masterdark
    header.GAIN=1;
    header.EXPOSURE=10e-6;
end