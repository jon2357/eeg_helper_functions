function [ dArray ] = fn_space_values( sType, minVal, maxVal, numVal, roundVal )
%Function returns numericalarray with desired spacing
% sType = 'lin', 'log'
% minVal = Number : starting value
% maxVal = Number : stopping value
% roundVal = Number : nuber of decimal places to round to

if nargin < 1; sType = 'lin'; end
if nargin < 2; minVal = 1; end
if nargin < 3; maxVal = 90; end
if nargin < 4; numVal = 5; end
if nargin < 5; roundVal = 1; end

if strcmpi(sType,'lin')
    %this might be good to use the percent change baseline conversion
    dArray = linspace(minVal,maxVal,numVal);
elseif strcmpi(sType,'log') % doensn't work yet
    %this might be good to use a db baseline conversion
    dArray = logspace(minVal,maxVal,numVal);
end

%Round values if requested
if ~isempty(roundVal) && isnumeric(roundVal) && roundVal > 0 
    dArray = round(dArray,roundVal); 
end

end

