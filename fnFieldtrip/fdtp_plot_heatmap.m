function [ outCell ] = fdtp_plot_heatmap( pdata, plotLabel, dim2use, dataField, createFigs, path_output_fld  )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
if 1 == 0
    infdtp  = fdtp_stat.d_grand;
    cfg = [];
    cfg.frequency   = [4 7];
    cfg.avgoverfreq = 'yes';
    [pdata] = ft_selectdata(cfg, infdtp);
    
    dim2use = 'freq';
    dataField = 'powspctrm';
    
    plotLabel = 'test plot';
    createFigs = 1;
    path_output_fld = [];
end

if nargin < 2; plotLabel= {}; end
if nargin < 3; dim2use = []; end
if nargin < 4; dataField = []; end
if nargin < 5; createFigs = []; end
if nargin < 6; path_output_fld = []; end

if isempty(path_output_fld); path_output_fld = []; end
% path_output_fld = 'full outout path';
if isempty(dim2use); dim2use = 'freq'; end
% dim2use = 'freq';'time';'chan';
if isempty(dataField); dataField = 'powspctrm'; end
% stat2use = 'stat';'prob'
if isempty(createFigs); createFigs = 1; end
% applyMask = 1; 0; Zero out non significant windows


%% For each stat data structure passed through create a cell array for each frequency processed
if strcmpi(dim2use,'freq')
    yDim.label = 'chan'; yDim.field = 'label'; yDim.round = [];
    xDim.label = 'time'; xDim.field = 'time';  xDim.round = 3;
    flipCell = 1;
end

if strcmpi(dim2use,'time')
    yDim.label = 'chan'; yDim.field = 'label'; yDim.round = [];
    xDim.label = 'freq'; xDim.field = 'freq';  xDim.round = 1;
    flipCell = 0;
end

if strcmpi(dim2use,'chan')
    yDim.label = 'freq'; yDim.field = 'freq'; yDim.round = 1;
    xDim.label = 'time'; xDim.field = 'time'; xDim.round = 3;
    flipCell = 1;
end

%% Find which dimension index we want
[ dimordcell ] = fn_cellstr_operations( 'seperate', pdata.dimord );
dimIndex = find(ismember(dimordcell,dim2use));
field2use = dim2use;
% Channels are special, they use a different variable than the dimension
% name
if strcmpi(dim2use,'chan'); field2use = 'label';end

% set plot name
if ~isempty(plotLabel)
    usr_label = plotLabel;
else
    usr_label = 'temp_label';
end

for ii = 1:length(pdata.(field2use))
    tmp_data = fn_matrix_dim_select( pdata.(dataField), ii, dimIndex, 1 );
    
    % Format label
    if isnumeric(pdata.(field2use)(ii))
        field_label = num2str(round(pdata.(field2use)(ii),1));
    elseif iscell(pdata.(field2use)(ii))
        field_label = pdata.(field2use){ii};
    end
    % Make label
    tmp_label = horzcat(usr_label,['(',dim2use,' ',field_label,')field(',dataField,')']);
    
    %Format Y axis
    if size(pdata.(yDim.field),1) > size(pdata.(yDim.field),2)
        yDim.values = pdata.(yDim.field)';
    else
        yDim.values = pdata.(yDim.field);
    end
    if ~isempty(yDim.round); yDim.values = round(yDim.values,yDim.round);end
    if isnumeric(yDim.values);  yDim.values = num2cell(yDim.values);end
    yVals = horzcat(tmp_label,yDim.values)';
    
    %format X axis
    if size(pdata.(xDim.field),1) > size(pdata.(xDim.field),2)
        xDim.values = pdata.(xDim.field)';
    else
        xDim.values = pdata.(xDim.field);
    end
    if ~isempty(xDim.round); xDim.values = round(xDim.values,xDim.round);end
    if isnumeric(xDim.values);  xDim.values = num2cell(xDim.values);end
    %disp(size(xDim.values)); disp(size(num2cell(tmp.sigstat)))
    xVals = vertcat(xDim.values,num2cell(tmp_data));
    
    % If we want to flip the axis for only the text output (help full
    % if we want to plot time on the X axis but make a table with time
    % on the rows
    if flipCell == 1
        tmp_valcell = horzcat(yVals,xVals)';
    else
        tmp_valcell = horzcat(yVals,xVals);
    end
    
    %save details for each field
    
    loopSave.valcell{ii} = tmp_valcell;
    loopSave.label{ii} = tmp_label;
    loopSave.data{ii} = tmp_data;
end

%% If we are going to output the figures and text file
if ~isempty(path_output_fld) && ischar(path_output_fld)
    if ~exist(path_output_fld,'dir'); mkdir(path_output_fld);end
end


%% output text file
outCell = vertcat(loopSave.valcell{:});
if ~isempty(path_output_fld)
    ABSpathBase = fullfile(path_output_fld,tmp_label);
    ABSpathFile = [ABSpathBase,'.txt'];
    fn_cell_print( outCell, ABSpathFile);
end

%% Create Figures
if createFigs == 1
    for iDim = 1:length(loopSave.label)
        inTitle = loopSave.label{iDim};
        inData  = loopSave.data{iDim};
        tt = reshape(inData,[1 numel(inData)]);
        
        n_nan = sum(isnan(tt));
        tt1 = tt(~isnan(tt));
        n_zero= sum(tt1 == 0);
        
        if (n_nan + n_zero) ~= length(tt)
            X_label = xDim.label;
            Y_label = yDim.label;
            Z_label = dataField;
            
            if length(yDim.values)> 40
                yyIndx = round(linspace(1,length(yDim.values),40));
                yyVals = yDim.values(yyIndx);
            else
                yyIndx = 1:length(yDim.values);
                yyVals = yDim.values;
            end
            
            if length(xDim.values)> 40
                xxIndx = round(linspace(1,length(xDim.values),30));
                xxVals = xDim.values(xxIndx);
            else
                xxIndx = 1:length(xDim.values);
                xxVals = xDim.values;
            end
            
            Y_ticks = vertcat(num2cell(yyIndx),yyVals);
            X_ticks = vertcat(num2cell(xxIndx),xxVals);
            [f1, ~ ]  = fn_plot_heat_map( inData, inTitle, X_label, Y_label, Z_label, X_ticks, Y_ticks  );
            
            if ~isempty(path_output_fld)
                disp('printing')
                path_output_file = fullfile(path_output_fld,[inTitle,'.fig']);
                savefig(f1,path_output_file,'compact');
                F = getframe(f1);
                imwrite(F.cdata, fullfile(path_output_fld,[inTitle,'.png']));
                close(f1);
            end
        else
            disp('All input values are Zero')
        end
    end
end




