function [ found_indx, found_args, rej_indx, rej_args ] = fn_struct_search_fields( inDataStruct, field_ds, rangeChk )
%This function will sarch within the first level of a data structure of a
%given field and then return the index numbers and values for that were
%found. Script ignores case when searching for items
% Search values should be either a string, a cell array of strings, a
% single number, or a numerical array. If an array is passed through, it
% will return true if any value is passed through
% Passing through multiple fields will return only the index values that
% match all field names and values
%
% Script will only work on fields in inDataStruct, that are of datatypes
% 'char' or a single numeric.(Cell or Numeric Arrays will always return
% false) This is coded inorder to keep ambiguities out of searching the
% data
%
% rangeChk = 1 or 0: 1 = true. this switch only applies if the requested
% values are a 1 x 2 numeric array, which sets the upperward and lower
% bound limits, if the length is greater than 2 then it only search for
% exact matches

% Example:

% Only return index values that match the value
% field_ds.name1 = 'value1';
% field_ds.name3 = 2;

% Return index values that match any value passed through
% field_ds.name2 = {'value1','value2'};
% field_ds.name4 = [2 34 57];

if 1 == 0
    inDataStruct = GP.data_epochs;
    field_ds = [];
    %     field_ds.acc = 'correct';
    %     field_ds.conf_attn = {'high','low'};
    %field_ds.bepoch = [1,3,5,7];
    field_ds.bini = [3,22];
end

if nargin < 2; field_ds = []; end
if nargin < 3; rangeChk = []; end

if isempty(field_ds)
    error('no selection criteria passed through')
end


%% Get search field names and verify they exist and contain data
verifyFields = fieldnames(field_ds); ii = 1;
for iField = 1:length(verifyFields)
    if ~isfield(inDataStruct,verifyFields{iField})
        error(['Search field does not exist: ' verifyFields{iField}]);
    end
    % If a search field contains no data, ignore it
    if ~isempty(field_ds.(verifyFields{iField}))
        searchFields{ii} = verifyFields{iField};
        ii = ii + 1;
    end
end
disp('All Search Fields found');
%% initialize matrix for found indices
found_mat = zeros(length(inDataStruct),length(searchFields));

%% Find requested data
%For each search parameter
for iField = 1:length(searchFields)
    %Select field name and test value/s
    testField = searchFields{iField};
    testVal   = field_ds.(testField);
    
    % If we are testing against string values in 'inDataStruct', convert to
    % a cell array
    if ischar(testVal); testVal = {testVal}; end
    
    %Check each Value
    foundindx = zeros(1,length(inDataStruct));
    for iIndx = 1:length(inDataStruct)
        dataVal = inDataStruct(iIndx).(testField);
        
        %Convert to cell string (cell array for strings)
        if ischar(dataVal); dataVal = {dataVal}; end
        
        %If data to be checked is a cell array with 1 cell
        if iscell(dataVal) && iscell(testVal) && length(dataVal) == 1
            % If the string was found in the passed through string options
            if ismember(lower(dataVal),lower(testVal))
                foundindx(iIndx) = 1;
            end
        end
        
        %If data to be checked is a single number
        if isnumeric(dataVal) && isnumeric(testVal) && length(dataVal) == 1
            % If the number was found in the passed through numeric value/s
            if rangeChk == 1 & length(testVal) == 2
                if dataVal >= min(testVal) && dataVal <= max(testVal)
%                     disp([num2str(dataVal),' >= ',num2str(min(testVal)),'|',...
%                           num2str(dataVal),' <= ',num2str(max(testVal))])
                    foundindx(iIndx) = 1;
                end
            else
                if sum(dataVal == testVal) > 0
                    foundindx(iIndx) = 1;
                end
            end
        end
        
        if length(dataVal) > 1
            warning(['Data value has a size greater than 1: dataVal size=',num2str(length(dataVal))])
            disp(dataVal);
        end
        found_mat(:,iField) = foundindx';
    end
end

% Find the convergence of our search conditions
conver_mat = sum(found_mat,2);
numConds   = size(found_mat,2);

found_indx = find(conver_mat == numConds);
found_args = inDataStruct(found_indx);

rej_indx = find(conver_mat ~= numConds);
rej_args = inDataStruct(rej_indx);




