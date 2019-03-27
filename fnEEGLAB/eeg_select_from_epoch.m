function [ newEpochList ] = eeg_select_from_epoch( epochlist, fieldOfInt, valOfInt, rmEventprefix )
%This script returns a data structure containing each epoch, and only the
%event spesified in the 'fieldOfInt' with the value spesified in
%'valOfInt'.

if 1 == 0 ; epochlist = EEG.epoch;end

if nargin < 2; fieldOfInt = 'eventlatency'; end
if nargin < 3; valOfInt = 0; end
if nargin < 4; rmEventprefix = 1; end

if ~ischar(fieldOfInt); error('Variable : fieldOfInt; needs to be a string'); end
if ~isstruct(epochlist); error('Variable : epochlist; needs to be a data structure'); end
    
%% Find the data that corrosponds to the event of interest within each epoch and grab the data for that event only
grabfields = fieldnames(epochlist)';
newEpochList = [];
for ii = 1:size(epochlist,2)
   valIndx = cell2mat(epochlist(ii).(fieldOfInt)) == valOfInt;
   newEpochList(ii).index = ii; %#ok
   
   for i2 = 1:size(grabfields,2)
       nField = grabfields{i2};
       if rmEventprefix == 1
           if ~isempty(strfind(grabfields{i2},'event')) && length(grabfields{i2}) > 5
               nField = grabfields{i2}(6:end);
           end
       end
           
       if iscell(epochlist(ii).(grabfields{i2})(valIndx))
           newEpochList(ii).(nField) = epochlist(ii).(grabfields{i2}){valIndx}; 
       else
           newEpochList(ii).(nField) = epochlist(ii).(grabfields{i2})(valIndx); 
       end
   end
end

