function [EEG ] = eeg_mergeSETFiles( mergeSetFiles, newFileName, wkDir )
%
% mergeSetFiles = {'full file path','newlabel';'full file path',[]};
%   an empty set[] in either place skips the file or renameing the labels
% newFileName = [rootName '-allrej'];

if nargin < 3; wkDir = []; end
ALLEEG = [];
disp('Loading Files to merge')
chkNum = 0;
for i = 1:size(mergeSetFiles,1)
    if ~isempty(mergeSetFiles{i,1}) && exist(mergeSetFiles{i,1},'file') > 0
        EEG = pop_loadset( mergeSetFiles{i,1});
        if ~isempty(mergeSetFiles{i,2})
            EEG.urevent = [];
            for ii = 1:size(EEG.event,2); EEG.event(ii).type = mergeSetFiles{i,2}; end
        end
        [ALLEEG, EEG, index] = eeg_store(ALLEEG, EEG);
        chkNum = chkNum + 1;
    end
end

try
    if chkNum > 1
        %Merge Datasets
        disp('*********Merging Datasets*********')
        EEG = pop_mergeset( ALLEEG, 1:size(ALLEEG,2), 0);
        EEG.setname = [newFileName];
        EEG = eeg_checkset( EEG );
        [ALLEEG, EEG, index] = eeg_store(ALLEEG, EEG);
    end
    
    if ~isempty(wkDir)
        %Save new dataset
        EEG = pop_saveset( EEG, 'filename',[EEG.setname '.set'],'filepath',wkDir);
        disp(['** New file created: ' wkDir '\' EEG.setname '.set **'])
    end
catch ME
    disp(ME)
end
end

