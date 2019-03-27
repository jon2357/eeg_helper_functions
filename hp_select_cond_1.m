function [ outDS ] = hp_select_cond_1( incfg, file_list, condition_list)
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


if ~isfield(incfg,'calc_diff');incfg.calc_diff = 0; end
if ~isfield(incfg,'order_diff');incfg.order_diff = []; end
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
        
        % Condition info
        for iCC = 1:length(condition_list)
            cH = ['c',num2str(iCC)];
            tmpDS.([cH,'_label'])= condition_list{iCC};
            tmpDS.([cH,'_data']) = inData.(loadVars{iCC});
            tmpDS.([cH,'_n'])   = length(tmpDS.([cH,'_data']).trialinfo);
        end
        
        
        
        % Create a difference data structure
        if incfg.calc_diff == 1
            if isempty(incfg.order_diff)
                indx = 1:length(condition_list);
                incfg.order_diff = reshape(indx,[2, length(indx)/2])';
            end
            
            for iD = 1:size(incfg.order_diff,1)
                indx1 = incfg.order_diff(iD,1);
                indx2 = incfg.order_diff(iD,2);
                
                cH1 = ['c',num2str(indx1)];
                cH2 = ['c',num2str(indx2)];
                dH  = ['d',num2str(iD)];
                
                tmpDS.([dH,'_label']) = ['[',tmpDS.([cH1,'_label']),...
                    ']vs[',tmpDS.([cH2,'_label']),']'];
                
                cfg = [];
                cfg.operation = 'subtract';
                cfg.parameter = incfg.parameter;
                tmpDS.([dH,'_data']) = ft_math(cfg, tmpDS.([cH1,'_data']),...
                    tmpDS.([cH2,'_data']));
                
                tmpDS.([dH,'_n']) = tmpDS.([cH1,'_n']) / tmpDS.([cH2,'_n']);
                
            end
        end
        
        sub_count = sub_count + 1;
        outDS(sub_count) = tmpDS;
    end
    
    
end
end


