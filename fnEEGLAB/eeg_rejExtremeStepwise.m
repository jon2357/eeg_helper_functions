function [ rejExtemeChans ] = eeg_rejExtremeStepwise(incfg, allData, srate, chans2run)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

% allData    = EEG.data;
% srate      = EEG.srate;
% chans2run  = 1:32;

if ~isfield(incfg,'cutprctile'); incfg.cutprctile = 97.5;  end
if ~isfield(incfg,'refindx');    incfg.refindx    = [];  end
if ~isfield(incfg,'wholeEpochCalc'); incfg.wholeEpochCalc    = 0;  end
if ~isfield(incfg,'threshold'); incfg.threshold    = [];  end

if ~isfield(incfg,'winsize');    incfg.winsize    = 200; end %in ms
if ~isfield(incfg,'stepsize');   incfg.stepsize   = 100; end %in ms
if ~isfield(incfg,'startIndx');  incfg.startIndx  = [];   end
if ~isfield(incfg,'endIndx');    incfg.endIndx    = [];  end


cutprctile = incfg.cutprctile;
winsize    = incfg.winsize;
stepsize   = incfg.stepsize;
useAlldata = incfg.wholeEpochCalc;
uVtheshold = incfg.threshold;
indx2avg   = incfg.refindx;

startIndx  = incfg.startIndx;
endIndx    = incfg.endIndx;

totalChans = size(allData,1);
allTimes   = size(allData,2);
numTrials  = size(allData,3);

if isempty(startIndx); startIndx = 1; end
if isempty(endIndx);   endIndx = allTimes; end

rejExtemeChans = zeros(totalChans,numTrials);
epochIndx      = startIndx:endIndx;
epochSize      = length(epochIndx);
sampleMS       = 1000/srate;
winIndxSize    = round(winsize/sampleMS);
stepIndxSize   = round(stepsize/sampleMS);

% setup onset index values
stepInt = nan(1,round(epochSize/stepIndxSize));
stepInt(1) = 1;
for iS = 2:length(stepInt); stepInt(iS) = stepIndxSize * iS; end

for i = 1:length(chans2run)
    chan2chk = chans2run(i);
    disp(['Processing Channel Index: ',num2str(chan2chk)]);
    cData  = allData(chan2chk,startIndx:endIndx,:);
    
    cutChans = [chan2chk,indx2avg];
    if useAlldata == 1
        %data2check = allData(chan2chk,:,:);
        data2check = nanmean(allData(cutChans,:,:),1);
    else
        data2check = cData;
    end
    cutOff = round(prctile(range(data2check,2),cutprctile));
    if isempty(uVtheshold); uVtheshold = cutOff; end
    
    epochChk = zeros(1,size(cData,3));
    for iT = 1:size(cData,3)
        A = cData(:,:,iT);
        for iE = 1:length(stepInt)
            chkDat = stepInt(iE):stepInt(iE)+winIndxSize;
            if chkDat(end) > length(A)
                sVal = chkDat <= length(A);
                chkDat = chkDat(sVal);
            end
            if length(chkDat) >= stepIndxSize
                if range(A(chkDat)) >= cutOff & range(A(chkDat)) > uVtheshold
                    epochChk(iT) = 1;
                end
            end
        end
    end
    disp(['-- Reject Trials: ',num2str(sum(epochChk))]);
    rejExtemeChans(chan2chk,:) = epochChk;
end
end

