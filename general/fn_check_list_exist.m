function [ returnText, found, notfound ] = fn_check_list_exist(inCell, dtype)
%
% dtype : [], 'var', 'builtin', 'file', 'dir', 'class'
%   example: dtype = 'file';
% inCell ; N x M cell array; Each row spesifies a spesific file / folder to
% verify the existance of. Each column could represent the folder structure
% For example:
%   inCell = {'C:\','eegTest','fld1','sub01','sub01.mat';...
%             'C:\','eegTest','fld1','sub02','sub01.mat'};
%   inCell = {'C:\eegTest\fld1\sub01\sub01.mat';...
%             'C:\eegTest\fld1\sub02\sub01.mat'};

if nargin < 2; dtype = []; end
%% make sure the input is a cell array
if ~iscell(inCell) && ischar(inCell); inCell = {inCell}; end

iNF = 0; iF = 0;
notfound = {}; found = {}; 
for i1 = 1:size(inCell,1)
    chkF = fullfile(inCell{i1,:});
    
    % Identify if value exists
    if isempty(dtype)  
        chkVal = exist(chkF);
    else
        chkVal = exist(chkF,dtype); 
    end
    
    % Add to the found or notfound cell array
    if chkVal == 0;
        iNF = iNF + 1;
        notfound{iNF,1} = chkF;
        notfound{iNF,2} = chkVal;
    else
        iF = iF + 1;
        found{iF,1} = chkF;
        found{iF,2} = chkVal;
    end
end

if isempty(notfound); 
    disp('All Files Found');
    returnText = []; 
else
    mCell = vertcat('Files not found: ',notfound(:,1));
    returnText = strjoin(mCell','\n');
end

end

