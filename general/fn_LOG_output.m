function [ ] = fn_LOG_output(outType, dirABS, filelabel, identifier,extra)
% Create a log file for the completion of a script

% outType = 'single'; % fn_LOG_output('single','Z:\create\Log\here', mfilename, identifier)
% outType = 'list';   % fn_LOG_output('list',  'Z:\create\Log\here', mfilename, identifierList,timeMilliSeconds)
% outType = 'error';  % fn_LOG_output('error', 'Z:\create\Log\here', mfilename, identifier, ME)

% dirABS = absolute path of where you want to place the log file
% filelabel = how you want to identify the log file
% identifier = how to identify where you are in a loop / spesification of
% instance
% extra = for 'error' this should be ME, for 'list' this should be the time
% in seconds for a loop
%% 
if nargin < 5; extra = 0; end
% check if filelist is a string and convert to a cell array
if ischar(identifier); identifier = {identifier};end
% check if folder to place files in exists and if not create it
if ~exist(dirABS,'dir'); mkdir(dirABS);end

%modify suffix of file name
if strcmpi(outType,'single')
    filePrefix = 'Single_';
elseif strcmpi(outType,'list')
    filePrefix = 'List_';
elseif strcmpi(outType,'error')
    filePrefix = 'Error_';
    identifier = [identifier,' --- Error'];
end

LOG_fname     = ['LOG_',filePrefix,filelabel,'.txt'];
disp(['***LOG*** ',outType, ' --- Creating Log Entry: ', fullfile(dirABS,LOG_fname)]);
fid = fopen(fullfile(dirABS,LOG_fname), 'a+');

if strcmpi(outType,'single')
    for i= 1:length(identifier)
        if ~isempty(identifier{i})
            lineWrite = identifier{i};fprintf(fid,'%s\t%s',datestr(now),lineWrite);fprintf(fid,'\n');
        end
    end
elseif strcmpi(outType,'list')
    fprintf(fid,'----- %s --- %s mins --\n',datestr(now), num2str(extra/60));
    for i= 1:length(identifier)
        if ~isempty(identifier{i})
            lineWrite = identifier{i};fprintf(fid,'%s',lineWrite);fprintf(fid,'\n');
        end
    end
elseif strcmpi(outType,'error')
    fprintf(fid,['----------- ' datestr(now) ' -----------\n']);
    fprintf(fid,'%s\n%s\n%s\n', filelabel,identifier{1},extra.message);
    for iLog = 1:size(extra.stack,1)
        fprintf(fid,'%s | line: %i\n',extra.stack(iLog,1).name, extra.stack(iLog,1).line);
    end
    fprintf(fid,'\n');
end


fclose(fid);

end
