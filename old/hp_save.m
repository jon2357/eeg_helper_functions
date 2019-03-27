function [ data ] = hp_save( data, out_fld_abs, new_set_name, over_write_existing )
%Saves dataset

if 1 == 0
    out_fld_abs  = pwd;
    new_set_name = [];
    over_write_existing = 0;
end

%% Run data checks
if nargin < 1; error('no dataset spesified'); end
if nargin < 2; out_fld_abs  = [] ;end
if nargin < 3; new_set_name = []; end
if nargin < 4; over_write_existing = 0; end

if ~ischar(out_fld_abs); error('HP: String Input Required: out_fld_abs(ex: C:\place\here)'); end

%% Update Data Structure
if ~isempty(new_set_name)
    data.etc.setname = new_set_name;
end


data.etc.filename  = [data.etc.setname,'.mat'];
data.etc.filepath  = out_fld_abs;

%% Create absolute path 
saveData  = fullfile(data.etc.filepath,data.etc.filename);

%% Check if files exist
if over_write_existing == 0
    file_found = {};
    if exist(saveData) ~= 0
        file_found{length(file_found)+1} = saveData;
    end
    if ~isempty(file_found)
        mCell = vertcat('HP: Files already exist:',file_found');
        returnText = strjoin(mCell','\n');
        error(returnText);
    end
end

%% Save Data Structure, with seperate data file
if ~exist(data.etc.filepath,'dir'); mkdir(data.etc.filepath); end

disp(['HP: Saving: ',saveData]);
save(saveData,'data');



end

