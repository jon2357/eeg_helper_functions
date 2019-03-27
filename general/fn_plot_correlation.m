function [ f1,detCell, addstrCell ] = fn_plot_correlation( incfg, incell )
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here
if 1 == 0
    incell = {};
    incell{1}.x = [ 1 2 3 4 5 6 7];
    incell{1}.y = [ 1 0 3 4 5 6 7];
    incell{1}.pointC = 'bd';
    incell{1}.trendC = 'b';
    incell{1}.lbl    = 'ya';
    incell{1}.sublist= [];
    
    incell{2}.x = [ 1 2 3 4 0 6 7];
    incell{2}.y = fliplr([ 1 2 3 4 5 6 7]);
    incell{2}.pointC = 'g';
    incell{2}.trendC = 'g';
    incell{2}.lbl    = 'oa';
    incell{2}.sublist= {'1','2','3','4','0','6','7'};
    
    incfg = [];
end

if ~isfield(incfg,'createNew'); incfg.createNew = 'yes'; end
if ~isfield(incfg,'filename');  incfg.filename = 'test'; end
if ~isfield(incfg,'addtext');   incfg.addtext = []; end
if ~isfield(incfg,'title');     incfg.title = []; end

if ~isfield(incfg,'xlabel');    incfg.xlabel = 'xAxis'; end
if ~isfield(incfg,'xlim');      incfg.xlim   = []; end

if ~isfield(incfg,'ylabel');    incfg.ylabel = 'yAxis'; end
if ~isfield(incfg,'ylim');      incfg.ylim   = []; end

if ~isfield(incfg,'datawidth'); incfg.datawidth  = 300; end
if ~isfield(incfg,'trendwidth');incfg.trendwidth = 20; end

if ~isfield(incfg,'textsize');  incfg.textsize   = 40; end

if ~isfield(incfg,'add_allcorrelation'); incfg.add_allcorrelation = 0; end

if isempty(incfg.title)
    incfg.title = incfg.filename;
end

%% Format text and plot Defaults
formated_title=strrep(incfg.title,'_','\_');

%% plot
if strcmpi(incfg.createNew,'yes')
    f1 = figure('Name',incfg.filename,'NumberTitle','off','units','inches','outerposition',[0 0 10 10]);
else
    f1 = [];
end

hold on %keep everything on the same axis

corrVals = NaN(length(incell),3);
detCell = cell(length(incell),5);
alldataX = cell(1,length(incell));
alldataY = cell(1,length(incell));
for ii = 1:length(incell)
    if ~isfield(incell{ii},'trendC'); incell{ii}.trendC = []; end
    if ~isfield(incell{ii},'pointC'); incell{ii}.pointC = []; end
    if ~isfield(incell{ii},'lbl'); incell{ii}.lbl = ['g',num2str(ii)]; end
    
    inX = incell{ii}.x;
    inY = incell{ii}.y;
    inC = incell{ii}.pointC;
    inT = incell{ii}.trendC;
    inlbl = incell{ii}.lbl;
    
    if isempty(inC); inC = 'k'; end
    
    % Plot scatter points
    scatter(inX,inY,incfg.datawidth,inC,'filled')
    
    
    % plot Line
    if ~isempty(inT)
        [corR,corP] = corr(inX',inY'); % Calculate correlation with standard matlab settings (Pearson)
        myfit=polyfit(inX,inY,1);      % Calculate linear polynomial fit
        yHat=myfit(1)*inX+myfit(2);    % Calcualte predicted values
        plot(inX,yHat,inT,'LineWidth',incfg.trendwidth) %plot predicted values
        corrVals(ii,:) = [length(inX),round(corR,3),round(corP,3)];
        detCell(ii,:)  = horzcat({inlbl},{inC},corrVals(ii,1),corrVals(ii,2),corrVals(ii,3));
    else
        detCell(ii,:) = horzcat({inlbl},{inC},{' '},{' '},{' '});
    end
    
    % Data log
    alldataX{ii} = incell{ii}.x;
    alldataY{ii} = incell{ii}.y;
end

if incfg.add_allcorrelation == 1
    inX = horzcat(alldataX{:});
    inY = horzcat(alldataY{:});
    inC = 'k';
    inT = 'k';
    inlbl = 'all-data';
    
    [corR,corP] = corr(inX',inY'); % Calculate correlation with standard matlab settings (Pearson)
    myfit=polyfit(inX,inY,1);      % Calculate linear polynomial fit
    yHat=myfit(1)*inX+myfit(2);    % Calcualte predicted values
    plot(inX,yHat,inT,'LineWidth',incfg.trendwidth) %plot predicted values
    corrVals(size(corrVals,1)+1,:) = [length(inX),round(corR,3),round(corP,3)];
    detCell(size(detCell,1)+1,:)  = horzcat({inlbl},{inC},corrVals(end,1),corrVals(end,2),corrVals(end,3));
end

%% Add labeling
title(formated_title);
% Axis Labels
xlabel(incfg.xlabel)
ylabel(incfg.ylabel)
% Axis limits
if ~isempty(incfg.xlim) && length(incfg.xlim) == 2; xlim(incfg.xlim); end
if ~isempty(incfg.ylim) && length(incfg.ylim) == 2
    ylim(incfg.ylim);
else
    yEnds = ylim;
    incY = range(yEnds)*.05;
    ylim([yEnds(1),yEnds(2)+incY])
end

set(gca,'FontSize',incfg.textsize)
%% Add subject labels
xEnds = xlim; dx = range(xEnds)*.01;
yEnds = ylim; dy = range(yEnds)*.01;
for ii = 1:length(incell)
    if ~isfield(incell{ii},'sublist'); incell{ii}.sublist = []; end
    if ~isempty(incell{ii}.sublist) && length(incell{ii}.sublist) == length(inX)
	inX = incell{ii}.x;
    inY = incell{ii}.y;
        text(inX+dx, inY+dy, incell{ii}.sublist);
    end
end

%% Add correlation and group info
addstrCell = cell(1,size(detCell,1));
for ii = 1:size(detCell,1)
    addstrCell{ii} = [detCell{ii,1},'(',num2str(detCell{ii,3}),') c(',detCell{ii,2},')'...
        ' [r(',num2str(detCell{ii,3}-2),')=',num2str(detCell{ii,4}),', p=',num2str(detCell{ii,5}),']'];
end
addstrCell = horzcat(addstrCell,incfg.addtext);
textbp(addstrCell)

hold off
end

