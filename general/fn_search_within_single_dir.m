function [ foundfiles, chkError ] = fn_search_within_single_dir( path_ABS, fileLookUp, forceStop )
%Function will search inside a directory of files that match a spesific
%format found in 'fileLookUp', if it finds more than 1 file, it returns an
%error and force stops the function, this can be overridden by passing
%through the forceStop parameter to 0 (1 is default)
% return all files in folder
% [ foundfiles, chkError ] = fn_search_within_single_dir( path_ABS ) 
% return all files in folder that match the fileLookup (if more than one match, return an error)
% [ foundfiles, chkError ] = fn_search_within_single_dir( path_ABS, fileLookUp )
% df
if 1 == 0
    path_ABS = 'C:\eegTest\epoch';
    fileLookUp = {'*.ct_0001','*.ct_0002'};
    forceStop = 0;
end

if nargin < 2; fileLookUp = []; end
if nargin < 3; forceStop = 1; end
    
chkError = [];
%% if file lookup is empty return all files in folder
if isempty(fileLookUp)
    inFileDir = dir(path_ABS);
    i2 = 0;
    for i1 = 1:length(inFileDir)
        if inFileDir(i1).isdir == 0
            i2 = i2 + 1;
            foundfiles{i2} = inFileDir(i1).name; %#ok
        end
    end
    
else
    %% If file look up is not empty only return those files that match 
    if ~iscell(fileLookUp); fileLookUp = {fileLookUp};end
    foundfiles = cell(1,length(fileLookUp));
    
    for i1 = 1:length(fileLookUp)
        inFileDir = dir(fullfile(path_ABS,[fileLookUp{i1}]));
        if size(inFileDir,1) > 1;
            errorCell = {i1, fileLookUp{i1}, size(inFileDir,1)};
            chkError = vertcat(chkError,errorCell); %#ok
            foundfiles{i1} = 'error';
        else
            foundfiles{i1} = inFileDir.name;
        end
    end
    
    if forceStop == 1 && ~isempty(chkError)
        disp(chkError)
        error('More than one file found with search parameters')
    end
end

