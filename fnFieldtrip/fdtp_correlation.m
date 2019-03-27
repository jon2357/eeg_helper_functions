function [regStat, corrStat] = fdtp_correlation(incfg,cData,intData)
% cData = 1 x N cell array with each cell representing a subject only use
%   one condition or a difference
% behavData = 1 x N array with each column containing a behavoiral
%   score you want to investigate with
%For running permutation based statistics:

if ~isfield(incfg,'run_test'); incfg.run_test = {'indepsamplesregrT','correlationT'}; end

if ~isfield(incfg,'parameter');   incfg.parameter   = 'powspctrm'; end
% Which parameter are we analyzing ('powspctrm', 'trial', 'avg')
if ~isfield(incfg,'chanIndx');    incfg.chanIndx    = 'all'; end
if ~isfield(incfg,'avgoverchan'); incfg.avgoverchan = 'no';  end
% incfg.avgoverchan = 'yes'; % Average across channel index numbers
if ~isfield(incfg,'latency');     incfg.latency     = 'all'; end
if ~isfield(incfg,'avgovertime'); incfg.avgovertime = 'no'; end
% incfg.avgovertime = 'yes'; % Average across time range
if ~isfield(incfg,'frequency');   incfg.frequency   = 'all'; end
if ~isfield(incfg,'avgoverfreq'); incfg.avgoverfreq = 'no'; end
% incfg.avgoverfreq = 'yes'; % Average across frequency range
if ~isfield(incfg,'nanmean');     incfg.nanmean     = 'yes'; end
if ~isfield(incfg,'statistic');   incfg.statistic   = 'depsamplesT'; end
%   incfg.statistic     = 'indepsamplesT'           independent samples T-statistic,(for compairing between groups)
%                         'indepsamplesF'           independent samples F-statistic,
%                         'indepsamplesregrT'       independent samples regression coefficient T-statistic,
%                         'indepsamplesZcoh'        independent samples Z-statistic for coherence,
%              Default -> 'depsamplesT'             dependent samples T-statistic,(for compairing within subject conditions)
%                         'depsamplesFmultivariate' dependent samples F-statistic MANOVA,
%                         'depsamplesregrT'         dependent samples regression coefficient T-statistic,
%                         'actvsblT'                activation versus baseline T-statistic.
if ~isfield(incfg,'correctm');    incfg.correctm    = 'no'; end
% apply multiple-comparison correction:
% incfg.correctm       = 'no', 'max', cluster', 'bonferroni', 'holm', 'hochberg', 'fdr' (default = 'no')
if ~isfield(incfg,'alpha');       incfg.alpha       = .05; end
if ~isfield(incfg,'correcttail'); incfg.correcttail = 'prob'; end
if ~isfield(incfg,'clusteralpha');incfg.clusteralpha = .05;end
if ~isfield(incfg,'numrand');     incfg.numrand     = 2000; end

if ~isfield(incfg,'useNeighbors');incfg.useNeighbors= 'no'; end
if ~isfield(incfg,'nbMethod');    incfg.nbMethod    = 'template'; end
if ~isfield(incfg,'minNb');       incfg.minNb       = 1; end

if ~isfield(incfg,'layout');      incfg.layout      = 'biosemi32.lay'; end
% 'biosemi128.lay'
if ~isfield(incfg,'template');    incfg.template    = 'biosemi32_neighb.mat'; end
%% Setup and run statistics
if strcmpi(incfg.useNeighbors,'yes')
    cfg = [];
    cfg.method      = incfg.nbMethod; %'template'; % try 'distance' as well
    cfg.template    = incfg.template;               % specify type of template
    cfg.layout      = incfg.layout;                      % specify layout of sensors* (biosemi128.lay)
    cfg.feedback    = 'no';                             % show a neighbour plot
    neighbours      = ft_prepare_neighbours(cfg, cData{1}); % define neighbouring channels
end
%% default settings for any analysis
cfg = [];
cfg.channel     = incfg.chanIndx;    %Nx1 cell-array with selection of channels (default = 'all'), see FT_CHANNELSELECTION for details
cfg.latency     = incfg.latency;     %[begin end] in seconds or 'all' (default = 'all')
cfg.frequency   = incfg.frequency;   %[begin end], can be 'all'       (default = 'all')
cfg.avgoverchan = incfg.avgoverchan; %'yes' or 'no'                   (default = 'no')
cfg.avgovertime = incfg.avgovertime; %'yes' or 'no'                   (default = 'no')
cfg.avgoverfreq = incfg.avgoverfreq; %'yes' or 'no'                   (default = 'no')
cfg.parameter   = incfg.parameter;       %(default = 'powspctrm')
cfg.nanmean     = incfg.nanmean;
cfg.method      = 'montecarlo';
%   cfg.method       = different methods for calculating the significance probability and/or critical value
%                    'montecarlo'    get Monte-Carlo estimates of the significance probabilities and/or critical values from the permutation distribution,
%                    'analytic'      get significance probabilities and/or critical values from the analytic reference distribution (typically, the sampling distribution under the null hypothesis),
%                    'stats'         use a parametric test from the MATLAB statistics toolbox,
%                    'crossvalidate' use crossvalidation to compute predictive performance
cfg.numrandomization = incfg.numrand;
cfg.alpha       = incfg.alpha;
cfg.correcttail = incfg.correcttail;


cfg.statistic   = incfg.statistic;
%   cfg.statistic       = 'indepsamplesT'           independent samples T-statistic,
%                         'indepsamplesF'           independent samples F-statistic,
%                         'indepsamplesregrT'       independent samples regression coefficient T-statistic,
%                         'indepsamplesZcoh'        independent samples Z-statistic for coherence,
%                         'depsamplesT'             dependent samples T-statistic,
%                         'depsamplesFmultivariate' dependent samples F-statistic MANOVA,
%                         'depsamplesregrT'         dependent samples regression coefficient T-statistic,
%                         'actvsblT'                activation versus baseline T-statistic.

cfg.correctm    = incfg.correctm;
% string, apply multiple-comparison correction, 'no', 'max', cluster',
% 'bonferroni', 'holm', 'hochberg', 'fdr' (default = 'no')

% if using cluster based statistics for multiple comparison corrections
if strcmpi(cfg.correctm,'cluster')
    cfg.clusterstatistic = 'maxsum';
    %  'maxsum', 'maxsize', 'wcm' (default = 'maxsum')
    cfg.clusterthreshold = 'parametric';
    cfg.clusteralpha     = incfg.clusteralpha;
    if strcmpi(incfg.useNeighbors,'yes')
        cfg.neighbours       = neighbours;
        cfg.minnbchan        = incfg.minNb ; % minimal neighbouring channels
    else
        cfg.neighbours       = [];
    end
end

% Other options
cfg.computecritval = 'yes';
cfg.feedback       = 'textbar';
%% compute statistics with ft_statfun_indepsamplesregrT
if ismember('indepsamplesregrT',incfg.run_test)
    rcfg = cfg;
    rcfg.statistic   = 'ft_statfun_indepsamplesregrT';
    rcfg.design = intData; rcfg.ivar = 1;
    regStat = ft_freqstatistics(rcfg, cData{:});
else
    regStat = [];
end
%% compute statistics with correlationT
if ismember('correlationT',incfg.run_test)
    ccfg = cfg;
    ccfg.statistic   = 'ft_statfun_correlationT';
    ccfg.design = intData; ccfg.ivar = 1;
    corrStat = ft_freqstatistics(ccfg, cData{:});
else
    corrStat = [];
end
end

