function  [ inData, out_filepath ] = hp_load( input_path_ABS, input_file, spesificVars )
% Function loads in single subject data file
%
% input_path_ABS = String : Absolute path of data file (or folder location)
%
% input_file = String : name of desired data file (located within the
%             input_path_ABS folder)


if nargin < 1; input_path_ABS = [] ;end
if nargin < 2; input_file= []; end
if nargin < 2; spesificVars = []; end

%% if file is passed through without any input pull up a GUI to select the file
if isempty(input_path_ABS) && isempty(input_file)
    defaultFileName = fullfile( pwd, '*.mat');
    [input_file, input_path_ABS] = uigetfile(defaultFileName, 'Select a file');
    if input_file == 0
        % User clicked the Cancel button.
        return;
    end
end

%% File that file exists
full_ABS = fullfile(input_path_ABS,input_file);
if ~exist(full_ABS,'file'); error(['HP:  Data Structure File not found: ',full_ABS]);end

%% Load in Data Structure
disp(['HP:  Loading: ',full_ABS]);

if isempty(spesificVars)
    inData = load(full_ABS,'-mat');
else
    inData = load(full_ABS,'-mat',spesificVars{:}); 
end

%% Return file path
%break down absolute file path
fld_break_down  = strsplit(full_ABS,{'\','/'});

%Update filepath with open location
if isunix
    out_filepath = horzcat('/',strjoin(fld_break_down(1:end-1),'/'));
else
    out_filepath = strjoin(fld_break_down(1:end-1),'\');
end

end




