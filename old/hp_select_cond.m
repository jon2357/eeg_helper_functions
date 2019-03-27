function [ outDS ] = hp_select_cond( incfg, file_list, condition_list)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if 1 == 0
    file_list = {...
        project_path,'test_data','presme_ya140enc','hp2','ya140enc_pow_cond(24).mat';
        project_path,'test_data','presme_ya165enc','hp2','ya165enc_pow_cond(24).mat';
        project_path,'test_data','presme_oa124enc','hp2','oa124enc_pow_cond(24).mat';
        project_path,'test_data','presme_oa146enc','hp2','oa146enc_pow_cond(24).mat';
        };
    
    condition_list = {'vis_hit','vis_miss'};
    
    incfg = [];
    incfg.info.group =  'ya';
    incfg.info.subject = {'1','2','3','4'};
    incfg.info.val1 = [1,2,3,4];
    incfg.info.val2 = 10;
    incfg.info.val3 = [ 1 2];
end


if ~isfield(incfg,'calc_diff');incfg.calc_diff = 1; end
if ~isfield(incfg,'parameter');incfg.parameter = 'powspctrm'; end
if ~isfield(incfg,'cond_prefix');incfg.cond_prefix = 'fdtp_c_'; end
% This would be a good place to add group, subject, session information
if ~isfield(incfg,'info');incfg.info = []; end


if ~isempty(incfg.info)
    tF = fieldnames(incfg.info);
    for iF = 1:length(tF)
        tmpVal = incfg.info.(tF{iF});
        %If this is a string, turn it into a cell array
        if ischar(tmpVal); tmpVal = {tmpVal}; end
        
        if length(tmpVal) == 1
            newInfo.(tF{iF}) = repmat(tmpVal,[1 size(file_list,1)]);
        elseif length(tmpVal) == size(file_list,1)
            newInfo.(tF{iF}) = incfg.info.(tF{iF});
        end
    end
    incfg.info = newInfo;
end

sub_count = 0;

for iRun = 1:size(file_list,1)
    
    folder_input_path = fullfile(file_list{iRun,1:end-1});
    file_input        = file_list{iRun,end};
    LOGid             = fullfile(folder_input_path, file_input);
    
    disp(['HP: Processing File [',num2str(iRun),'/',...
        num2str(size(file_list,1)),']: ',LOGid]);
    
    % Load contrast of interest
    loadVars = cell(1,length(condition_list));
    for ii = 1:length(loadVars)
        loadVars{ii} = [incfg.cond_prefix,condition_list{ii}];
    end
    [ inData, ~ ] = hp_load( folder_input_path, file_input, loadVars );
    
    
    % If we found all the conditions we are looking for
    if length(fieldnames(inData)) == length(loadVars)
        
        tmpDS = [];
        if ~isempty(incfg.info)
            tF = fieldnames(incfg.info);
            for iF = 1:length(tF)
                tmpVal = incfg.info.(tF{iF})(iRun);
                if iscell(tmpVal) && length(tmpVal) == 1
                    tmpDS.(tF{iF})  = incfg.info.(tF{iF}){iRun};
                else
                    tmpDS.(tF{iF})  = incfg.info.(tF{iF})(iRun);
                end
            end
        end
        
        if (~isfield(tmpDS,'subject') || isempty(tmpDS.subject)) && ...
                isfield(inData.(loadVars{1}).trialinfo,'subject')
            tmpDS.subject = strjoin(unique({inData.(loadVars{1}).trialinfo.subject}),'_');
        end
        if (~isfield(tmpDS,'group')  || isempty(tmpDS.group)) && ...
                isfield(inData.(loadVars{1}).trialinfo,'group')
            tmpDS.group = strjoin(unique({inData.(loadVars{1}).trialinfo.group}),'_');
        end
        if (~isfield(tmpDS,'sess')  || isempty(tmpDS.sess)) && ...
                isfield(inData.(loadVars{1}).trialinfo,'sess')
            tmpDS.sess = strjoin(unique({inData.(loadVars{1}).trialinfo.sess}),'_');
        end
        
        % Condition one info
        c1_label = condition_list{1};
        c1_data  = inData.(loadVars{1});
        c1_n     = length(c1_data.trialinfo);
        
        %condition two info
        c2_label = condition_list{2};
        c2_data  = inData.(loadVars{2});
        c2_n     = length(c2_data.trialinfo);
        
        % Build data structure
        
        tmpDS.c1_label= c1_label;
        tmpDS.c1_data = c1_data;
        tmpDS.c1_n    = c1_n;
        tmpDS.c2_label= c2_label;
        tmpDS.c2_data = c2_data;
        tmpDS.c2_n    = c2_n;
        
        % Create a difference data structure
        if incfg.calc_diff == 1
            cfg = [];
            cfg.operation = 'subtract';
            cfg.parameter = incfg.parameter;
            diff_data = ft_math(cfg, c1_data, c2_data);
            diff_label = ['[',c1_label,']vs[',c2_label,']'];
            diff_n = c1_n / c2_n;
            
            tmpDS.diff_label= diff_label;
            tmpDS.diff_data = diff_data;
            tmpDS.diff_n    = diff_n;
        end
        
        sub_count = sub_count + 1;
        outDS(sub_count) = tmpDS;
    end
    
    
end
end


