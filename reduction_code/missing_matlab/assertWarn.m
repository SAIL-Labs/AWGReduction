function assertWarn(condition,varargin)
% ASSERTWARN Generate warning when condition is violated, simialr to ASSERT. Same inputs used for
% normal WARNING call should work, ie:
%
% assertWarn(expression,'message_id', 'message', a1, a2, ..., an)
% assertWarn(expression,'message')
% assertWarn(expression,'message', a1, a2,...)
% assertWarn(expression,'message_id', 'message')
% assertWarn(expression,'message_id', 'message', a1, a2, ..., an)
%
% For example: assertWarn(1, 'assertWarn:test', 'tested on %s',datestr(date))
%
% Copyright (c) 2014, Chris Betters

if condition % reveerse logic
    if nargin==2
        warning(varargin{1})
    elseif nargin==3
        warning(varargin{1}, varargin{2})
    elseif nargin>3
        for i=1:length(varargin)
            % make 
            if isnumeric(varargin{i})
                varargin{i}=num2str(varargin{i}); % eval turns the string back into number
            elseif ischar(varargin{i})
                varargin{i}=['''' varargin{i} ''''];
            end
        end
        eval(['warning(' strjoin(varargin,', ') ')'])
    else
        warning('assertWarn:dangerWillRobinson','Condition True')
    end
end