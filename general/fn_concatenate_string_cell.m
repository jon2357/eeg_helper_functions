function [ outList ] = fn_concatenate_string_cell( useTrials, dim )
%function takes a 2 dimentional cell array with string, and concatenates
%across a spesific dimension. 

if nargin < 2; dim = 1; end

if dim == 2; useTrials = useTrials';end

outList = cell(1,size(useTrials,1));
for iF = 1:length(outList)
    outList{iF} = horzcat(useTrials{iF,:});
end

if dim == 1; outList = outList'; end
end

