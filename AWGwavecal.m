%AWGwavecal
clc;clear
spectraFiles=dirFilenames('*WAVECAL*1D-spectra.fits');


waves=1670:-10:1100;
waves=waves(4:46);
for i=4:46
    spectra(:,:,i)=fitsread(spectraFiles{i});
end
spectra=spectra(:,:,4:46);
spectra=spectra/max(spectra(:));
%imagesc(sum(spectra,3))


locs=NaN(9,43);
%waves=fliplr(waves);
for ii=1:length(waves)
    
    for o=1:9
        warning('OFF','signal:findpeaks:largeMinPeakHeight')
        [pk,lo]=findpeaks(spectra(o,:,ii)','MinPeakHeight',0.3,'NPeaks',1,'SortStr','descend');
        warning('On','signal:findpeaks:largeMinPeakHeight')
        if ~isempty(pk)
            %pks(o,ii)=pk;
            locs(o,ii)=lo;
        end
    end
    %[cf_, xdatafit(i), c, d, a, gof] = chrislib.fitting.fit_gauss(x',xzoomprofile');
end

f=1;
for o=1:9
    
    [p(f,:,o),S(f,:,o),mu(f,:,o)] = polyfit(locs(o,~isnan(locs(o,:))),waves(find(~isnan(locs(o,:)))),2); %#ok<FNDSB>
    
    wavefit(f,:,o)=polyval(p(f,:,o),1:320,S(f,:,o),mu(f,:,o));
end
plot(squeeze(wavefit),squeeze(sum(spectra,3))')
save('wavecal.mat','wavefit');