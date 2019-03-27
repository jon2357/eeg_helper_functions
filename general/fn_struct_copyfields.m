function [ outStruct ] = fn_struct_copyfields( inStruct )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if length(inStruct) > 1; inStruct = inStruct(1);end

cpfields = fieldnames(inStruct);

for ii = 1:length(cpfields)
    chkField = cpfields{ii};
    if isnumeric(inStruct.(chkField))
        if length(inStruct.(chkField)) == 1
            outStruct.(chkField) = NaN;
        else
            outStruct.(chkField) = [];
        end
    elseif ischar(inStruct.(chkField))
        outStruct.(chkField) = '';
    elseif iscell(inStruct.(chkField))
        outStruct.(chkField) = {};
    elseif isstruct(inStruct.(chkField))
        outStruct.(chkField) = [];
    end
end

end

