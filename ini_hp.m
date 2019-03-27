function [ output_args ] = ini_hp(rtnVal)
%Initializing function to add the appropriate folder paths to process the
%data. 
%Example: calling: 'ini_hp' from your script initalizes folder structure

%rtnVal: string value of the toolbox info, passing a field name (from
% the data structure: 'hpinfo' returns the value
% Example [ output_args ] = ini_hp('ver'); would return the version number
% from (hpinfo.ver)

if nargin < 1; rtnVal = []; end

%% set matlab session defaults
f1 = figure;
set(0,'DefaultFigureColormap',feval('jet')); % change default color map to jet
close(f1);
%% Toolbox details
hpinfo.ver     = 2;
hpinfo.release = 'wip';
hpinfo.author = 'Jon Strunk';
hpinfo.email  = 'jstrunk@gatech.edu';
hpinfo.cdate  = '12/4/2017';
hpinfo.tested_matlab_ver  = {'R2015a'};

% Info Selection
list_info = fieldnames(hpinfo)';
if ~isempty(rtnVal) && ismember(rtnVal,list_info)
    output_args = hpinfo.(list_info{ismember(list_info,rtnVal)});
else
    output_args = hpinfo;
end

%% Verify Path Structure
if isempty(rtnVal)
    %main_dir = fileparts(whch('ini_gasp'));i
    main_dir = fileparts(which(mfilename));
    %% Interval Folder structure
    addpath(fullfile(main_dir, 'general'));
    addpath(fullfile(main_dir, 'fnEEGLAB'));
    addpath(fullfile(main_dir, 'run_scripts_eeg'));
    addpath(fullfile(main_dir, 'fnFieldtrip'));
    addpath(fullfile(main_dir, 'fnAperture'));
%    addpath(fullfile(main_dir, 'external'));

end
end

