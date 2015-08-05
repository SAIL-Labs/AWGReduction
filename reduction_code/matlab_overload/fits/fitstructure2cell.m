function cards=fitstructure2cell(extra)
    extra=rmfield(extra,{'SIMPLE','BITPIX','NAXIS','NAXIS1','NAXIS2','NAXIS3','DATETIME'});
    % convert a structure to fit cards cell array for my fitswrite.
    cards = [fieldnames(extra) struct2cell(extra) repmat({' '},size(fieldnames(extra),1),1)];
    
    % find empty cells
    emptyCells = cellfun('isempty',cards);
    % remove empty cells
    cards(emptyCells) = {' '};
end