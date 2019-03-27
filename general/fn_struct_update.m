function [ outStruct ] = fn_struct_update( baseStruct, toDo, inputStruct, bkFields, bkPrefix )
%Function will update each data structure in an array of data structures or
%add a data structure to the end of an existing one (fields do not have to
%match)
% to add a new data structure to the existing array, the inputStruct must
% be singular
% to update / add a field to an existing array of data structures, the
% inputStruct must be either singular (to make a direct copy) or the same
% length as the baseStruct.
%
% toDo = 'add' || 'update';
% bkFields = cell array of field names from inputStruct that you want to leave
% a backup of in the vaseStruct data structure. 'bkPrefix' appends a prefix to the
% fields you want to leave while updating. has no effect on newly created
% fields

if 1 == 0
    baseStruct = GP.mod;
    toDo = 'add'; %update
    inputStruct = modch;
    bkFields = {'history'};
    bkPrefix = 'bk_';
end

if nargin < 3; error('Not enough input'); end
if nargin < 4; bkFields = {}; end
if nargin < 5; bkPrefix = []; end

if isempty(bkPrefix); bkPrefix = 'bk_'; end
if ~iscell(bkFields); bkFields = {bkFields};end
%% Get info about base structure
if ~isstruct(baseStruct); baseStruct = struct(); end
baseFields = fieldnames(baseStruct);
baseLen = length(baseStruct);

if ~isstruct(inputStruct); error('inputStruct must be a structure'); end
if isempty(fieldnames(inputStruct)); error('inputStruct must have fields'); end

stopRun = 0; outStruct =[];
%% Check if this is a straight up replace
if length(baseLen) < 1 || isempty(baseFields)
    outStruct = inputStruct;
    stopRun = 1;
elseif ~stopRun && length(baseLen) == 1
    % Check if the baseStruct only has empty fields
    emptyChk = 0;
    for ii = 1:length(baseFields)
        if isempty(baseStruct.(baseFields{ii}));
            emptyChk = emptyChk + 1;
        end
    end
    if emptyChk == ii
        outStruct = inputStruct;
        stopRun = 1;        
    end
    
end

%% Check if we need to modify the data matrix
if ~stopRun
    outStruct = baseStruct;
    outLen    = length(baseStruct);
    outFields = fieldnames(outStruct);
    inFields  = fieldnames(inputStruct);
    % If we just want to add another data structure to our existing
    % structure
    if strcmpi(toDo,'add')
        if length(inputStruct) > 1; error('Can only add one data structure at a time'); end
        for ii = 1:length(inFields)
            outStruct(outLen+1).(inFields{ii}) = inputStruct.(inFields{ii});
        end
        % If we are updating the existing data structure
    elseif strcmpi(toDo,'update')
        if length(inputStruct) ~= 1 || length(inputStruct) ~= length(outStruct)
            error('Input data structure must be singular or the same length as the data structure we want to update');
        end
        %If the input matrix is singular, make it as long as the structure
        %we want to update
        if length(inputStruct) == 1
            inputStruct = repmat(inputStruct,1,length(outStruct));
        end
        % If we want to back up some fields
        if ~isempty(bkFields) && sum(ismember(outFields,bkFields)) > 0
            for iF = 1:length(bkFields)
                for iS = 1:length(outStruct)
                    if isfield(outStruct(iS),bkFields{iF})
                        outStruct(iS).([bkPrefix,bkFields{iF}]) = outStruct(iS).(bkFields{iF});
                    end
                end
            end
        end
        % Modify or create new field and update the (array of) data
        % structures
        for iF = 1:length(inFields)
            for iS = 1:length(outStruct)
                if isfield(outStruct(iS),inFields{iF})
                    outStruct(iS).(inFields{iF}) = inputStruct(iS).(inFields{iF});
                end
            end
        end

    end
end

