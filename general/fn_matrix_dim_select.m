function [ outD ] = fn_matrix_dim_select( inD, indx, dim, squeezeD )
% Function will take a data matrix and return all the values based on a
% spesifc dimension and index number 
% inD  = inData;
% indx = 1;
% dim  = 4;

if nargin < 4; squeezeD = 1; end

if size(indx,1) > size(indx,2); indx = indx';end
if size(indx,1) > 1; error(['Must be a numeric array 1 x N. Current dimensions: ,' num2str(size(indx))]); end
%% create indexing string
e1 = cell(1,length(size(inD)));
for iDi = 1:length(size(inD))
    e1{iDi} = ':';
    if iDi == dim; e1{iDi} = horzcat('[',num2str(indx),']'); end
end
tmpStr = sprintf('%s,',e1{:});
indxStr = horzcat('inD(',tmpStr(1:end-1),')');

%% evaluate and reduce to data dimensions
outD = eval(indxStr);
if squeezeD == 1; outD = squeeze(outD); end