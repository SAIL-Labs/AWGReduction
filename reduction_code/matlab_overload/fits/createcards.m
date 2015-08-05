classdef createcards < handle
    % CREATECARDS is class to simply construction of headers for my customised
    % fitswrite.m
    % takes keyword, value,comment and comment inputs and converts them to new row in a cell
    % array. i.e.
    % {keyword}, {value},{comment}
    %
    % example use:
    %
    % HDU=createcards('EXPTIME','10','exposure time in seconds');
    % HDU.addcard('CREATOR','Matlab','program the created file');
    % fitswrite(imdata,filename,HDU.cards,...)
    
    properties
        % cell array of keyword, value,comment
        cards=[];
    end
    
    methods
        function this=createcards(keyword,value,comment)
            % constructor. creates a 1x3 cell array of keyword, value,comment
            this.cards=[{keyword}, {value},{comment}];
        end

        function addcard(this,keyword,value,comment)
            % adds new card (row) of keyword, value,comment
            this.cards=[this.cards; [{keyword}, {value},{comment}]];
        end    
    end  
end

