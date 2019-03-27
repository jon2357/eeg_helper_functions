function [regStat, corrStat] = fldtp_fn_correlation(incfg,cData,intData)
% cData = 1 x N cell array with each cell representing a subject only use
%   one condition or a difference
% behavData = 1 x N array with each column containing a behavoiral
%   score you want to investigate with

if 1 == 0
    cData = grpData.cond(3,:);
    intData = rand(1,length(cData));
    incfg = [];
    incfg.avgovertime = 'yes';
    incfg.latency = [ .2 1.7];
    incfg.frequency   = [8 12];
    incfg.avgoverfreq = 'yes';
end

if ~isfield(incfg,'chanIndx');    incfg.chanIndx    = 'all'; end
if ~isfield(incfg,'latency');     incfg.latency     = 'all'; end
if ~isfield(incfg,'frequency');   incfg.frequency   = 'all'; end
if ~isfield(incfg,'parameter');   incfg.parameter   = 'powspctrm'; end

if ~isfield(incfg,'avgoverchan'); incfg.avgoverchan = 'no';  end
if ~isfield(incfg,'avgovertime'); incfg.avgovertime = 'no'; end
if ~isfield(incfg,'avgoverfreq'); incfg.avgoverfreq = 'no'; end

if ~isfield(incfg,'numrand');     incfg.numrand     = 2000; end
if ~isfield(incfg,'correcttail'); incfg.correcttail = 'prob'; end

if ~isfield(incfg,'runTest'); incfg.runTest = {'indepsamplesregrT','correlationT'}; end

if size(cData) ~= size(intData); error('condition Data and behavoiral data need to match');end
%here we insert our independent variable (behavioral data) in the cfg.design matrix, for example: reaction times, Pr, etc..

useMethod = 'montecarlo';

%% Base configuration
cfg = [];
cfg.channel     = incfg.chanIndx;    %Nx1 cell-array with selection of channels (default = 'all'), see FT_CHANNELSELECTION for details
cfg.latency     = incfg.latency;     %[begin end] in seconds or 'all' (default = 'all')
cfg.frequency   = incfg.frequency;   %[begin end], can be 'all'       (default = 'all')
cfg.avgoverchan = incfg.avgoverchan; %'yes' or 'no'                   (default = 'no')
cfg.avgovertime = incfg.avgovertime; %'yes' or 'no'                   (default = 'no')
cfg.avgoverfreq = incfg.avgoverfreq; %'yes' or 'no'                   (default = 'no')
cfg.parameter   = incfg.parameter;   %(default = 'powspctrm')

cfg.method      = useMethod;
cfg.numrandomization = incfg.numrand;
cfg.computecritval = 'yes';
cfg.computeprob    = 'yes';
cfg.correcttail   = incfg.correcttail;
%% compute statistics with ft_statfun_indepsamplesregrT
if ismember('indepsamplesregrT',incfg.runTest)
    rcfg = cfg;
    rcfg.statistic   = 'ft_statfun_indepsamplesregrT';
    rcfg.design = intData; rcfg.ivar = 1;
    regStat = ft_freqstatistics(rcfg, cData{:});
else
    regStat = [];
end
%% compute statistics with correlationT
if ismember('correlationT',incfg.runTest)
%     dum = cell(1,length(cData));
%     for ii = 1:length(cData)
%         dum{ii} = cData{ii};
%         dum{ii}.powspctrm = repmat(intData(ii),size(cData{ii}.powspctrm));
%     end
%     Nsub = length(cData);
%     ccfg = cfg;
%     ccfg.statistic   = 'ft_statfun_correlationT';
%     ccfg.design = [horzcat(ones(1,Nsub),2*ones(1,Nsub))]; %horzcat(1:Nsub,1:Nsub)];
%     ccfg.ivar = 1;    %ccfg.uvar = 2;
%     
%     corrStat = ft_freqstatistics(ccfg, cData{:},dum{:});

    ccfg = cfg;
    ccfg.statistic   = 'ft_statfun_correlationT';
    ccfg.design = intData; 
    ccfg.ivar = 1;
    corrStat = ft_freqstatistics(ccfg, cData{:});
else
    corrStat = [];
end
end

