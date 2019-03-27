function [ tfData,outD ] = fdtp_run_wavelet( incfg, data )
%fdtp_run_wavelet: the fieldtrip package requires that the time values in
%'data.time' are in seconds. this is required inorder to appropriately apply
% a frequnecy data
%
% tfData.powspctrm = abs(tfData.fourierspctrm).^2;
% tfData.instphase = angle(tfData.fourierspctrm);
% freqnew=ft_checkdata(tfData,'cmbrepresentation','sparsewithpow');
if 1 == 0
    incfg = [];
    incfg.timeOfInt = [-500 2000];
    incfg.freqOfInt = 2:2:10;
    incfg.numCycles = 5;
    incfg.padLength = [];
end

if nargin < 2; incfg = []; end

%% Check for the matlab toolbox: fieldtrip
outscripts_called = {'ft_freqanalysis'};
for ii = 1:length(outscripts_called)
    chkfdtp = which(outscripts_called{ii});
    if isempty(chkfdtp); error(['This function requires the fieldtrip ',...
            'toolbox, please add t to your matlab path and run ,',...
            outscripts_called{ii},'.m']);
    end
end

%% Defining Morlet wavelet parameters:
% which frequencies are we interested in processing
if ~isfield(incfg,'freqOfInt');    incfg.freqOfInt = 3:2:31; end
% how many wavelet cycles before signal tapers down to zero, smaller =
% better temporal resolution, larger = better spectral resolution
if ~isfield(incfg,'numCycles');    incfg.numCycles = 5; end

%% Setup Epoch time and parameters
%fieldtrip automaticly ussumes everything is in seconds (this will switch
%the times into seconds for the required fieldtrip operations, and then
%switch it back after the processing has been completed)
if ~isfield(incfg,'insecs');     incfg.insecs = 1; end
% Data should include some buffer zones (due to signal loss in wavlet
% transform), default is to use the whole epoch
if ~isfield(incfg,'timeOfInt');    incfg.timeOfInt = []; end
% padLength: How much time to add to each epoch, this should be in the same
% time resolution as the other time parameters
if ~isfield(incfg,'padLength');    incfg.padLength = []; end
% fliping the epoch will do modify each trial by mirroring it around each
% side of the epoch 'no': leaves the epoch alone and makes no adjustments,
% 'yes' mirrors the entire epoch around the begining and end point, 'toi':
% mirrors the entire epoch around the minimum and maximum time of interest
% points
if ~isfield(incfg,'flipEpoch'); incfg.flipEpoch = 'no'; end %'no','yes','toi'
% a number 0 - 1 to indicate the proportion of the Epoch to mirror around
if ~isfield(incfg,'flipSize');  incfg.flipSize  = .5; end

%% Output data parameters:
% use 50hz sample rate after frequency decomposition
% reducing sample rate, this should be in the same time resolution as the
% data. if the data is in ms so should this be)
if ~isfield(incfg,'freqTimeInterval');  incfg.freqTimeInterval= .02; end
% incfg.chanlabels = {'Fz','Cz','Pz'}; {'all'}: use all electrodes (not
% just head electrodes); leave blank to just run on head electrodes
if ~isfield(incfg,'chanlabels');     incfg.chanlabels = {}; end
% output type is which data we are interested in (power:'pow');
%   (cross spectral density (coherence): 'csd'); ('fourier')
if ~isfield(incfg,'outputType');     incfg.outputType = 'pow'; end

%% Define in function variables
inData    = data;
freqOfInt = incfg.freqOfInt;
numCycles = incfg.numCycles;
padLength = incfg.padLength;
timeOfInt = incfg.timeOfInt;
insecs    = incfg.insecs;
flipEpoch = incfg.flipEpoch;
flipSize  = incfg.flipSize;
freqTimeInterval = incfg.freqTimeInterval;
chanlabels = incfg.chanlabels;
outputType = incfg.outputType;

dimordcell = strsplit(inData.dimord,'_');
dim_chan = find(ismember(dimordcell,'chan') == 1);
dim_time = find(ismember(dimordcell,'time') == 1);
dim_other = find(~ismember(dimordcell,{'chan','time'}) == 1);
if length(dim_other) > 1; error('Input data should not have more than 3 dimensions'); end

%% Check if time values are in ms, and if so convert to seconds
if ~insecs
    freqTimeInterval = freqTimeInterval/1000;
    if ~isempty(padLength); padLength = padLength / 1000; end
    if ~isempty(timeOfInt); timeOfInt = timeOfInt / 1000; end
    if iscell(inData.time)
        for ii = 1:length(inData.time)
            inData.time{ii} = inData.time{ii}/1000;
        end
    elseif isnumeric(inData.time)
        inData.time = inData.time / 1000;
    end
end
%% modify data based on desire to flip
flipDetails.type = flipEpoch;
if ~strcmpi(flipEpoch,'no')
    timeIncrement = (1000 / inData.fsample / 1000);
    % If time is numeric, create a cell array for values
    if isnumeric(inData.time)
        timeCell = cell(1,size(inData.trial,dim_other));
        for ii = 1:length(timeCell)
            timeCell{ii} = inData.time;
        end
    elseif iscell(inData.time)
        timeCell = inData.time;
    end
    % If trial is numeric, convert into a cell array
    if isnumeric(inData.trial)
        dataCell = cell(1,size(inData.trial,dim_other));
        for ii = 1:length(dataCell)
            if dim_other == 1; dataCell{ii} = squeeze(inData.trial(ii,:,:)); end
            if dim_other == 2; dataCell{ii} = squeeze(inData.trial(:,ii,:)); end
            if dim_other == 3; dataCell{ii} = squeeze(inData.trial(:,:,ii)); end
        end
    elseif iscell( inData.trial)
        dataCell = inData.trial;
    end
    % create record
    flipDetails.timeInc = timeIncrement;
    flipDetails.orgTime = timeCell{1};
    flipDetails.orgSize = length(timeCell{1});
    % Process each trial and time point with flip details
    for ii = 1:length(dataCell);
        tmpTime = timeCell{ii}; tmpData = dataCell{ii};
        flip_len = round(length(tmpTime)*flipSize);
        % Process and create a new time array with additional values
        flip_front_stop = tmpTime(1)-flip_len*timeIncrement;
        flip_front = fliplr(tmpTime(1)-timeIncrement:-timeIncrement:flip_front_stop);
        flip_back_stop = tmpTime(end)+flip_len*timeIncrement;
        flip_back = tmpTime(end)+timeIncrement:timeIncrement:flip_back_stop;
        timeCell{ii} = horzcat(flip_front,tmpTime,flip_back);
        % verify that the data is in chans * time dimensions
        if dim_time < dim_chan; tmpData = tmpData'; end
        % Flip the data
        front_data = fliplr(tmpData(:,1:flip_len));
        back_data  = fliplr(tmpData(:,end-flip_len+1:end));
        tmp2data   = horzcat(front_data,tmpData,back_data);
        % if this was in time * Chan dimensions, transpose back
        if dim_time < dim_chan; tmp2data = tmp2data'; end
        dataCell{ii}  = tmp2data;
    end
    % create record
    flipDetails.newTime = timeCell{1};
    flipDetails.newSize = length(timeCell{1}); 
    
    % If time is numeric, set output to be numeric
    if isnumeric(inData.time); inData.time = timeCell{1};
    else inData.time = timeCell;
    end
    
    % If trial is numeric, set output to be numeric
    if isnumeric(inData.trial)
        tmpMAT = nan(size(inData.trial));
        for ii = 1:size(tmpMAT,dim_other)
            if dim_other == 1; tmpMAT(ii,:,:) = dataCell{ii}; end
            if dim_other == 2; tmpMAT(:,ii,:) = dataCell{ii}; end
            if dim_other == 3; tmpMAT(:,:,ii) = dataCell{ii}; end
        end
        inData.trial = tmpMAT;
    elseif iscell( inData.trial)
        inData.trial = dataCell;
    end

end

%% Grab time values and verify they are in a numeric array
if iscell(inData.time);   timevals = inData.time{1}; end
if isnumeric(inData.time);timevals = inData.time; end

%% Pad Length = the amount of zeros around each epoch that we want to add
% round the length of the trial up to the closest whole number and add 4 (in
%seconds
if isempty(padLength);
    epochLims  = [timevals(1),timevals(end)];
    epochRange = range(epochLims);
    padLength  = ceil(epochRange)+4;
end

%% if no spesific channels are selected, run on all head channels
if isempty(chanlabels)
    chanInds = ~ismember(lower(inData.label),...
        lower({'EXG1','EXG2','EXG3','EXG4','EXG5','EXG6','EXG7','EXG8','Blink','Horz'}));
    chanlabels = inData.label(chanInds);
elseif strcmpi(chanlabels,'all')
    chanlabels= inData.label;
end

%% Default the time range of interest if none is spesified (this will take the minimum time for the lowest frequnecy of interest)
if isempty(timeOfInt)
    rmVal = ((1000/min(freqOfInt)/1000)*numCycles)/2;
    timeOfInt = [timevals(1)+rmVal,timevals(end)-rmVal];
end

%% wavelet details

if length(numCycles) == 1
    cycleArray = numCycles*ones(1,length(freqOfInt));
elseif length(numCycles) == length(freqOfInt);
    cycleArray = numCycles; %incase we setup a complex wavelet
end

% Calculate Spectral bandwidth  = (frequency / (number of cycles)) * 2
SpBand = (freqOfInt ./ cycleArray) * 2;
SpBandmin = freqOfInt - (SpBand /2);
SpBandmax = freqOfInt + (SpBand /2);
% Calculate Wavelet duration (temporal flitering) = ((numberof cyles)/frequency)/ pi
waveDur = (cycleArray ./ freqOfInt) / pi;

tf_metrics = horzcat(freqOfInt',cycleArray',SpBand',SpBandmin',SpBandmax',(round(waveDur*1000))');
tf_out = vertcat({'freq(hz)','cycles','SpBandrange','SpBandmin','SpBandmax','waveDur(ms)'},num2cell(tf_metrics));

%% run analysis
disp('Running Wavelet Conversion');

tic
%trial settings
cfg = [];
cfg.trials      = 'all';
cfg.keeptrials  = 'yes';
cfg.channel     = chanlabels;

%TF settings (get power and cross channel coherence, complex fourier)
cfg.method = 'wavelet';
cfg.output = outputType; %'fourier'; % 'powandcsd';
cfg.pad    = padLength;
cfg.width  = numCycles;
cfg.foi    = freqOfInt;
cfg.toi    = timeOfInt(1):freqTimeInterval:timeOfInt(2);

% I don't think this actually matters at all, keeping in for the hell of it
% (makes a mostly meaningless error go away too)
testTOI = timeOfInt(1):freqTimeInterval:timeOfInt(2);
corrTOI = nan(1,length(testTOI));
for iT = 1:length(corrTOI); corrTOI(iT) = timevals(nearest(timevals,testTOI(iT))); end
cfg.toi    = corrTOI;

tfData   = ft_freqanalysis(cfg, inData);

tProcTime = toc;
%% Analysis Details
outD.datetime   = fix(clock);
outD.outputType = outputType;
outD.padLength  = padLength;
outD.numCycles  = numCycles;
outD.freqOfInt  = freqOfInt;
outD.toi        = cfg.toi;
outD.procTime   = tProcTime;
outD.flipDetails= flipDetails;
outD.diags      = tf_out;
outD.nbchan     = length(tfData.label);
outD.chanlabels = tfData.label;
outD.srate  = (length(tfData.time)/(range(tfData.time)/1));
outD.times  = tfData.time;
outD.xmin   = outD.times(1);
outD.xmax   = outD.times(end);
outD.pnts   = length(tfData.time);



end

