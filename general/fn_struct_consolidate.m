function [ mod_struct ] = fn_struct_consolidate( inStruct, fields2avg )
%This function will take a 1 x N data structure and consolidate it down to
%a single data structure, fields that are identical across the array will
%only show single values, those that differ across the array will become
%data arrays of the appropriate data type (cell array of strings, numerical
%array for single numbers, for fields that contain numerical arrays the will
%return in a cell array)

% fields2avg = cell array of field anmes that can be averaged over if they
% are a numeric array. adds a field with the prefix 'avg_' followed by the
% field name

if  1 == 0
    inStruct = GP.data_epochs;
end
if nargin < 2; fields2avg = {}; end

mod_struct = [];
all_fields = fieldnames(inStruct);
    for iC = 1:length(all_fields)
        field_cell = {inStruct.(all_fields{iC})};
        if length(field_cell) == 1 || isequal(field_cell{:})
            mod_struct.(all_fields{iC}) = field_cell{1};
        elseif sum(cellfun(@isnumeric, field_cell)) == length(field_cell)
            if sum(cellfun(@length, field_cell)) == length(field_cell)
                mod_struct.(all_fields{iC}) = [field_cell{:}];
            else
                mod_struct.(all_fields{iC}) = field_cell(:)';
            end
        else
            mod_struct.(all_fields{iC}) = field_cell(:)';
        end
    end
    
    mod_struct.n = length(inStruct);
    
    if ~isempty(fields2avg)
        for ii = 1:length(fields2avg)
            if isfield(mod_struct,(fields2avg{ii}))
                procData = mod_struct.(fields2avg{ii});
                if isnumeric(procData)
                    avgVal = nanmean(procData);
                    newFieldname = ['avg_',fields2avg{ii}];
                    mod_struct.(newFieldname) = avgVal;
                end
            end
        end
    end
                
end

