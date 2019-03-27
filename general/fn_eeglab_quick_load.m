function [ EEG ] = fn_eeglab_quick_load( input_path_ABS, input_file )
% Function loads in single subject EEGLAB data file
%
% input_path_ABS = String : Absolute path of the folder location)
%
% input_file = String : name of desired data file (located within the
%             input_path_ABS folder)


if nargin < 2
    error('Must include path and file name as seperate string variables'); 
end

%% Load in Data Structure
full_ABS = fullfile(input_path_ABS,input_file);
if ~exist(full_ABS,'file'); error(['Data Structure File not found: ',full_ABS]);end
disp(['FN:  Loading EEGLAB File: ',full_ABS]);

%% Load in EEGLAB data structure (*.set file)
inData = load(full_ABS,'-mat');
EEG = inData.EEG;

%% Load in EEGLAB data 
% (Assumes that the file name in EEG.data is the file name of the data
% [*.fdt] file and that it is in the same folder location

inDataName = fullfile(input_path_ABS,EEG.data);
fid = fopen( inDataName, 'r', 'ieee-le');
data = fread(fid, [EEG.trials*EEG.pnts EEG.nbchan], 'float32');
fclose(fid);
EEG.data = reshape(data,[EEG.nbchan,EEG.pnts,EEG.trials]);

end

