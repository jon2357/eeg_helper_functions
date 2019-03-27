function [ pInfo ] = fdtp_plot_mean_level(incfg,con1,con2 )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
if 1 == 0
    uStat = fdtp_stat_wthn(1);
    
    incfg = [];
    incfg.con_type = 'within'; %'between'
    incfg.time = uStat.stat.time_range;
    incfg.freq = uStat.stat.freq_range;
    incfg.chan = uStat.stat.stat.label(uStat.stat.stat.mask);
    incfg.con_labels = {'one','two'};
    incfg.plot_name = 'something_test';
    incfg.outputABS = 'C:\';
    incfg.addinfo = [];
    
    con1 = {wthnCell{1}.data}; %#ok
    con2 = {wthnCell{2}.data}; 
    
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
use_parameter = 'powspctrm';

% Create labeling
pInfo.chan = ['chan_mean(',num2str(length(int_chan)),') = ',strjoin(int_chan',';'),';'];
pInfo.time = ['time: ','[',num2str(int_time),']'];
pInfo.freq = ['freq: ','[',num2str(int_freq),']'];
pInfo.stat_type = ['stat: ',con_type];
pInfo.data1_n = ['n1: ',num2str(length(con1))];
pInfo.data2_n = ['n2: ',num2str(length(con2))];
pInfo.data1_label = ['label 1: ',con_labels{1}];
pInfo.data2_label = ['label 2: ',con_labels{2}];
pInfo.addinfo =addinfo;

% Create a grand average / diff
cfg = []; cfg.parameter = use_parameter;
pD.ga1 = ft_freqgrandaverage(cfg,con1{:});
pD.ga2 = ft_freqgrandaverage(cfg,con2{:});
cfg = []; cfg.operation = 'subtract'; cfg.parameter = use_parameter;
pD.ga_diff = ft_math(cfg, pD.ga1, pD.ga2);

% Reduce in both time and frequency
cfg = [];
cfg.latency     = int_time; cfg.avgovertime = 'yes';
cfg.frequency   = int_freq; cfg.avgoverfreq = 'yes';
[pData(1)] = ft_selectdata(cfg, pD.ga1 );
[pData(2)] = ft_selectdata(cfg, pD.ga2 );
[pData(3)] = ft_selectdata(cfg, pD.ga_diff );


cfg = [];
cfg.channel = int_chan;
cfg.avgoverchan = 'yes';
cfg.latency     = int_time;
cfg.avgovertime = 'yes';
cfg.frequency   = int_freq;
cfg.avgoverfreq = 'yes';

subCluster = cell(1,2);
for i1 = 1:2
    if i1 == 1; uCon = con1; end
    if i1 == 2; uCon = con2; end
    for ii = 1:length(uCon)
        [tmpC{i1}{ii}] = ft_selectdata(cfg, uCon{ii});
        subCluster{i1}(ii) = tmpC{i1}{ii}.powspctrm;
    end
end

pVal_tmp1 = subCluster{1};
pVal_tmp2 = subCluster{2};
if length(subCluster{1}) > length(subCluster{2})
    l_diff  = abs(length(subCluster{1}) - length(subCluster{2}));
    addVal = NaN([1 l_diff]);
    pVal_tmp2 = horzcat(subCluster{2},addVal);
elseif length(subCluster{1}) < length(subCluster{2})
    l_diff  = abs(length(subCluster{1}) - length(subCluster{2}));
    addVal = NaN([1 l_diff]);
    pVal_tmp1 = horzcat(subCluster{1},addVal);
end


if strcmpi(con_type,'within') && length(pVal_tmp1) == length(pVal_tmp2)
    pLbl = horzcat(con_labels,'diff');
    pVal = vertcat(subCluster{:})';
    pVal(:,3) = pVal(:,1) - pVal(:,2);
    %[h,p,ci,stats] = ttest(pVal);
    scfg = [];
    scfg.statistic   = 'depsamplesT';
    [ stat ] = fdtp_permStatistics(scfg, tmpC{1},tmpC{2});
elseif strcmpi(con_type,'between')
    pLbl = con_labels;
    pVal = [pVal_tmp1;pVal_tmp2]';
    %[h,p,ci,stats] = ttest2(pVal_tmp1,pVal_tmp2);
    scfg = [];
    scfg.statistic   = 'indepsamplesT';
    [ stat ] = fdtp_permStatistics(scfg, tmpC{1},tmpC{2});
end

sigLine = sprintf('t(%d)=%.3f,p=%.3f,CI=%.3f',stat.df,stat.stat,stat.prob,stat.cirange);

pInfo.stat_type = horzcat(pInfo.stat_type,'; ',sigLine);
pInfo.stat = stat;
pInfo.int_chan = int_chan;
pInfo.int_time = int_time;
pInfo.int_freq = int_freq;
pInfo.con_labels = con_labels;
pInfo.pVal = pVal;

adsig = '';
if stat.prob <= .05;adsig = 'sig';end
if isempty(int_plotName); int_plotName = 'test_me'; end
int_plotName = [int_plotName,adsig];

FigH = figure('Name',int_plotName,'NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);

%Plot grand average (highlighting selected electrode)
zlim = max(abs(reshape([pData.powspctrm],[1 numel([pData.powspctrm])])))*1.1;
for iP = 1:length(pData)
    useLim = [-zlim, zlim];
    if iP == 3; useLim = 'maxabs'; end
    cfg = [];
    cfg.parameter = 'powspctrm';
    cfg.zlim      = useLim;
    cfg.highlight          = 'on';
    cfg.highlightchannel = int_chan;
    cfg.highlightsymbol  = '*';
    cfg.layout           = 'biosemi32.lay';
    cfg.colorbar         = 'yes';
    subplot(2,4,iP);
    ft_topoplotTFR(cfg, pData(iP))
end

%Plot Mean Bar of cluster with cluster average
pMean = nanmean(pVal);
pSEM = NaN(1,size(pVal,2));
pSD  = NaN(1,size(pVal,2));
for i = 1:size(pVal,2)
	pSD(i)  = nanstd(pVal(:,i)); 
    pSEM(i) = nanstd(pVal(:,i)) / sqrt(sum(~isnan(pVal(:,i))));
end

pInfo.metrics_mean = pMean;
pInfo.metrics_sem  = pSEM;
pInfo.metrics_sd   = pSD;

subplot(2,4,4);
barwitherr(pSEM, pMean);    % Plot with errorbars
set(gca,'XTickLabel',strrep(pLbl,'_',' '))

%Plot whisker plot with cluster average
subplot(2,4,[5 6]);
try 
    boxplot(pVal,'Notch','on','Labels',pLbl,'Whisker',1);
catch
    warning('Box plot failed for some reason')
    disp(pVal)
    disp(pLbl)
end

%Report info on the spesific cluster
subplot(2,4,[7 8]);
plot(1,1); axis off

text(.1,1.8,strrep(int_plotName,'_',' '))
text(.1,1.6,[strrep(pInfo.data1_label,'_',' '),' | ',...
    strrep(pInfo.data1_n,'_',' '),' | Mean (SEM) [StDev]:',...
    num2str(pMean(1)),'(',num2str(pSEM(1)),')',...
	'[',num2str(pSD(1)),']'])

text(.1,1.4,[strrep(pInfo.data2_label,'_',' '),' | ',...
    strrep(pInfo.data2_n,'_',' '),' | Mean (SEM) [StDev]:',...
    num2str(pMean(2)),'(',num2str(pSEM(2)),')',...
	'[',num2str(pSD(2)),']'])

if length(pMean) > 2
    text(.1,1.2,['Diff | Mean (SEM) [StDev]:',...
	num2str(pMean(3)),'(',num2str(pSEM(3)),')','[',num2str(pSD(3)),']'])
end

text(.1,1.0,[strrep(pInfo.freq,'_',' '),' | ',strrep(pInfo.time,'_',' ')])
text(.1,0.8,strrep(pInfo.stat_type,'_',' '))

break_indx = find(pInfo.chan == ';'); breakpoints = [60 120 180 240];
startP = 0.6; redP = [0,.15,.3,.45,6];
for ii = 1:length(breakpoints)
    useP = startP - redP(ii);
    iStop = break_indx(nearest(break_indx,breakpoints(ii)));
    
    if ii == 1; iStart = 1; 
    else; iStart = break_indx(nearest(break_indx,breakpoints(ii-1)));
    end
    
    if iStart < length(pInfo.chan)
        text(.1,useP,strrep(pInfo.chan(iStart:iStop),'_',' '));
    end
end

%% 

if length(pInfo.con_labels) == 2
    lbl_one = pInfo.con_labels{1};
    lbl_two = pInfo.con_labels{2};
    contrastLbl = ['[',strjoin(pInfo.con_labels,']vs['),']'];
elseif length(pInfo.con_labels) == 4
    lbl_one = ['[',strjoin(pInfo.con_labels(1:2),']vs['),']'];
    lbl_two = ['[',strjoin(pInfo.con_labels(3:4),']vs['),']'];
    contrastLbl = ['[',lbl_one,']vs[',lbl_two,']'];
end

cluster_label = [...
        'f(',num2str(min(pInfo.int_freq)),'to',num2str(max(pInfo.int_freq)),')',...
        't(',num2str(min(pInfo.int_time)),'to',num2str(max(pInfo.int_time)),')',...
        'c(',num2str(length(pInfo.int_chan)),')'];     

sL = {'grp','sub',lbl_one,lbl_two,'diff'};
sD = [pInfo.addinfo.sub1',num2cell(round(pInfo.pVal,3))];
sMetric = cell(4,size(sD,2));
sMetric(2,:) = horzcat({'mean',num2str(size(sD,1))},num2cell(pInfo.metrics_mean));
sMetric(3,:) = horzcat({'SD',num2str(size(sD,1))},num2cell(pInfo.metrics_sd));
sMetric(4,:) = horzcat({'sem',num2str(size(sD,1))},num2cell(pInfo.metrics_sem));
outData = vertcat(sL,sD,sMetric);

t = cell(5,size(outData,2));
t{1,1} = [contrastLbl,'_',cluster_label];
    t{2,1} =[pInfo.freq,' ',pInfo.time,' ',pInfo.chan];
    tmpSSS = sprintf('''%s'', ',pInfo.int_chan{:});
    t{3,1} = ['{',tmpSSS(1:end-2),'}'];   
    t{4,1} = pInfo.stat_type;
    
pInfo.quick_details = vertcat(t,outData);
%% Save output
if ~isempty(outputABS)
    %setup output file
    if ~exist(outputABS,'dir'); mkdir(outputABS); end
    outFile = fullfile(outputABS,[int_plotName,'.mat']);
    [ dir2out, file2out ] = fn_IncrementFileStructure('file', outFile );
    tmp_file2out = file2out(1:end-4);
    
    %Save mat file
    outFile= fullfile(dir2out,[tmp_file2out,'.mat']);
    save(outFile,'pInfo');
    %Save figure
    outFile= fullfile(dir2out,[tmp_file2out,'.fig']);
    savefig(FigH,outFile);
    %save png
    F = getframe(FigH);
    outFile = fullfile(dir2out,[tmp_file2out,'.png']);
    imwrite(F.cdata, outFile);
    %close figure
    close(FigH);    
    
    %Print values
    fn_cell_print( pInfo.quick_details, fullfile(dir2out,[tmp_file2out,'.txt']))
end
end

