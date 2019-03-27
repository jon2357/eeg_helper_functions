function [ outData, outReport ] = fdtp_quantify_trials( inData, measurement, inIndx, addtrial_label)

if 1 == 0
    measurement = 'mean';
    inIndx = 1:20;
    inData = data;
end

if nargin < 4; addtrial_label = []; end
%% Function Defaults
quantify_field = 'powspctrm';
quantify_dim = 1;
trimPercent = 10;
new_label_fieldname = 'a_label';
%%
total_data_points = size(inData.(quantify_field),quantify_dim);
if sum(inIndx < 1) > 0
    error('HP: Can not pass through a zero index');
elseif max(inIndx) > total_data_points
    error('HP: Can not pass through a index number larger than the array');
end

%% Process fieldtrip data
if isempty(inIndx)
    warning('HP: No trials selected, returning an emptyset');
    outData = [];
else
    cfg = [];
    cfg.avgoverrpt = 'no';
    cfg.trials     = inIndx;
    outData = ft_selectdata(cfg, inData);
    
    if ~strcmpi('trials',measurement)
        if ismember('mean',lower(measurement))
            a1 = nanmean(outData.(quantify_field),quantify_dim);
        elseif ismember('median',lower(measurement))
            a1 = nanmedian(outData.(quantify_field),quantify_dim);
        elseif ismember('trimmean',lower(measurement))
            a1 = trimmean(outData.(quantify_field),trimPercent,quantify_dim);
        elseif ismember('std',lower(measurement))
            a1 = nanstd(outData.(quantify_field),quantify_dim);
        else
            error('HP: Quantify Method not support');
        end
        outData.(quantify_field) = squeeze(a1);
        
        %Update dimension order
        inDimord = strsplit(outData.dimord,'_');
        dimIndx = 1:length(inDimord);
        newDim  = inDimord(~ismember(dimIndx,quantify_dim));
        outData.dimord = strjoin(newDim,'_');
    end
    % Log what the helper function did
    outData.cfg.dim  = quantify_dim;
    outData.cfg.measurement = measurement;
    if ismember('trimmean',lower(measurement))
        outData.cfg.trimpercent = trimPercent;
    end
    
    if ~isempty(addtrial_label)
        for ii = length(outData.trialinfo)
            outData.trialinfo(ii).(new_label_fieldname) = addtrial_label;
        end
    end
 
end

%% Reporting data structure
    outReport.datetime = fix(clock);
    outReport.measurement = measurement;
    if ismember('trimmean',lower(measurement))
        outReport.trimpercent = trimPercent;
    end
    outReport.dim   = quantify_dim;
    outReport.field = quantify_field;
    outReport.orig_indx = inIndx;
    outReport.trials = outData.trialinfo;
end

