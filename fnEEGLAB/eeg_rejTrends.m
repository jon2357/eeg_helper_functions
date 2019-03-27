function [ rejTrendChans ] = eeg_rejTrends(incfg, EEG, chans2run)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here


% allData    = EEG.data;
% srate      = EEG.srate;
% chans2run  = 1:32;

if ~isfield(incfg,'cutprctile');incfg.cutprctile = 95;  end
if ~isfield(incfg,'EEGorICA');  incfg.EEGorICA   = 1;   end % 1 = raw data, 0 = ICA
if ~isfield(incfg,'maxslope');  incfg.maxslope   = [];  end
if ~isfield(incfg,'minR');      incfg.minR       = .3;  end

cutprctile = incfg.cutprctile;
EEGorICA   = incfg.EEGorICA;
maxslope   = incfg.maxslope;
minR       = incfg.minR;

totalChans = size(EEG.data,1);
numTrials  = size(EEG.data,3);
rejTrendChans  = zeros(totalChans,numTrials);

for i = 1:length(chans2run)
    %cutOff = max(range(EEG.data(chans2run(i),:,:),2))/1.3;
    %cutOff = iqr(range(EEG.data(chans2run(i),:,:),2))*5;
    
    if isempty(maxslope)
        if EEGorICA == 1
            maxslope = prctile(range(EEG.data(chans2run(i),:,:),2),cutprctile);
        end
        if EEGorICA == 0
            EEG.icaact = (EEG.icaweights*EEG.icasphere)*EEG.data(EEG.icachansind,:);
            maxslope = prctile(range(EEG.icaact(chans2run(i),:,:),2),cutprctile);
        end
    end
    EEG = pop_rejtrend(EEG,EEGorICA,chans2run(i) ,EEG.pnts,maxslope ,minR,1,0,0);
    
    
    rejTrendChans(chans2run(i),:) = EEG.reject.rejconstE(chans2run(i),:);
end

end

