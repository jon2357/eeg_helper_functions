function [ pat ] = ap_reduce_pat( incfg, pat )


if ~isfield(incfg,'replace_nan'); incfg.replace_nan = []; end % 
% setting this to a value will find all 'NaN' values in the dataset and
% replace them with the passed through value (might be useful if nan fucks
% up classification, needs to be numeric

if ~isfield(incfg,'event_index'); incfg.event_index = []; end % 
%For selecting events, pass through the index numbers of which events you
%want to keep

if ~isfield(incfg,'chan'); incfg.chan = {}; end
% {'Fz','Cz','Pz'} = reduce data to these electrodes
% {{'Fz','Cz','Pz'}} = average these electrodes (allows for multiple
% clusters)

if ~isfield(incfg,'time_range'); incfg.time_range = []; end
% N x 2 array, each row contains values to limit the time range too
% Checks time against the time dimension data structure 'avg' field
if ~isfield(incfg,'time_avg_or_limit'); incfg.time_avg_or_limit = 1; end
% 1 = average the time points together to create a temporal cluster
% 2 = remove time points out side of those passed through

if ~isfield(incfg,'freq_range'); incfg.freq_range = []; end
% N x 2 array, each row contains values to limit the freq range too
% Checks freq against the time dimension data structure 'avg' field
if ~isfield(incfg,'freq_avg_or_limit'); incfg.freq_avg_or_limit = 1; end
% 1 = average the freq points together to create a freq cluster (band)
% 2 = remove freq points out side of those passed through


%%
if ~isempty(incfg.replace_nan)
    pat.mat(isnan(pat.mat)) = incfg.replace_nan;
end


%% 
if ~isempty(incfg.event_index)
        newMat = pat.mat(incfg.event_index,:,:,:);
        newDim = pat.dim.ev;
        newDim.mat = newDim.mat(incfg.event_index);
        newDim.len = length(newDim.mat);
        
        pat.mat = newMat;
        pat.dim.ev = newDim;
end

%%
if ~isempty(incfg.chan)
    uRange = incfg.chan; %{'Fz','Cz','Pz','Fp1','Fp2','AF3','AF4'}; % incfg.chan
    patDimVal = {pat.dim.chan.mat.label};
    
    if ischar(uRange{1}) && ~iscell(uRange{1})
        indx = find(ismember(patDimVal,uRange) == 1);
        tS = pat.dim.chan.mat(indx);
        for iT = 1:length(tS); tS(iT).number = iT; end
        newMat = pat.mat(:,indx,:,:);
    end
    
    if ~ischar(uRange{1}) && iscell(uRange{1})
        tS = struct('number',[],'label',[]);
        newMat = [];
        for ii = 1:length(uRange)
            indx = find(ismember(patDimVal,uRange{ii}) == 1);
            tS(ii).number = ii;
            tS(ii).label = strjoin(patDimVal(indx),',');
            newMat(:,ii,:,:) = nanmean(pat.mat(:,indx,:,:),2); %#ok
        end
    end
    
    pat.mat = newMat;
    pat.dim.chan.mat = tS;
    pat.dim.chan.len = length(pat.dim.chan.mat);
end

%%
if ~isempty(incfg.time_range)
    uRange = incfg.time_range; %[-.1 0; 0 .1;.1 .2;.2 .3]; % incfg.time_range
    patDimVal = [pat.dim.time.mat.avg];
    
    %Find the matching index numbers for each passed through value
    idcell = cell(1,size(uRange,1));
    for ii = 1:size(uRange,1)
        sR = uRange(ii,:);
        %[~, indx_1] = min(abs(patDimVal - sR(1))); %find nearest data point (could be before or after)
        %[~, indx_2] = min(abs(patDimVal - sR(2)));
        indx_1 = find(patDimVal > sR(1),1,'first');
        indx_2 = find(patDimVal < sR(2),1,'last');
        idcell{ii} = indx_1:indx_2;
    end
    
    % Create clusters based on index values for the dim info and the data
    if incfg.time_avg_or_limit == 1
        tS = struct('range',[],'avg',[],'label',[]);
        newMat = [];
        for ii = 1:length(idcell)
            tI = idcell{ii};
            tS(ii).range = [patDimVal(min(tI)),patDimVal(max(tI))];
            tS(ii).avg = mean(patDimVal(tI));
            tS(ii).label = [num2str(round(tS(ii).range(1),2)),'to',...
                num2str(round(tS(ii).range(2),2))];
            
            newMat(:,:,ii,:) = nanmean(pat.mat(:,:,tI,:),3); %#ok
        end
    end
    
    % Reduce data to only those index values for the dim info and the data
    if incfg.time_avg_or_limit == 2
        uV = unique(horzcat(idcell{:}));
        tS = pat.dim.time.mat(uV);
        newMat = pat.mat(:,:,uV,:);
    end
    
    pat.mat = newMat;
    pat.dim.time.mat = tS;
    pat.dim.time.len = length(pat.dim.time.mat);
end

%%
if ~isempty(incfg.freq_range)
        uRange = incfg.freq_range; % [4 7; 8 12; 16 26]; % incfg.freq_range
    patDimVal = [pat.dim.freq.mat.avg];
    
    %Find the matching index numbers for each passed through value
    idcell = cell(1,size(uRange,1));
    for ii = 1:size(uRange,1)
        sR = uRange(ii,:);
        %[~, indx_1] = min(abs(patDimVal - sR(1)));
        %[~, indx_2] = min(abs(patDimVal - sR(2)));
        indx_1 = find(patDimVal > sR(1),1,'first');
        indx_2 = find(patDimVal < sR(2),1,'last');
        idcell{ii} = indx_1:indx_2;
    end
    
    % Create clusters based on index values for the dim info and the data
    if incfg.freq_avg_or_limit == 1
        tS = struct('range',[],'avg',[],'label',[]);
        newMat = [];
        for ii = 1:length(idcell)
            tI = idcell{ii};
            tS(ii).range = [patDimVal(min(tI)),patDimVal(max(tI))];
            tS(ii).avg = mean(patDimVal(tI));
            tS(ii).label = [num2str(round(tS(ii).range(1),2)),'to',...
                num2str(round(tS(ii).range(2),2))];
            
            newMat(:,:,:,ii) = nanmean(pat.mat(:,:,:,tI),4); %#ok
        end
    end
    
    % Reduce data to only those index values for the dim info and the data
    if incfg.freq_avg_or_limit == 2
        uV = unique(horzcat(idcell{:}));
        tS = pat.dim.freq.mat(uV);
        newMat = pat.mat(:,:,:,uV);
    end
    
    pat.mat = newMat;
    pat.dim.freq.mat = tS;
    pat.dim.freq.len = length(pat.dim.freq.mat);
end
