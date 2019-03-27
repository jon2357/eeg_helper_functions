function [ npat ] = aperture_create_pat( eegdata, incfg )
% Generic function for creating an aperture pattern file
%
% eegdata = 4D numerical matrix with the dims: trials, chan, time, freq
% (default based on fieldtrip frequnecy output)
%
% incfg.chan_cell = 1 x N cell array with the channel labels in order of index
%   location ('ch1' = index location 1)

% incfg.time_cell = 1 x N cell array with time value in milliseconds 
%   (can be single value or 1 x N numeric array [min ...  max])
%
% incfg.time_label = 1 x N cell array (same size as: time_cell), that contains
%   user spesified labels for each time bin and over rides automatically
%   generated labels
%
% incfg.freq_cell  = 1 x N cell array with freq value in Hz
%   (can be single value or 1 x N numeric array [min ... max])
%
% incfg.freq_label = 1 x N cell array (same size as: freq_cell), that contains
%   user spesified labels for each freq bin and over rides automatically
%   generated labels
%
% incfg.event_struct = Data structure with a length the same as the number
% of epochs/ trials in the data set. Each sub varaible contains trial
% spesific information.

if nargin < 1; eegdata = []; end
if nargin < 2; incfg   = []; end

%% Create Test data
if isempty(eegdata) && isempty(incfg)
    incfg.event_struct = {};
    incfg.chan_cell = {'c1','c2','c3','c4','c5'};
    incfg.time_cell = {100.89,[200 400.7],500,600,700.9,[800 900]};
    incfg.time_label ={};
    incfg.freq_cell = {3.456,[5.334 8.986],10.89, [12.34  14.56]};
    incfg.freq_label ={'test1','test2','test3','test4'};
    eegdata = rand(50,length(incfg.chan_cell),...
        length(incfg.time_cell),length(incfg.freq_cell));
end

%% Setup Default fields
if ~isfield(incfg,'name');      incfg.name       = 'dataset'; end
if ~isfield(incfg,'file_path'); incfg.file_path   = ''; end
if ~isfield(incfg,'file_name'); incfg.file_name   = ''; end
if ~isfield(incfg,'source');    incfg.source     = 'sub'; end
if ~isfield(incfg,'chan_cell'); incfg.chan_cell  = {}; end % needs to be a cell array of strings
if ~isfield(incfg,'time_cell'); incfg.time_cell  = {}; end %does not have to be a cell array, can also be a numerical array
if ~isfield(incfg,'time_label');incfg.time_label = {}; end % cell array of strings
if ~isfield(incfg,'time_metric');incfg.time_metric = 's'; end % cell array of strings
if ~isfield(incfg,'freq_cell'); incfg.freq_cell  = {}; end  %does not have to be a cell array, can also be a numerical array
if ~isfield(incfg,'freq_label');incfg.freq_label = {}; end % cell array of strings
if ~isfield(incfg,'event_struct');incfg.event_struct = {}; end %data structure

% incfg.in_dimord = not coded yet
if ~isfield(incfg,'in_dimord');incfg.in_dimord = {'rpt','chan','freq','time'}; end    

%% define local variables
in_name     = incfg.name;
in_source   = incfg.source;
file_abs    = fullfile(incfg.file_path,incfg.file_name);
chan_cell   = incfg.chan_cell;
time_cell   = incfg.time_cell;
time_label  = incfg.time_label;
time_metric = incfg.time_metric;
freq_cell   = incfg.freq_cell;
freq_label  = incfg.freq_label;
event_struct= incfg.event_struct;

%% Reshape Data if required, output data needs to be in (trials, chan, time, freq)
if ~isempty(incfg.in_dimord)
    if ~iscell(incfg.in_dimord)
        Z = textscan(incfg.in_dimord,'%s','Delimiter','_')';
        dimordcell = Z{:}';
    else
        [ dimordcell ] = incfg.in_dimord;
    end
    cIndx = find(ismember(dimordcell,'chan'));
    tIndx = find(ismember(dimordcell,'time'));
    fIndx = find(ismember(dimordcell,'freq'));
    eIndx = find(ismember(dimordcell,{'rpt','rpttap','epoch'}));    
    eegdata = permute(eegdata,[eIndx,cIndx,tIndx,fIndx]); %disp([eIndx,cIndx,tIndx,fIndx])
end
%% Top Level Aperture Data Structure
npat.name   = in_name;    % string : name of dataset
npat.file   = file_abs;   % string : absolute path and file name (with extention) of saved dataset
npat.source = in_source;  % string : Subject? name of source file?
npat.params = struct([]);  % Data Structure : Contains processing details
npat.dim    = [];  % Data Structure : Contains details about trials, chan, time, freq
npat.modified = false;% Binary : 1: if data structure has been modified since last open (0: default)
npat.mat  = eegdata;    % Numerical Matrix (Single) : 4 D (trials, chan, time, freq)
npat.fig  = [];    % stored figures
npat.stat = [];    % stored stats

%% Create Event dim

% If event structure was not passed through fake one
if isempty(event_struct); 
    for ii = 1:size(eegdata,1); 
        event_struct(ii).trial   = ii; 
        event_struct(ii).cond_AB = 'A'; 
        if rem(ii,2); event_struct(ii).cond_AB = 'B'; end 
        event_struct(ii).cond_12 = 1;
        if ii > size(eegdata,1)/2;event_struct(ii).cond_12 = 2; end
    end
end

% Build event data structure
pat_dim_ev.name   = 'study'; % String : Name of study (example: 'study')
pat_dim_ev.source = in_source; % String : Subject? name of source file?
pat_dim_ev.file   = ''; % string : absolute path and file name (with extention) of saved dataset
pat_dim_ev.modified = false; % Binary : 1: if data structure has been modified since last open (0: default)
pat_dim_ev.stat = [];  % stored stats

% Data Structure (variable sub fields with behavoiral data for each epoch)
% should contain an entry for each epoch
pat_dim_ev.mat  = event_struct;  

% Number : Single value indicating number of data points within dimension (720 = 720 epochs)
pat_dim_ev.len = length(pat_dim_ev.mat); 

% Copy event structure into pattern structure
npat.dim.ev = pat_dim_ev;
%% Create Channel dim
% If channel labels were not passed through create them
if isempty(chan_cell); 
    chan_cell = cell(1,size(eegdata,2)); 
    for ii = 1:length(chan_cell); chan_cell{ii} = horzcat('ch',num2str(ii)); end
end

% Create other channel matrix fields
chan_indx = 1:length(chan_cell);

% Build channel data structure
pat_dim_chan.type = 'chan'; % String : dimension label
pat_dim_chan.file = '';     % String : absolute path and file name (with extention) of saved dataset
pat_dim_chan.modified = false; % Binary : 1: if data structure has been modified since last open (0: default)

pat_dim_chan.mat = [];
for iC = 1:length(chan_indx)
    pat_dim_chan.mat(iC).number = chan_indx(iC);  % Number : index number for each channel
    pat_dim_chan.mat(iC).label = chan_cell{iC};   % String : Label for each channel (corrosponding to the index number)
end
% Number : Single value indicating number of data points within dimension (32 = 32 channels)
pat_dim_chan.len = length(pat_dim_chan.mat); 

% Copy chan structure into pattern structure
npat.dim.chan = pat_dim_chan;

%% Create Time dim
% If time data was not passed through make it up
if isempty(time_cell); 
    time_cell = cell(1,size(eegdata,3)); 
    for ii = 1:length(time_cell); time_cell{ii} = ii*10; end
end

% Build time data structure
pat_dim_time.type = 'time'; % String : dimension label
pat_dim_time.file = ''; % String : absolute path and file name (with extention) of saved dataset
pat_dim_time.modified = false;  % Binary : 1: if data structure has been modified since last open (0: default)

pat_dim_time.mat = []; % Data Structure
for iT = 1:length(time_cell)
    if iscell(time_cell(iT))
        curr_time = time_cell{iT};
    else
        curr_time = time_cell(iT);
    end
    
    if length(curr_time) > 1
        % 1 x 2 Numeric Array : [max min] in milliseconds (could also be single value)
        pat_dim_time.mat(iT).range = [min(curr_time),max(curr_time)];
        % Number : mean time between range values
        pat_dim_time.mat(iT).avg   = nanmean(curr_time);
         % String : example: 'MINtoMAXms'
         if strcmpi(time_metric,'ms')
            pat_dim_time.mat(iT).label = [num2str(round(min(curr_time))),'to',num2str(round(max(curr_time))),time_metric]; 
         else
            pat_dim_time.mat(iT).label = [num2str(min(curr_time)),'to',num2str(max(curr_time)),time_metric]; 
         end
    elseif length(curr_time) == 1    
        pat_dim_time.mat(iT).range = curr_time;
        pat_dim_time.mat(iT).avg   = curr_time;
        if strcmpi(time_metric,'ms')
            pat_dim_time.mat(iT).label = [num2str(round(curr_time)),time_metric];
        else
            pat_dim_time.mat(iT).label = [num2str(curr_time),time_metric];
        end
    end
    % If a label was passed through use it
    if ~isempty(time_label);pat_dim_time.mat(iT).label = time_label{iT}; end
end
% Number : Single value indicating number of data points within dimension (2 = 2 time points)
pat_dim_time.len  = length(pat_dim_time.mat); 

% Copy time structure into pattern structure
npat.dim.time = pat_dim_time;
%% Create Freq dim
% If freq data was not passed through make it up
if isempty(freq_cell); 
    freq_cell = cell(1,size(eegdata,4)); 
    for ii = 1:length(freq_cell); freq_cell{ii} = ii; end
end

% Build freq data structure
pat_dim_freq.type = 'freq'; % String : dimension label
pat_dim_freq.file = ''; % String : absolute path and file name (with extention) of saved dataset
pat_dim_freq.modified = false; % Binary : 1: if data structure has been modified since last open (0: default)

pat_dim_freq.mat = []; % Data Structure
for iF = 1:length(freq_cell)
    if iscell(freq_cell(iF))
        curr_freq = freq_cell{iF};
    else
        curr_freq = freq_cell(iF);
    end
    if length(curr_freq) > 1
        % 1 x 2 Numeric Array : [max min] in milliseconds (could also be single value)  
        pat_dim_freq.mat(iF).range = [min(curr_freq),max(curr_freq)]; 
        % Number : mean between range values
        pat_dim_freq.mat(iF).avg   = nanmean(curr_freq); 
        % String : example: 'Delta'   
        pat_dim_freq.mat(iF).label = [num2str(round(min(curr_freq),1)),'to',num2str(round(max(curr_freq),1)),'Hz']; 
    elseif length(curr_freq) == 1
        pat_dim_freq.mat(iF).range = curr_freq;
        pat_dim_freq.mat(iF).avg   = curr_freq;
        %disp(curr_freq)
        pat_dim_freq.mat(iF).label = [num2str(round(curr_freq,1)),'Hz'];
    end
    % If a label was passed through use it
    if ~isempty(freq_label);pat_dim_freq.mat(iF).label = freq_label{iF}; end
end
% Number : Single value indicating number of data points within dimension (6 = 6 frequencies)
pat_dim_freq.len  = length(pat_dim_freq.mat); 

% Copy time structure into pattern structure
npat.dim.freq = pat_dim_freq;

%% add in some required fields and data points
ep_end_ms =round(range([npat.dim.time.mat.range]));
for i1 = 1:length(npat.dim.ev.mat)
    npat.dim.ev.mat(i1).eegoffset = ep_end_ms * i1;
end

%% Save pattern datastructure if so desired
if ~isempty(incfg.file_path)
    pat = npat;
    if ~exist(incfg.file_path,'dir'); mkdir(incfg.file_path); end
    savefile = pat.file; disp([' -- Saving: ',savefile,'.mat']);
    save(savefile, 'pat');
end

end

