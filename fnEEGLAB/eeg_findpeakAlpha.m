function [ peakAlphaWT,peakAlphaRaw, PxxRestricted,freqRused ] = eeg_findpeakAlpha( eegData,sampRate, saveFigABS)
%Required input is a channel x timw x trial matrix (same as the EEG.data
% from EEGLAB), in fldtrip this can be passed through by converting the
% trial cell array into a numerical matrix. Example code below:
%
%   from EEGLAB (load eeglab file first)
%       eegData  = EEG.data(1:32,:,:); %only include head channels
%       sampRate = EEG.srate;
%       saveFigABS = 'C:\where_ever\you\want\folder\this_is_the_file_name';
%       [ peakAlphaWT,peakAlphaRaw, PxxRestricted,freqRused ] = fn_findpeakAlpha( eegData,sampRate, saveFigABS)
%
%

rangeOfint = [7 14];
if nargin < 1; error('ChanXtimeXtrial Matrix Required'); end
if nargin < 2; error('Sample rate required'); end
if nargin < 3; saveFigABS = []; end

dataMat = eegData;
%% Get PSD for each trial
PxxMat    = [];
fMat       = [];
for iChan = 1:size(dataMat,1)
    for iTrial = 1:size(dataMat,3)
        singleTrial = dataMat(iChan,:,iTrial);
        [Pxx,F] = periodogram(singleTrial,[],length(singleTrial),sampRate);
        PxxMat(iChan,:,iTrial) = Pxx'; %#ok
        fMat(iChan,:,iTrial)    = F'; %#ok
    end
end

%% Calculate IAF / get peaks

%average across all trials for each channel
avgChanPxx   = nanmean(PxxMat,3);

% only look at frequencies of interest
allFreq = fMat(1,:,1);
freqLim = (allFreq >= rangeOfint(1) & allFreq <= rangeOfint(2));
freqRused = allFreq(freqLim)';
powRmat   = avgChanPxx(:,freqLim)';
PxxRestricted = PxxMat(:,freqLim,:);
%% get the mean power density of each frequency across all channels,
% fit it to a gaussian and get predicted values
avgRaw = mean(powRmat,2);
%freqPowerVarRaw = var(powRmat,[],2);
[ avgfreq] = fn_getPeakData( freqRused,avgRaw );
peakAlphaRaw = avgfreq.YHat_pksVal;

%% get the mean power of each frequency weighted by the frequency
%take the average across all channels / trials and multiply them by their frequency
% I believe this is the center of gravity approach
wtPowRmat = powRmat.*repmat(freqRused,1,size(powRmat,2));
avgWt = mean(wtPowRmat,2);
%freqPowerVarWT = var(wtPowRmat,[],2);
[ wtfreq] = fn_getPeakData( freqRused,avgWt );
peakAlphaWT = wtfreq.YHat_pksVal;
%% Need to check for consistency between the 2 plots
errorSub = 0;
for i = 1:2
    runAvgCheck = 0;
    if i == 1 && length(avgfreq.YHat_pksVal) > 1
        chkFreq = avgfreq;
        %chkVar  = freqPowerVarRaw;
        runAvgCheck = 1;
        %         if length(wtfreq.YHat_pksVal) == 1
        %             [~, tloc ] = min(abs(chkFreq.YHat_pksVal - wtfreq.YHat_pksVal));
        %             tPeak = chkFreq.YHat_pksVal(tloc);
        %         end
    end
    if i == 2 && length(wtfreq.YHat_pksVal) > 1
        chkFreq = wtfreq;
        %chkVar  = freqPowerVarWT;
        runAvgCheck = 1;
        %         if length(avgfreq.YHat_pksVal) == 1
        %             [~, tloc ] = min(abs(chkFreq.YHat_pksVal - avgfreq.YHat_pksVal));
        %             tPeak = chkFreq.YHat_pksVal(tloc);
        %         end
    end
    if runAvgCheck > 0
        
        %         sortVar   = sort(chkVar(chkFreq.YHat_pksLoc))';
        %         minVarLoc = find(chkVar == sortVar(1));
        %         minVarpeak = chkFreq.YHat_pksVal(chkFreq.YHat_pksLoc == minVarLoc);
        
        modrange  = [8 12];
        limPeak = chkFreq.YHat_pksVal(chkFreq.YHat_pksVal >= modrange(1) & chkFreq.YHat_pksVal <= modrange(2));
        usePeak = limPeak;
        
        if length(limPeak) > 1
            [~, subloc ] = min(abs(chkFreq.YHat_pksVal - chkFreq.raw_maxVal));
            subPeak = chkFreq.YHat_pksVal(subloc);
            usePeak = subPeak;
        end
        
        if i == 1  ; peakAlphaRaw = usePeak;
        elseif i == 2 ; peakAlphaWT = usePeak;
        else
            errorSub = 1;
        end
    end
end
%% create figure for subject identification
if ~isempty(saveFigABS)
    h = figure;
    plotChans  = powRmat;    %% plot mean values
    plotRaw       = avgfreq.avg;
    plotPeaks  = avgfreq.YHat_pksVal;
    plotYhatMax= avgfreq.YHat_maxVal;
    plotavgMax = avgfreq.raw_maxVal;
    plotf      = avgfreq.f;
    plotYHat   = avgfreq.YHat;
    plotChosen = peakAlphaRaw;
    
    subplot(4,1,1);
    plotTitle = 'Raw - Gaussian Curve';
    createIAFplot(plotf,freqRused,plotChans,plotPeaks,plotYhatMax,plotYHat,plotRaw,plotavgMax,plotTitle,plotChosen)
    subplot(4,1,2);
    plotTitle = 'Raw - Channel Power';
    createIAFplot([],freqRused,plotChans,plotPeaks,plotYhatMax,plotYHat,plotRaw,plotavgMax,plotTitle,plotChosen)
    
    %% plot weighted
    plotChans  = wtPowRmat;    %% plot mean values
    plotRaw    = wtfreq.avg;
    plotPeaks  = wtfreq.YHat_pksVal;
    plotYhatMax= wtfreq.YHat_maxVal;
    plotavgMax = wtfreq.raw_maxVal;
    plotf      = wtfreq.f;
    plotYHat   = wtfreq.YHat;
    plotChosen = peakAlphaWT;
    
    subplot(4,1,3);
    plotTitle = 'Gravity - Gaussian Curve';
    createIAFplot(plotf,freqRused,plotChans,plotPeaks,plotYhatMax,plotYHat,plotRaw,plotavgMax,plotTitle,plotChosen)
    
    subplot(4,1,4);
    plotTitle = 'Gravity - Channel Power';
    createIAFplot([],freqRused,plotChans,plotPeaks,plotYhatMax,plotYHat,plotRaw,plotavgMax,plotTitle,plotChosen)
    
    saveas(h,[saveFigABS,'-IAF'],'fig') % it saves with file name picture.
    print(h,[saveFigABS,'-IAF'],'-dpng','-r300');
    close(h);
end
peakAlphaWT = round(peakAlphaWT*10)/10;
peakAlphaRaw = round(peakAlphaRaw*10)/10;
if errorSub == 1; error('check IAF');end
%% Other ways to calculate AIF
if 1 == 0
    % weight each channel seperately and find the max value for each channel,
    % then average the corrosponding frequencies together
    weightChans = powRmat.*repmat(freqRused,1,size(powRmat,2));
    [~,indx] = max(weightChans);
    mean(freqRused(indx));
    
    
    %%calculate a gaussian curve for each channel, find the max value of
    % each gaussian curve and average together
    for ii = 1:size(weightChans,2)
        weightedf = fit(freqRused,weightChans(:,ii),'gauss2');
        gVals(:,ii) = weightedf(freqRused); %#ok
    end
    [~,gloc] = max(gVals);
    mean(freqRused(gloc));
end


end

function [] = createIAFplot(f,freqRused,plotChans,plotPeaks,plotMax,YHatRaw,yRaw,plotavgMax,plotTitle,plotChosen)
if ~isempty(f)
    plot(f,freqRused,plotChans);
else
    plot(freqRused,plotChans);
end
hold on
line('XData', freqRused, 'YData', YHatRaw, 'LineStyle', '- -','LineWidth', 3, 'Color','r')
line('XData', freqRused, 'YData', yRaw , 'LineStyle', '- -','LineWidth', 3, 'Color','k')
val_yMax = max(max(plotChans));
val_yMax = val_yMax+val_yMax*.1;
ylim([0 val_yMax])

for i = 1:length(plotPeaks)
    line('XData',[plotPeaks(i) plotPeaks(i)], 'YData', ylim, 'LineStyle', '-','LineWidth', 5, 'Color','g')
end

line('XData',[plotMax plotMax], 'YData', ylim, 'LineStyle', '-','LineWidth', 2, 'Color','r')
line('XData',[plotavgMax plotavgMax], 'YData', ylim, 'LineStyle', '-','LineWidth', 2, 'Color','k')
line('XData',[plotChosen plotChosen], 'YData', ylim, 'LineStyle', '-.','LineWidth', 5, 'Color','b')
title(plotTitle);
hold off
b = gca; legend(b,'off');
end

function [ freq] = fn_getPeakData( freqRused,avg )
freq.freqs = freqRused;
freq.avg   = avg;
% fit a gaussian to the average head frequency power over selected freq range
freq.f = fit(freqRused,avg,'gauss2');
% calculate predicted values
freq.YHat = freq.f(freqRused);

%create predicted values of the gaussian curve and the peaks
[~, freq.YHat_pksLoc] = findpeaks(freq.YHat);
freq.YHat_pksVal      = freqRused(freq.YHat_pksLoc)';
freq.YHat_pksLoc      = freq.YHat_pksLoc';
%find the max value of the gaussian curve and select the corrosponding
%frequency value
[~,freq.YHat_maxloc] = max(freq.YHat);
freq.YHat_maxVal     = freqRused(freq.YHat_maxloc);

[~,freq.raw_maxloc] = max(avg);
freq.raw_maxVal     = freqRused(freq.raw_maxloc);


end