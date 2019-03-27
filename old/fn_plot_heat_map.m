function [f1, h ] = fn_plot_heat_map( inData, inTitle, X_label, Y_label, Z_label, X_ticks, Y_ticks, createNew  )
% inData = N x M (2 dimensional matrix (rows are Y axis, Columns are X axis
% inTitle, X_label, Y_label, Z_label are string values that add labels
% X_ticks, Y_ticks are 2 x N cell array with the format of:
%       - Top Row: index numbers on where to place the labels
%       - Bottom Row: labels to use

if nargin < 2; inTitle = []; end
if nargin < 3; X_label = []; end
if nargin < 4; Y_label = []; end
if nargin < 5; Z_label = []; end
if nargin < 6; X_ticks = []; end
if nargin < 7; Y_ticks = []; end
if nargin < 8; createNew = []; end

if isempty(inTitle); inTitle = 'temp title';end
if isempty(X_label); X_label = 'X axis';end
if isempty(Y_label); Y_label = 'Y axis';end
if isempty(Z_label); Z_label = 'Z axis';end

if isempty(X_ticks); X_ticks = {};end
if isempty(Y_ticks); Y_ticks = {};end
if isempty(createNew); createNew = 1; end

inData(inData == 0) = NaN;
topVal = nanmean(abs(reshape(inData,[1,numel(inData)])))...
    + (1 * nanstd(abs(reshape(inData,[1,numel(inData)]))));

if isnan(topVal) || topVal < .05; topVal = .05; end

%undercase is read as a subscript in matlab (convert all under case into 
% spaces for the title)
inTitle = strrep(inTitle,'_',' '); 

if createNew
    f1 = figure('Name',inTitle,'NumberTitle','off','units','inches',...
        'outerposition',[0 0 20 10]);
end
h = imagesc(inData,[-topVal topVal]);
set(h, 'AlphaData', ~isnan(inData)); % clear any color from NaN values
title(inTitle);
c = colorbar; c.Label.String = Z_label;

ax = gca;
xlabel(X_label);
if ~isempty(X_ticks)
    ax.XTick = [X_ticks{1,:}];
    ax.XTickLabel = X_ticks(2,:);
end
ylabel(Y_label); 
if ~isempty(Y_ticks)
    ax.YTick = [Y_ticks{1,:}];
    ax.YTickLabel = Y_ticks(2,:);
end

if ~createNew
    f1 = gcf;
end
end

