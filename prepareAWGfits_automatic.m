% function prepareAWGfits_automatic(shouldForceAll,shouldDeStripe,shouldSigmaClip)
%     if nargin==0
clc;clear
        shouldForceAll=true;
        shouldDeStripe=false;
        shouldSigmaClip=true;
%     elseif nargin==3
%     else
%         error('prepareAWGfits_automatic:WrongNummberOfInputs',...
%             'Either provide no inputs, or specify logicals for shouldForceAll, shouldDestripe, shouldSigmaClip. Default is false true true.')
%     end
%     %assertWarning(shouldForceAll,'Files will be overwritten.')
    
    reduced_folder='reduced_chris';
    
    %% get and parse filenames of all fits
    allfiles=dirFilenames('*.fits');
    
    %allfiles=cellfun(@(x) x(1:end-5),allfiles,'UniformOutput',false);
    
    for i=1:length(allfiles)
        header(i)=fitsheader(allfiles{i});
        exposure(i)=header(i).T_INT;
        object{i}=header(i).TARGNAME;
        type{i}=header(i).DATATYPE;
    end
    
%     splitfilenames=regexp(allfiles, '_', 'split');
%     for i=1:length(splitfilenames)
%         splits(i,:)=splitfilenames{i}(~cellfun(@isempty,(splitfilenames{i})));
%     end
%     allfiles=dirFilenames('*.fits'); % add .fits back
%     assert(~isempty(allfiles),'no .fits files found');
%     
%     cellRows = mat2cell(splits(:,1:2),ones(size(splits(:,1:2),1),1),size(splits(:,1:2),2));
%     objects = cellfun(@(x) strjoin(x,'-'),cellRows,'uni',0);
% 
%     exposure=cellfun(@str2double,splits(:,5));
%     cube=splits(:,4);
%     type=splits(:,3);
%     
%     %     objects=(cellfun(@(x) x(1:8),allfiles,'UniformOutput',false));
%     %     exposure=cell2mat(cellfun(@(x) str2double(x(10:16)),allfiles,'UniformOutput',false));
%     %     cube=cellfun(@(x) x(18:19),allfiles,'UniformOutput',false);
%     %     type=cellfun(@(x) x(21:end-5),allfiles,'UniformOutput',false);
    
    %object_type=cellfun(@(x,y) [x '_' y],objects,type,'UniformOutput',0);
    
    % group into unique groups by object
    uniqueobjects=unique(object);
    darkobjects=~cellfun('isempty',strfind(lower(object),'dark')); % ~cellfun('isempty',strfind(lower(type),'cals')) &
    uniquedarks=unique(exposure(darkobjects));
    
    %%
    if ~isdir(fullfile(pwd,reduced_folder))
        mkdir(reduced_folder)
        %addpath(fullfile(pwd,'reduced'))
    end
    
    %% load mask
    if shouldDeStripe
        try
            load(fullfile(reduced_folder, 'mask_full.mat'))
        catch err
            flatfile='End_Cals_superK_500_0050000_01.fits';
            imdata=mean(fitsread(flatfile),3);
            imagesc(log10(imdata))
            [xi, yi]=getpts;
            BW1 = roipoly(imdata,xi,yi);
            save(fullfile(reduced_folder, 'mask_full.mat'),'BW1')
        end
        mask=BW1;
    end
    
    %% make master darks - combine all equal exposur dark frames in current folder.
    for i=1:length(uniquedarks)
        logicalListOfLikeDarks=uniquedarks(i)==exposure & darkobjects;
        darkFilenames=allfiles(logicalListOfLikeDarks);
        
        try
            dark.(['d' num2str(uniquedarks(i))])=fitsread(fullfile(reduced_folder, [num2str(uniquedarks(i)) '_masterdark.fit']));
            assert(~shouldForceAll,'Force flag set.')
        catch err
            
            for j=1:length(darkFilenames)
                header=fitsheader(darkFilenames{j});
                header.DISPAXIS=2;
                %header.GAIN=1;
                %header.READNOIS=100;
                header.EXPOSURE=uniquedarks/1e6;
                
                imagecube=fitsread(darkFilenames{j});
                
                darkImdata(:,:,j)=mean(imagecube,3); % combine image cube
            end
            
            masterdark=mean(darkImdata,3); % combine all image cubes
            dark.(['d' num2str(uniquedarks(i))])=masterdark;
            oldheader=fitstructure2cell(header);
            fitswrite(masterdark,fullfile(reduced_folder,[num2str(uniquedarks(i)) '_masterdark.fit']),oldheader(7:end,:))
        end
    end
    
    clear imagecube darkImdata header darkFilenames logicalListOfLikeDarks i j splits masterdark err
    
    %% dark subtract all other frames and combine unique objects with unique exposures
    fullframeflat=1; % for later upgrades
    
    for i=1:length(uniqueobjects)
        logicalListOfLikeObjects=strcmpi(uniqueobjects{i},object) & ~darkobjects;
        
        %cubeindex=str2double(cube(logicalListOfLikeObjects));
        
        uniqueexposures=unique(exposure(logicalListOfLikeObjects));
        
        for exp=1:length(uniqueexposures)
            
            logicalListOfLikeObjectsAndExposures=uniqueexposures(exp)==exposure & ~darkobjects & logicalListOfLikeObjects;
            lightFilenames=allfiles(logicalListOfLikeObjectsAndExposures);
            
            try
                fitsread(fullfile(pwd,reduced_folder,[objects{find(logicalListOfLikeObjectsAndExposures,1,'first')} '_' num2str(uniqueexposures(exp)) '_coadded_' type{find(logicalListOfLikeObjectsAndExposures,1,'first')} '_RED.fit']));
                assert(~shouldForceAll,'Force flag set.')
                error
            catch err
                
                for file=1:length(lightFilenames)
                    [~,name,~] = fileparts(lightFilenames{file});
                    
                    header=fitsheader(lightFilenames{file});
                    header.DISPAXIS=2;
                    header.GAIN=1;
                    header.READNOIS=std2(dark.(['d' num2str(uniqueexposures(exp))]));
                    header.EXPOSURE=uniqueexposures(exp);
                    imagecube=fitsread(lightFilenames{file});
                    
                    imagecube_darksub=bsxfun(@minus,imagecube,dark.(['d' num2str(uniqueexposures(exp))])); % subtract dark from each frame
                    imagecube_darksub_fullflat=bsxfun(@rdivide,imagecube_darksub,fullframeflat);
                    
                    % destrip
                    if shouldDeStripe
                        imraw=imagecube_darksub_fullflat;
                        imraw(repmat(mask,[1 1 100]))=NaN;
                        colmed=nanmedian(imraw,1);
                        imagecube_darksub_fullflat=bsxfun(@minus,imagecube_darksub_fullflat,colmed);
                    end
                    
                    if shouldSigmaClip
                        badpixels=bsxfun(@gt,abs(bsxfun(@minus,imagecube_darksub_fullflat,mean(imagecube_darksub_fullflat,3))),4*std(imagecube_darksub_fullflat,1,3));
                        sum(badpixels(:))
                        imagecube_darksub_fullflat(badpixels)=NaN;
                        parfor j=1:size(badpixels,3)
                            imagecube_darksub_fullflat(:,:,j)=inpaint_nans(imagecube_darksub_fullflat(:,:,j));
                        end
                    end
                    
                    % combine cube
                    imdata(:,:,file)=sum(imagecube_darksub_fullflat,3); % combine dark subtracted image cube
                    %imagescubesize(file)=size(imagecube,3); % save image cube size for noise estimate
                    headerold=fitstructure2cell(header);
                    fitswrite(imdata(:,:,file),fullfile(pwd,reduced_folder, [name '_' header.DATATYPE '_' num2str(header.T_INT) '_' header.TARGNAME '_RED.fit']),headerold(7:end,:));
                    
                    %figure('Name',lightFilenames{i}(23:end-4));imagesc(imdata(:,:,i))
                    %set(gca,'CLim',[0 2^14*100])
                end
                if size(imdata,3)>1
                    fitswrite(sum(imdata,3),fullfile(pwd,reduced_folder,[type{find(logicalListOfLikeObjectsAndExposures,1,'first')} '_' num2str(uniqueexposures(exp)) '_coadded_' object{find(logicalListOfLikeObjectsAndExposures,1,'first')} '_RED.fit']),headerold(7:end,:))
                end
                clear imdata imagescubesize
            end
        end
    end