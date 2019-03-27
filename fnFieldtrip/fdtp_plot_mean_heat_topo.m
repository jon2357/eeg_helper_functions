function [ ] = fdtp_plot_mean_heat_topo( incfg, inDS )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if ~isfield(incfg,'parameter');   incfg.parameter = 'powspctrm'; end
if ~isfield(incfg,'freq');incfg.freq = [8 12]; end
if ~isfield(incfg,'time');incfg.time = [0 1]; end
if ~isfield(incfg,'chan');incfg.chan = {}; end
if ~isfield(incfg,'label');incfg.label = 'test'; end
if ~isfield(incfg,'add_lines');incfg.add_lines = [0 2.5]; end
if ~isfield(incfg,'zlim');incfg.zlim = []; end
if ~isfield(incfg,'outputABS');incfg.outputABS = []; end
if ~isfield(incfg,'plot_topo');incfg.plot_topo = 1; end
if ~isfield(incfg,'plot_heat');incfg.plot_heat = 1; end
if ~isfield(incfg,'plot_combo');incfg.plot_combo = 1; end

if isempty(incfg.chan) | strcmpi(incfg.chan,'all')
    incfg.chan = inDS.label;
end
if numel(incfg.time) ~= numel(incfg.freq)
    error('Must pass through matching time and freq parameters')
end
%% Get heat map details
cfg = [];
cfg.channel     = incfg.chan;
cfg.avgoverchan = 'yes';
cfg.nanmean     = 'yes';
[data_heat] = ft_selectdata(cfg, inDS);
tmp_mask = zeros(size(data_heat.(incfg.parameter)));

for ii = 1:size(incfg.time,1)
    tmp_time = data_heat.time >= min(incfg.time(ii,:)) &...
        data_heat.time <=  max(incfg.time(ii,:));
    tmp_freq = data_heat.freq >= min(incfg.freq(ii,:)) &...
        data_heat.freq <=  max(incfg.freq(ii,:));
    tmp_mask(:,tmp_freq,tmp_time) = 1;
end

for ii = 1:length(incfg.add_lines)
    [~, id] = min(abs(data_heat.time - incfg.add_lines(ii)));
    tmp_mask(:,:,id) = 1;
end
data_heat.mask = tmp_mask;


%% Get topo map properties and create DS
data_topo = cell(1,size(incfg.time,1));
for ii = 1:size(incfg.time,1)
    cfg = [];
    cfg.latency     = incfg.time(ii,:);
    cfg.avgovertime = 'yes';
    cfg.nanmean     = 'yes';
    cfg.frequency   = incfg.freq(ii,:);
    cfg.avgoverfreq = 'yes';
    cfg.nanmean     = 'yes';
    [data_topo{ii}] = ft_selectdata(cfg, inDS);
    tmp_mask = zeros(size(data_topo{ii}.(incfg.parameter)));
    tmp_chan = ismember(data_topo{ii}.label,incfg.chan);
    tmp_mask(tmp_chan) = 1;
    data_topo{ii}.mask = tmp_mask;
    
end

if isempty(incfg.zlim)
    tV = NaN(1,length(data_topo));
    for ii = 1:length(data_topo)
        tV(ii) = max(abs(reshape(data_topo{ii}.(incfg.parameter),1,numel(data_topo{ii}.(incfg.parameter)))));
    end
    incfg.zlim = [-max(tV) max(tV)];
end

if incfg.plot_combo == 1
    %% Plot combined
    if length(data_topo) > 1
        nRows = 2;
    else
        nRows = 1;
    end
    xS = 1.75 * 7;
    yS = 1 * (5*nRows);
    
    FigH = figure('NumberTitle','off',...
        'units','inch','outerposition',[0 0 xS yS]);
    
    subplot(nRows,3,[1 2])
    cfg = [];
    cfg.zlim = incfg.zlim; %           = plotting limits for color dimension, 'maxmin', 'maxabs', 'zeromax', 'minzero', or [zmin zmax] (default = 'maxmin')
    cfg.title = [strrep(incfg.label,'_',' '),'-c(',num2str(length(incfg.chan)),')'];
    cfg.maskparameter = 'mask'; %  = field in the data to be used for masking of data
    cfg.maskstyle =  'outline'; %  = style used to masking, 'opacity', 'saturation', 'outline' or 'colormix' (default = 'opacity')
    ft_singleplotTFR(cfg,data_heat)
    
    for ii = 1:length(data_topo)
        nCol = 2+ii;
        subplot(nRows,3,nCol)
        cfg = [];
        cfg.parameter = 'powspctrm';
        cfg.zlim      = incfg.zlim;
        cfg.layout           = 'biosemi32.lay';
        cfg.colorbar         = 'no';
        cfg.highlight          = 'on';
        cfg.highlightchannel = incfg.chan;
        cfg.highlightsymbol  = '*';
        cfg.highlightsize = 10;
        cfg.highlightfontsize = 20;
        %cfg.highlightcolor = [ 1 1 1];
        %cfg.maskparameter = 'mask';
        cfg.commentpos = 'rightbottom';
        cfg.title = [incfg.label,'f(',num2str(data_topo{ii}.freq),')t(',num2str(data_topo{ii}.time),')'];
        ft_topoplotTFR(cfg, data_topo{ii});
    end
    % save
    if ~isempty(incfg.outputABS)
        if ~exist(incfg.outputABS,'dir'); mkdir(incfg.outputABS);end
        print(fullfile(incfg.outputABS,[incfg.label,'.png']),'-dpng','-r300');
        print(fullfile(incfg.outputABS,[incfg.label,'.pdf']),'-dpdf','-bestfit');
        %savefig(FigH,fullfile(incfg.outputABS,[incfg.label,'.fig']),'compact');
        close(FigH)
    end
    
end

if incfg.plot_heat == 1
    %% Plot seperate Heat
    
    xS = 1.75 * 4;
    yS = 1 * 4;
    
    FigHeat = figure('NumberTitle','off',...
        'units','inch','outerposition',[0 0 xS yS]);
    
    cfg = [];
    cfg.zlim = incfg.zlim; %           = plotting limits for color dimension, 'maxmin', 'maxabs', 'zeromax', 'minzero', or [zmin zmax] (default = 'maxmin')
    cfg.title = [strrep(incfg.label,'_',' '),'-c(',num2str(length(incfg.chan)),')'];
    cfg.maskparameter = 'mask'; %  = field in the data to be used for masking of data
    cfg.maskstyle =  'outline'; %  = style used to masking, 'opacity', 'saturation', 'outline' or 'colormix' (default = 'opacity')
    ft_singleplotTFR(cfg,data_heat);
    
    if ~isempty(incfg.outputABS)
        if ~exist(incfg.outputABS,'dir'); mkdir(incfg.outputABS);end
        print(fullfile(incfg.outputABS,[cfg.title,'_heat.png']),'-dpng','-r600');
        print(fullfile(incfg.outputABS,[cfg.title,'_heat.pdf']),'-dpdf','-bestfit');
        %savefig(FigHeat,fullfile(incfg.outputABS,[cfg.title,'_heat.fig']),'compact');
        close(FigHeat)
    end
end

if incfg.plot_topo == 1
    %% Plot seperate Topo
    xS = 1 * 4;
    yS = 1 * 4;
    
    for ii = 1:length(data_topo)
    FigTopo = figure('NumberTitle','off',...
        'units','inch','outerposition',[0 0 xS yS]);

        cfg = [];
        cfg.parameter = 'powspctrm';
        cfg.zlim      = incfg.zlim;
        cfg.layout           = 'biosemi32.lay';
        cfg.colorbar         = 'yes';
        cfg.highlight          = 'on';
        cfg.highlightchannel = incfg.chan;
        cfg.highlightsymbol  = '*';
        cfg.highlightsize = 10;
        cfg.highlightfontsize = 20;
        %cfg.highlightcolor = [ 1 1 1];
        %cfg.maskparameter = 'mask';
        cfg.commentpos = 'rightbottom';
        cfg.title = [incfg.label,'f(',num2str(data_topo{ii}.freq),')t(',num2str(data_topo{ii}.time),')'];
        ft_topoplotTFR(cfg, data_topo{ii});
        
        % save
        if ~isempty(incfg.outputABS)
            if ~exist(incfg.outputABS,'dir'); mkdir(incfg.outputABS);end
            print(fullfile(incfg.outputABS,[cfg.title,'_topo.png']),'-dpng','-r600');
            print(fullfile(incfg.outputABS,[cfg.title,'_topo.pdf']),'-dpdf','-bestfit');
            %savefig(FigTopo,fullfile(incfg.outputABS,[incfg.label,'_topo.fig']),'compact');
            close(FigTopo)
        end
    end
    
    % Create a blank topo with electrodes highlights
    data_topo{1}.mask = zeros(size(data_topo{1}.(incfg.parameter)));
    
    FigTopo = figure('NumberTitle','off',...
        'units','inch','outerposition',[0 0 xS yS]);
    
    cfg = [];
    cfg.parameter = 'powspctrm';
    cfg.zlim      = incfg.zlim;
    cfg.layout           = 'biosemi32.lay';
    cfg.colorbar         = 'yes';
    cfg.highlight        = 'on';
    cfg.highlightchannel = incfg.chan;
    cfg.highlightsymbol  = '*';
    cfg.highlightsize = 10;
    cfg.highlightfontsize = 20;
    %cfg.highlightcolor = [ 1 1 1];
    cfg.maskparameter = 'mask';
    cfg.commentpos = 'rightbottom';
    cfg.title = incfg.label;
    ft_topoplotTFR(cfg, data_topo{1});
    
    % save
    if ~isempty(incfg.outputABS)
        if ~exist(incfg.outputABS,'dir'); mkdir(incfg.outputABS);end
        print(fullfile(incfg.outputABS,[incfg.label,'_topo_blank.png']),'-dpng','-r600');
        print(fullfile(incfg.outputABS,[incfg.label,'_topo_blank.pdf']),'-dpdf','-bestfit');
        %savefig(FigTopo,fullfile(incfg.outputABS,[incfg.label,'_topo_blank.fig']),'compact');
        close(FigTopo)
    end
end
end

