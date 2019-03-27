function [  ] = fn_plotbar_with_error( inMeans, inErr, labels )
% groups are on rows
% inMeans = [ 1 2 3; 4 5 6];
% inErr   = [ .1 .2 .3; .4 .5 .6];

if nargin < 3; labels = []; end
if isempty(labels)
    for ii = 1:size(inMeans,1)
        labels{ii} = ['grp',num2str(ii)];
    end
end
addlbl = categorical(labels);
hBar = bar(addlbl,inMeans);
% Get x and y position of bars
ctr = zeros(size(inMeans,1), size(inMeans,2));
ydt = zeros(size(inMeans,1), size(inMeans,2));
for i = 1:size(inMeans,2)
  ctr(:,i) = bsxfun(@plus, hBar(1).XData, [hBar(i).XOffset]');
  ydt(:,i) = hBar(i).YData;
end
disp(ctr); % Prints x positions (double numbers)
hold on;
% Plot error bars on top of individual bar plots
errorbar(ctr, ydt, inErr, 'o', 'marker', 'none', 'linewidth', 2);
hold off;

end

