function [ C, I ] = fn_find_range( inX, dataFind, roundX )
% returns values and index numbers of an array ('inX') for closest location of the
% numbers in 'dataFind'
% inX = 10.25:.5:30; dataFind = [14 22]; roundX = 1 (empty set is don't
% round. otherwise a numberical will round to that many decimal places)
if nargin < 3; roundX = []; end

origX = inX;
if ~isempty(roundX); 
    inX = round(inX,roundX); 
end

if length(dataFind) == 1
    [~, I] = min(abs(inX-dataFind(ii)));
elseif length(dataFind) == 2
    I = find(inX-dataFind(1) >= 0 & inX-dataFind(2) <= 0);
else
    error('Requires 1 or 2 data input (dataFind');
end
    C = origX(I);
    


