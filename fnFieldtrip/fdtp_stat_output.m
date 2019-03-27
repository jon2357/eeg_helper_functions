function [ outStat ] = fdtp_stat_output( stat, stat_labels, dim2use, stat2use, applyMask, createFigs, path_output_fld )



if nargin < 2; stat_labels= {}; end
if nargin < 3; dim2use = []; end
if nargin < 4; stat2use = []; end
if nargin < 5; applyMask = []; end
if nargin < 6; createFigs = []; end
if nargin < 7; path_output_fld = []; end

if isempty(path_output_fld); path_output_fld = []; end
% path_output_fld = 'full outout path';
if isempty(dim2use); dim2use = 'freq'; end
% dim2use = 'freq';'time';'chan';
if isempty(stat2use); stat2use = 'stat'; end
% stat2use = 'stat';'prob'
if isempty(applyMask); applyMask = 1; end
% applyMask = 1; 0; Zero out non significant windows

if isempty(createFigs); createFigs = 1; end
% applyMask = 1; 0; Zero out non significant windows

if ischar(stat_labels); stat_labels = {stat_labels}; end
%% For each stat data structure passed through create a cell array for each frequency processed
if strcmpi(dim2use,'freq')
    yDim.label = 'chan'; yDim.field = 'label'; yDim.round = [];
    xDim.label = 'time'; xDim.field = 'time';  xDim.round = 2;
    flipCell = 1; 
end

if strcmpi(dim2use,'time')
    yDim.label = 'chan'; yDim.field = 'label'; yDim.round = [];
    xDim.label = 'freq'; xDim.field = 'freq';  xDim.round = 1;
    flipCell = 0; 
end

if strcmpi(dim2use,'chan')
    yDim.label = 'freq'; yDim.field = 'freq'; yDim.round = 1;
    xDim.label = 'time'; xDim.field = 'time'; xDim.round = 2;
    flipCell = 1;
end

for iStat = 1:length(stat)
    inStat = stat(iStat);
    
    [ dimordcell ] = fn_cellstr_operations( 'seperate', inStat.dimord );
    dimIndex = find(ismember(dimordcell,dim2use));
    
    field2use = dim2use;
    if strcmpi(dim2use,'chan'); field2use = 'label';end
    
    if ~isempty(stat_labels)
        inStat.usr.label = stat_labels{iStat};
    elseif isfield(inStat.cfg,'usr') &&...
            isfield(inStat.cfg.usr,'label')
        inStat.usr.label = inStat.cfg.usr.label;
    else
        inStat.usr.label = ['temp(c',num2str(iStat),')'];
    end
    
    for ii = 1:length(inStat.(field2use))
        
        tmp.prob = fn_matrix_dim_select( inStat.prob, ii, dimIndex, 1 );
        tmp.mask = fn_matrix_dim_select( inStat.mask, ii, dimIndex, 1 );
        tmp.stat = fn_matrix_dim_select( inStat.stat, ii, dimIndex, 1 );
        tmp.(stat2use) = fn_matrix_dim_select( inStat.(stat2use), ii, dimIndex, 1 );
        
        if applyMask == 1
            tmp.sigstat = round(tmp.(stat2use) .* tmp.mask,3);
        else
            tmp.sigstat = round(tmp.(stat2use),3);
        end
        
        % Format label
        if isnumeric(inStat.(field2use)(ii))
            field_label = num2str(round(inStat.(field2use)(ii),1));
        elseif iscell(inStat.(field2use)(ii))
            field_label = inStat.(field2use){ii};
        end
        
        
        
        mL = {yDim.field,xDim.field};
        addl = cell(1,2);
        for i = 1:length(mL)
            if strcmp(mL{i},'label')
                addl{i} = ['(c',num2str(length(inStat.(mL{i}))),')'];
            else
                addl{i} = ['(',mL{i}(1),num2str(length(inStat.(mL{i})))...
                    'm',num2str(round(nanmean(inStat.(mL{i})),2)),')'];
            end
        end
        
        tmp.label = horzcat(inStat.usr.label,...
            ['(',dim2use,'_',field_label,')mc(',...
            inStat.cfg.correctm,')',stat2use,'_',horzcat(addl{:})]);
        
        %Format Y axis
        if size(inStat.(yDim.field),1) > size(inStat.(yDim.field),2)
            yDim.values = inStat.(yDim.field)';
        else
            yDim.values = inStat.(yDim.field);
        end
        if ~isempty(yDim.round); yDim.values = round(yDim.values,yDim.round);end
        if isnumeric(yDim.values);  yDim.values = num2cell(yDim.values);end
        yVals = horzcat(tmp.label,yDim.values)';
        
        %format X axis
        if size(inStat.(xDim.field),1) > size(inStat.(xDim.field),2)
            xDim.values = inStat.(xDim.field)';
        else
            xDim.values = inStat.(xDim.field);
        end
        if ~isempty(xDim.round); xDim.values = round(xDim.values,xDim.round);end
        if isnumeric(xDim.values);  xDim.values = num2cell(xDim.values);end
        %disp(size(xDim.values)); disp(size(num2cell(tmp.sigstat)))
        xVals = vertcat(xDim.values,num2cell(tmp.sigstat));
        
        % If we want to flip the axis for only the text output (help full
        % if we want to plot time on the X axis but make a table with time
        % on the rows
        if flipCell == 1
            tmp.sigcell = horzcat(yVals,xVals)';
        else
            tmp.sigcell = horzcat(yVals,xVals);
        end
        
        inStat.usr.sigstat{ii} = tmp.sigstat;
        inStat.usr.sigcell{ii} = tmp.sigcell;
        inStat.usr.siglbl{ii}  = tmp.label;
    end
    outStat(iStat) = inStat;
end


if ~isempty(path_output_fld) && ischar(path_output_fld)
    if ~exist(path_output_fld,'dir'); mkdir(path_output_fld);end
end

for iStat = 1:length(outStat)
    
    
    if ~isempty(path_output_fld)
       outCell = vertcat(outStat(iStat).usr.sigcell{:}); 
        
        if length(outStat) == 1 && length(outStat(iStat).usr.siglbl) == 1
            ABSpathBase = fullfile(path_output_fld,...
                outStat(iStat).usr.siglbl{1});
        else
            ABSpathBase = fullfile(path_output_fld,...
            [outStat(iStat).usr.label,'(',dim2use,'_n[',...
            num2str(length(outStat(iStat).usr.siglbl)),']',...
            ')mc(',inStat.cfg.correctm,')',stat2use]);
        end
        ABSpathFile = [ABSpathBase,'.txt'];
        [ dir2out, file2out ] = fn_IncrementFileStructure('file', ABSpathFile );
        ABSpathFile = fullfile(dir2out,file2out);
        fn_cell_print( outCell, ABSpathFile)
    end
    
    if createFigs == 1
        for iDim = 1:length(outStat(iStat).usr.siglbl)
            inTitle = outStat(iStat).usr.siglbl{iDim};
            inData  = outStat(iStat).usr.sigstat{iDim};
            tt = reshape(inData,[1 numel(inData)]);
            
            n_nan = sum(isnan(tt));
            tt1 = tt(~isnan(tt));
            n_zero= sum(tt1 == 0);
            
            if (n_nan + n_zero) ~= length(tt)
                X_label = xDim.label;
                Y_label = yDim.label;
                Z_label = stat2use;
                
                if length(yDim.values)> 40
                    yyIndx = round(linspace(1,length(yDim.values),40));
                    yyVals = yDim.values(yyIndx);
                else
                    yyIndx = 1:length(yDim.values);
                    yyVals = yDim.values;
                end
                
                if length(xDim.values)> 40
                    xxIndx = round(linspace(1,length(xDim.values),40));
                    xxVals = xDim.values(xxIndx);
                else
                    xxIndx = 1:length(xDim.values);
                    xxVals = xDim.values;
                end
                  
                Y_ticks = vertcat(num2cell(yyIndx),yyVals);
                X_ticks = vertcat(num2cell(xxIndx),xxVals);
                [f1, ~ ]  = fn_plot_heat_map( inData, inTitle, X_label, Y_label, Z_label, X_ticks, Y_ticks  );
                
                if ~isempty(path_output_fld)
                    path_output_file = fullfile(path_output_fld,[inTitle,'.fig']);
                    [ dir2out, file2out ] = fn_IncrementFileStructure('file', path_output_file );
                    path_output_file = fullfile(dir2out,file2out);
                    savefig(f1,path_output_file,'compact'); 
                    
                    F = getframe(f1);
                    path_output_file = fullfile(path_output_fld,[inTitle,'.png']);
                    [ dir2out, file2out ] = fn_IncrementFileStructure('file', path_output_file );
                    path_output_file = fullfile(dir2out,file2out);
                    imwrite(F.cdata, path_output_file);
                    close(f1);
                end
            else
                disp('All input values are Zero')
            end
        end
    end
end

end

