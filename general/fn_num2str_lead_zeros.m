function [ outCell ] = fn_num2str_lead_zeros( inArray, numberOfdigits )
%Adds in leading zeros to a number / an array of numbers
% inArray = 1 x N integer array 
% numberOfdigits = Integer with the total number of digits to out put
% Example
% inArray = [ 1 20]; numberOfdigits = 3; 
%  wil output: outCell = {'001', '020'};

if nargin < 2; numberOfdigits = 4; end

outCell = cell(1,length(inArray));
for i = 1:length(inArray)
    epochNum = inArray(i);
    nDigit = numel(num2str(epochNum));
    addZeros = numberOfdigits-nDigit;
    zeroStr = '';
    if addZeros > 0
        for ii = 1:addZeros
            zeroStr = [zeroStr,'0'];
        end
    end
    addval = [zeroStr,num2str(epochNum)];
    outCell{i} = addval;
end
