function [ outVal ] = fn_cellstr_operations( func, inCellstr, in_sep )
% function for converting between cell array of strings to a string and
% back again
% [ dimordcell ] = fn_cellstr_operations( 'seperate', dimord )
% [ dimord ] = fn_cellstr_operations( 'join', dimordcell )
%% run checks
if nargin < 2; error('Not enough input'); end
if nargin < 3; in_sep = '_'; end


%% Operations
if strcmpi(func,'seperate')
    if ~ischar(inCellstr)
        error('seperating operation requires character input');
    else
        outVal  = strsplit(inCellstr,in_sep);
    end
elseif strcmpi(func,'join')
    if ~iscell(inCellstr)
        error('joining operation requires cell input');
    else
        outVal = [];
        for ii = 1:length(inCellstr)
            if isnumeric(inCellstr{ii});
                    inCellstr{ii} = num2str(inCellstr{ii});
            end
            if ii < length(inCellstr) 
                cVal = [inCellstr{ii},in_sep];
            else
                cVal = inCellstr{ii};
            end
            outVal = [outVal,cVal]; %#ok
        end
    end
end

