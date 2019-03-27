function [ outDS ] = fdtp_plot_mean_level( input_files, input_config, outputABS)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% input_files = cell array of files to use
% input_config = cell array with
%       column 1 = frequency range (ex: [ 8 12])
%       column 2 = time range (ex: [ 0 .5])
%       column 3 = conditions to plot (ex: {'vis_hit','vis_cr'})
%       column 4 = calculate difference (ex: 1 or 0)
%       column 5 = channels to average across (ex: {'Fp1','AF3','FC1'})
%       column 6 = plot name
if 1 == 0
    input_files = {...
        'C:\Users\strun\Dropbox\GT\proj\preSME\preSME_2018_02_13_v1\','test_data','ya105ret_pow_cond(30).mat';
        'C:\Users\strun\Dropbox\GT\proj\preSME\preSME_2018_02_13_v1\','test_data','ya106ret_pow_cond(30).mat';
        'C:\Users\strun\Dropbox\GT\proj\preSME\preSME_2018_02_13_v1\','test_data','ya108ret_pow_cond(30).mat';
        };
    input_config = {...
        [8 12],[0 .5],{'vis_hit','vis_cr'},1,{'Fp1','AF3','FC1'}, 'testPlot';...
        };
end

%% Verify files exist
[ returnText ] = fn_check_list_exist(input_files, 'file');
if ~isempty(returnText); error(returnText);end

%% Setup contrasts
cc.con_setup = input_config(:,3)';
cc.unique    = unique(horzcat(cc.con_setup{:}));
cc.contrast_index = NaN(length(cc.con_setup),2);
for ii = 1:length(cc.con_setup)
    tmpC = cc.con_setup{ii};
    tmpInd = NaN(1,length(tmpC));
    for i1 = 1:length(tmpC)
        tmpInd(i1) = find(ismember(cc.unique,tmpC{i1}));
    end
    cc.contrast_index(ii,:) = tmpInd;
    cc.contrast_label{ii} = ['[',cc.unique{tmpInd(1)},']vs[',cc.unique{tmpInd(2)},']'];
end

%% Load in conditions
getConds = cc.unique; disp(getConds)
cfg = [];
cfg.calc_diff = 1;
cfg.contrast_index = cc.contrast_index;
cfg.load_sub = 'fdtp_sub';
[ uGrp , uGA ] = hp_load_conditions( cfg, input_files, getConds);

%% Setup contrast to run
for runNum = 1:size(input_config,1)
    int_freq = input_config{runNum,1};
    int_time = input_config{runNum,2};
    int_plot = horzcat(input_config{runNum,3},cc.contrast_label{runNum});
    int_chan = input_config{runNum,5};
    int_plotName = input_config{runNum,6};
    
    %% Select the grand averages
    p_indx = NaN(1,length(int_plot));
    for ii = 1:length(p_indx)
        p_indx(ii) = find(ismember([uGA.label],int_plot{ii}) == 1);
    end
    pGA = uGA(p_indx);
    
    %% Get data from each subject
    
    outCell = cell(length(uGrp),length(pGA),7);
    for iSub = 1:length(uGrp)
        uSub = uGrp(iSub);
        for iG = 1:length(pGA)
            t.label = pGA(iG).label{1};
            t.index = find(ismember({uSub.condition.label},t.label) == 1);
            if isempty(t.index)
                t.index = find(ismember({uSub.contrast.label},t.label) == 1);
                t.data = uSub.contrast(t.index).data;
                t.n    = uSub.contrast(t.index).n;
            else
                t.data = uSub.condition(t.index).data;
                t.n    = uSub.condition(t.index).n;
            end
            cfg = [];
            cfg.channel = int_chan;
            cfg.avgoverchan = 'yes';
            cfg.latency     = int_time;
            cfg.avgovertime = 'yes';
            cfg.frequency   = int_freq;
            cfg.avgoverfreq = 'yes';
            [rData] = ft_selectdata(cfg, t.data);
            outCell{iSub,iG,1} = rData;
            outCell{iSub,iG,2} = rData.powspctrm;
            outCell{iSub,iG,3} = t.label;
            outCell{iSub,iG,4} = t.n;
            outCell{iSub,iG,5} = uSub.subject;
            outCell{iSub,iG,6} = uSub.group;
            outCell{iSub,iG,7} = uSub.behav;
        end
    end
    
    %% Reduce the grand average data
    if exist('pData','var'); clear pData; end
    for iP = 1:length(pGA)
        cfg = [];
        cfg.latency     = int_time;
        cfg.avgovertime = 'yes';
        cfg.frequency   = int_freq;
        cfg.avgoverfreq = 'yes';
        [pData(iP)] = ft_selectdata(cfg, pGA(iP).data); %#ok
    end
    
    %% Create output variable
    pInfo.subject = outCell(:,1,5);
    pInfo.group   = outCell(:,1,6);
    pInfo.sel_chan   = int_chan;
    pInfo.sel_time   = int_time;
    pInfo.sel_freq   = int_freq;
    pInfo.sel_label  = outCell(1,:,3);
    pInfo.sel_data   = outCell(:,:,2);
    pInfo.sel_ga = pData;
    
    outDS(runNum) = pInfo;
    
    if ~isempty(outputABS)
        if ~exist(outputABS,'dir'); mkdir(outputABS); end
        pVal = cell2mat(pInfo.sel_data);
        pLbl = pInfo.sel_label;
        
        if isempty(int_plotName); int_plotName = 'test_me'; end
        FigH = figure('Name',int_plotName,'NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);
        
        %Plot grand average (highlighting selected electrode)
        zlim = max(abs(reshape([pData.powspctrm],[1 numel([pData.powspctrm])])))*1.1;
        for iP = 1:length(pData)
            cfg = [];
            cfg.parameter = 'powspctrm';
            cfg.zlim      = [-zlim, zlim];
            cfg.highlight          = 'on';
            cfg.highlightchannel = int_chan;
            cfg.highlightsymbol  = 'x';
            cfg.layout           = 'biosemi32.lay';
            subplot(2,4,iP);
            ft_topoplotTFR(cfg, pData(iP))
        end
        
        %Plot Mean Bar of cluster with cluster average
        pMean = mean(pVal);
        pSEM  = std(pVal) / sqrt(size(pVal,1));
        subplot(2,4,4);
        barwitherr(pSEM, pMean);    % Plot with errorbars
        set(gca,'XTickLabel',strrep(pLbl,'_',' '))
        
        
        %Plot scatter plot of the data
        subplot(2,4,[5 6]);
        pX = 1:size(pVal,1);
        scatter(pX,pVal(:,end)')
        
        %Plot whisker plot with cluster average
        subplot(2,4,[7 8]);
        boxplot(pVal,'Notch','on','Labels',pLbl,'Whisker',1)
        
        % Save output
        outFile = fullfile(outputABS,int_plotName);
        savefig(FigH,[outFile,'.fig']);
        F = getframe(FigH);
        imwrite(F.cdata, [outFile,'.png']);
        close(FigH);
        save([outFile,'.mat'],'pInfo');
    end
end
end

