function [ pInfo ] = fdtp_plot_corr(incfg,in_stat,con1,con2 )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
if 1 == 0
    uStat = fdtp_stat(1).stat;
    incfg = pcfg; %#ok
    
    incfg = [];
    incfg.con_type = 'within'; %'between'
    incfg.time = uStat.time_range;
    incfg.freq = uStat.freq_range;
    incfg.chan = uStat.stat.label(uStat.stat.mask);
    incfg.con_labels = {'one','two'};
    incfg.plot_name = 'something_test';
    incfg.outputABS = 'C:\';
    incfg.addinfo = [];
    incfg.group = {conStruct.group};
    con1 = {conStruct.data};
    con2 = [conStruct.int_value];
    
end

if ~isfield(incfg,'con_type');  incfg.con_type = 'corr'; end
if ~isfield(incfg,'time');      incfg.time = []; end
if ~isfield(incfg,'freq');      incfg.freq = []; end
if ~isfield(incfg,'chan');      incfg.chan = {}; end
if ~isfield(incfg,'con_labels');incfg.con_labels = {'one','two'}; end
if ~isfield(incfg,'plot_name'); incfg.plot_name = 'something_test'; end
if ~isfield(incfg,'addinfo');   incfg.addinfo = []; end
if ~isfield(incfg,'outputABS'); incfg.outputABS = ''; end
if ~isfield(incfg,'group');     incfg.group = {}; end
if ~iscell(incfg.group)
    tmpG{1} = incfg.group; 
    incfg.group = tmpG;
end

con_type = incfg.con_type;
int_time = incfg.time;
int_freq = incfg.freq;
int_chan = incfg.chan;
con_labels = incfg.con_labels;
int_plotName = incfg.plot_name;
addinfo = incfg.addinfo;
outputABS = incfg.outputABS;
%% Plot?
% use_parameter = 'rho';

% Create labeling
pInfo.chan = ['chan_mean(',num2str(length(int_chan)),') = ',strjoin(int_chan',';')];
pInfo.time = ['time: ','[',num2str(int_time),']'];
pInfo.freq = ['freq: ','[',num2str(int_freq),']'];
pInfo.stat_type = ['stat: ',con_type];
pInfo.data1_n = ['n1: ',num2str(length(con1))];
pInfo.data2_n = ['n2: ',num2str(length(con2))];
pInfo.data1_label = ['label 1: ',con_labels{1}];
pInfo.data2_label = ['label 2: ',con_labels{2}];
pInfo.addinfo =addinfo;
pInfo.group = incfg.group;

cfg = [];
cfg.channel = int_chan;
cfg.avgoverchan = 'yes';
cfg.latency     = int_time;
cfg.avgovertime = 'yes';
cfg.frequency   = int_freq;
cfg.avgoverfreq = 'yes';
cfg.nanmean     = 'yes';

pVal = nan(1,length(con1));
for ii = 1:length(con1)
    [tmpC] = ft_selectdata(cfg, con1{ii});
    pVal(ii) = tmpC.powspctrm;
end

pInfo.int_chan = int_chan;
pInfo.int_time = int_time;
pInfo.int_freq = int_freq;
pInfo.con_labels = con_labels;
pInfo.pVal = pVal;
pInfo.intVal = con2;

[R,P] = corrcoef(pVal,con2);
pInfo.corr.R = R;
pInfo.corr.P = P;

z = .5*log( (1+R(1,2))/(1-R(1,2)) );
sErr = 1/sqrt(length(pVal)-3);
tmp = 1.96*sErr;
ci=[tanh(z-tmp),tanh(z+tmp)];

% pInfo.corrgrp.n = length(pVal);
% pInfo.corrgrp.z = round(z*1000)/1000;
% pInfo.corrgrp.sErr = round(sErr*1000)/1000;
% pInfo.corrgrp.ci = round(ci*1000)/1000;

pInfo.corrgrp = [];
pInfo.fishers = [];
if ~isempty(pInfo.group) && length(pInfo.group) >= 2
    grp_lbls = unique(pInfo.group);
    for ii = 1:length(grp_lbls)
        tmpG = find(ismember(pInfo.group,grp_lbls(ii)) == 1);
        tmp_pVal = pVal(tmpG);
        tmp_con2 = con2(tmpG);
        [tR,tP] = corrcoef(tmp_pVal,tmp_con2);
        pInfo.corrgrp(ii).label = grp_lbls{ii};
        pInfo.corrgrp(ii).pVal = tmp_pVal;
        pInfo.corrgrp(ii).inVal = tmp_con2;
        pInfo.corrgrp(ii).R = tR(1,2);
        pInfo.corrgrp(ii).P = tP;
        
        n = length(tmp_pVal);
        z = .5*log( (1+tR(1,2))/(1-tR(1,2)) );
        sErr = 1/sqrt(n-3);
        tmp = 1.96*sErr;
        ci=[tanh(z-tmp),tanh(z+tmp)];
        
        pInfo.corrgrp(ii).n = n;
        pInfo.corrgrp(ii).z = round(z*1000)/1000;
        pInfo.corrgrp(ii).sErr = round(sErr*1000)/1000;
        pInfo.corrgrp(ii).ci = round(ci*1000)/1000;
    end
    if length(pInfo.corrgrp) == 2
    pInfo.fishers.sErr = sqrt((1/(pInfo.corrgrp(1).n-3)) + (1/(pInfo.corrgrp(2).n-3)));
    pInfo.fishers.zDiff = (pInfo.corrgrp(1).z-pInfo.corrgrp(2).z)/pInfo.fishers.sErr;
    pInfo.fishers.p = 2*(1-normcdf(abs(pInfo.fishers.zDiff)));
    end
end


adsig = '';
if P(2,1) <= .05; adsig = 'sig';end
if isempty(int_plotName); int_plotName = 'test_me'; end
int_plotName = [int_plotName,adsig];

FigH = figure('Name',int_plotName,'NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);
useTitle = ['n(',num2str(length(pVal)),'): ',...
    con_labels{2},' X ',con_labels{1}];

%Plot grand average (highlighting selected electrode)
if length(in_stat.label) ~= 1
cfg = [];
cfg.zlim      = 'maxabs';
cfg.highlight          = 'on';
cfg.highlightchannel = int_chan;
cfg.highlightsymbol  = '*';
cfg.layout           = 'biosemi32.lay';
cfg.colorbar         = 'yes';

cfg.parameter = 'rho';
subplot(2,3,1); ft_topoplotTFR(cfg, in_stat);

cfg.parameter = 'rho';
cfg.maskparameter = 'mask';
subplot(2,3,2); ft_topoplotTFR(cfg, in_stat);

cfg.parameter = 'stat';
cfg.maskparameter = '';
subplot(2,3,3); ft_topoplotTFR(cfg, in_stat);
end

subplot(2,3,[4 5]);
tmpColorStuff = {'bd','b';'g','g'};

if ~isempty(pInfo.corrgrp)
    incell = cell(1,length(pInfo.corrgrp));
    for ii = 1:length(pInfo.corrgrp)
        incell{ii}.lbl  = pInfo.corrgrp(ii).label;
        incell{ii}.x = pInfo.corrgrp(ii).inVal;
        incell{ii}.y = pInfo.corrgrp(ii).pVal;
        incell{ii}.pointC = tmpColorStuff{ii,1};
        incell{ii}.trendC = tmpColorStuff{ii,2};
    end
else
    incell = {};
    incell{1}.x = con2;
    incell{1}.y = pVal;
    incell{1}.pointC = 'bd';
    incell{1}.trendC = 'b';
end

cfg = [];
cfg.title = useTitle;
cfg.xlabel = strrep(con_labels{2},'_','\_');
cfg.ylabel = strrep(con_labels{1},'_','\_');
cfg.add_allcorrelation = 1;

cfg.createNew = 'no';
cfg.datawidth  = 200;
cfg.trendwidth = 10;
cfg.textsize   = 10;
[ ~,detCell, addstrCell ] = fn_plot_correlation( cfg, incell );
pInfo.stat_type = con_type;

pInfo.detCell = detCell;

pInfo.plotName = int_plotName;
if ~isempty(pInfo.fishers)
    addstrCell{end+1} = ['Fishers Exact: ',...
        num2str(round(pInfo.fishers.p*1000)/1000)];
end
pInfo.addstrCell = addstrCell;

%Report info on the spesific cluster
subplot(2,3,6);
plot(1,1);  axis off


UchanCell = {};
if length(pInfo.chan)> 60
    channel_inc = [1:50:length(pInfo.chan), length(pInfo.chan)];
    breakpts = [channel_inc(1:end-1)', channel_inc(2:end)'];
    UchanCell = cell(1,size(breakpts,1));
    for i = 1:size(breakpts,1)
        UchanCell{i} = pInfo.chan(breakpts(i,1):breakpts(i,2));
    end
else
    UchanCell{1} = pInfo.chan;
end

figure_text = {...
    strrep(int_plotName,'_',' ');...
    ['stat: ',con_type,' | ',strrep(useTitle,'_',' ')];...
    [strrep(pInfo.freq,'_',' '),' | ',strrep(pInfo.time,'_',' ')];...
    };

curr_val = 2.15;
for iText = 1:3
    if iText == 1; addcell = figure_text; end
    if iText == 2; addcell = addstrCell; end
    if iText == 3; addcell = UchanCell; end
    for ii = 1:length(addcell)
        curr_val = curr_val - .15;
        if ~isempty(addcell{ii})
            text(.1,curr_val,strrep(addcell{ii},'_',' '));
        end
    end
end

cluster_label = ['f',num2str(mean(pInfo.int_freq)),...
    't',num2str(mean(pInfo.int_time)),'c',num2str(length(pInfo.int_chan))];
sL = {'grp','sub',pInfo.con_labels{2},[pInfo.con_labels{1},cluster_label]};
sD = [pInfo.addinfo.sub;num2cell(pInfo.intVal);num2cell(round(pInfo.pVal,3))];
pInfo.quick_data = horzcat(sL',sD)';

t = {};
t{1,1} = horzcat(pInfo.con_labels{2},' X ',pInfo.con_labels{1},' ',pInfo.freq,' ',pInfo.time);
t{2,1} = pInfo.chan;
tmpSSS = sprintf('''%s'', ',pInfo.int_chan{:});
t{3,1} = ['{',tmpSSS(1:end-2),'}'];
t{4,1} = sprintf('%s'', ',pInfo.addstrCell{:});
pInfo.quick_details = t;

tmpIn = cell(4,size(pInfo.quick_data,2)-1);
pInfo.quick_out = vertcat(horzcat(t,tmpIn),pInfo.quick_data);
% Save output
if ~isempty(outputABS)
    if ~exist(outputABS,'dir'); mkdir(outputABS); end
    outFile = fullfile(outputABS,int_plotName);
    savefig(FigH,[outFile,'.fig']);
    F = getframe(FigH);
    imwrite(F.cdata, [outFile,'.png']);
    close(FigH);
    save([outFile,'.mat'],'pInfo');
    
     %Print values
    fn_cell_print( pInfo.quick_out, [outFile,'.txt'])
end
end

