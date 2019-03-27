function [ outDS, gaData ] = hp_load_conditions( incfg, file_list, condition_list)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if 1 == 0
    clear all; %#ok
    project_path = 'C:\Users\strun\Dropbox\GT\proj\preSME\preSME_2018_02_13_v1';
    %     file_list = {...
    %         project_path,'test_data','presme_ya140enc','hp2','ya140enc_pow_cond(24).mat';
    %         project_path,'test_data','presme_ya165enc','hp2','ya165enc_pow_cond(24).mat';
    %         project_path,'test_data','presme_oa124enc','hp2','oa124enc_pow_cond(24).mat';
    %         project_path,'test_data','presme_oa146enc','hp2','oa146enc_pow_cond(24).mat';
    %         };
    file_list = {...
        project_path,'test_data','ya105ret_pow_cond(30).mat';
        project_path,'test_data','ya106ret_pow_cond(30).mat';
        project_path,'test_data','ya108ret_pow_cond(30).mat';
        project_path,'test_data','ya112ret_pow_cond(30).mat';
        };
    
    condition_list = {'vis_hit','vis_cr','people','aud_hit','aud_cr'};
    
    incfg = [];
    incfg.info.group =  'ya';
    incfg.info.subject = {'1','2','3','4'};
    incfg.info.val1 = [1,2,3,4];
    incfg.info.val2 = 10;
    incfg.info.val3 = [ 1 2];
end

if nargin < 3; condition_list = []; end

if ~isfield(incfg,'calc_diff');incfg.calc_diff = 1; end
if ~isfield(incfg,'calc_ga');incfg.calc_ga = 1; end
if ~isfield(incfg,'contrast_index');incfg.contrast_index = []; end
if ~isfield(incfg,'parameter');incfg.parameter = 'powspctrm'; end
if ~isfield(incfg,'cond_prefix');incfg.cond_prefix = 'fdtp_c_'; end
if ~isfield(incfg,'load_sub');incfg.load_sub = []; end
if ~isfield(incfg,'behav_field');incfg.behav_field = 'behav'; end
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
    if isempty(condition_list)
        loadVars = [];
    else
        loadVars = cell(1,length(condition_list));
        for ii = 1:length(loadVars)
            loadVars{ii} = [incfg.cond_prefix,condition_list{ii}];
        end
    end
    [ inData, ~ ] = hp_load( folder_input_path, file_input, loadVars );
    if ismember('zero',condition_list);
		inData.([incfg.cond_prefix,'zero']) = fdtp_create_fixed_sample_dataset( inData.(loadVars{1}));
	end
		
    if isempty(loadVars)
        loadVars = fieldnames(inData);
        condition_list = loadVars;
    end
    % If we found all the conditions we are looking for
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
    
    % Get condition info
    tmpStruct = [];
    if exist('condc','var'); clear condc; end
    for iCond = 1:length(condition_list)
        if isfield(inData,loadVars{iCond})
            tmpStruct.index = iCond;
            tmpStruct.label = condition_list{iCond};
            tmpStruct.data  = inData.(loadVars{iCond});
            tmpStruct.n     = NaN;
            if isfield(tmpStruct.data,'trialinfo')
                tmpStruct.n = length(tmpStruct.data.trialinfo);
            end
            condc(iCond) = tmpStruct; %#ok
        end
    end
    
    tmpDS.found_index = [condc.index];
    
    if incfg.calc_diff == 1 && length(condc) > 1
        if ~isempty(incfg.contrast_index)
            pContrast = incfg.contrast_index;
            if max(pContrast) > length(condc)
                error('Condition index larger than number of conditions');
            end
        elseif ~isempty(incfg.contrast_index)
            pContrast = [1 2];
        else
            arr = tmpDS.found_index;
            nCombs = (length(arr)*(length(arr)-1)) / 2;
            tmpV = cell(1,nCombs);
            iCount = 0;
            for i1 = 1:length(arr)
                for i2 = i1:length(arr)
                    if i1 ~= i2
                        iCount = iCount + 1;
                        tmpV{iCount} = [arr(i1) arr(i2)];
                    end
                end
            end
            pContrast = vertcat(tmpV{:});
        end
        
        tmpStruct = [];
        if exist('diffc','var'); clear diffc; end
        for iC = 1:size(pContrast,1)
            uIndx = pContrast(iC,:);
            uCond = condc(uIndx);
            
            tmpStruct.index = uIndx;
            tmpStruct.label = ['[',uCond(1).label,']vs[',uCond(2).label,']'];
            
            cfg = [];
            cfg.operation = 'subtract';
            cfg.parameter = incfg.parameter;
            tmpStruct.data = ft_math(cfg, uCond(1).data, uCond(2).data);
            
            tmpStruct.n = uCond(1).n / uCond(2).n;
            diffc(iC) = tmpStruct; %#ok
        end
        
        if size(pContrast,1) == 2
            
            tmpStruct.index = [5,6];
            tmpStruct.label = ['[',diffc(1).label,']vs[',diffc(2).label,']'];
            
            cfg = [];
            cfg.operation = 'subtract';
            cfg.parameter = incfg.parameter;
            tmpStruct.data = ft_math(cfg, diffc(1).data, diffc(2).data);
            
            tmpStruct.n = diffc(1).n / diffc(2).n;
            diffc(3) = tmpStruct;
        end
    else
        diffc = [];
    end
    
    tmpDS.condition = condc;
    tmpDS.contrast  = diffc;
    
    % If we are loading in the behavoiral info
    if ~isempty(incfg.load_sub)
        [ sData, ~ ] = hp_load( folder_input_path, file_input, incfg.load_sub );
        gC = fieldnames(sData);
        tmpS = sData.(gC{1});
        tmpDS.(incfg.behav_field) = tmpS.(incfg.behav_field);
    end
    
    sub_count = sub_count + 1;
    outDS(sub_count) = tmpDS; %#ok
    
    
end


if incfg.calc_ga == 1
    if exist('gaData','var'); clear gaData; end
    for iC = 1:length(condition_list)
        pCon = condition_list{iC};
        if exist('cStruct','var'); clear cStruct; end
        for iS = 1:length(outDS)
            indxCon = ismember({outDS(iS).condition.label},pCon);
            if sum(indxCon) > 1
                indxCon = find(indxCon == 1,1,'first');
            end
            cStruct(iS) = outDS(iS).condition(indxCon); %#ok
            
        end
        
        if exist('tmpS','var'); clear tmpS; end
        tmpS.index = unique([cStruct.index]);
        tmpS.label = unique({cStruct.label});
        tmpS.n     = [cStruct.n];
        cfg = [];
        cfg.parameter = incfg.parameter;
        tmpS.data = ft_freqgrandaverage(cfg,cStruct.data);
        gaData(iC) = tmpS; %#ok
    end
    
    if isfield(outDS,'contrast') && isstruct(outDS(1).contrast)
        
        tmp_lbl = cell(1,length(outDS));
        for ii = 1:length(outDS); tmp_lbl{ii} = {outDS(ii).contrast.label}; end
        all_con = unique(horzcat(tmp_lbl{:}));
        
        if exist('conData','var'); clear conData; end
        for iC = 1:length(all_con)
            pCon = all_con{iC};
            if exist('cStruct','var'); clear cStruct; end
            sCount = 0;
            for iS = 1:length(outDS)
                indxCon = find(ismember({outDS(iS).contrast.label},pCon) == 1); %disp(indxCon);
                if length(indxCon) == 1
                    sCount = sCount + 1;
                    cStruct(sCount) = outDS(iS).contrast(indxCon);
                elseif length(indxCon) > 1
                    if ~exist('cStruct','var') || ~ismember({cStruct(sCount).label},pCon)
                        sCount = sCount + 1;
                        cStruct(sCount) = outDS(iS).contrast(indxCon(1));
                    end
                else
                    
                end
            end
            tmpS.index = unique([cStruct.index]);
            tmpS.label = unique({cStruct.label});
            tmpS.n     = [cStruct.n];
            cfg = [];
            cfg.parameter = incfg.parameter;
            tmpS.data = ft_freqgrandaverage(cfg,cStruct.data);
            conData(iC) = tmpS; %#ok
        end
        
        gaN = length(gaData);
        for iAdd = 1:length(conData)
            gaIndx = gaN+iAdd;
            gaData(gaIndx) = conData(iAdd);
        end
    end
end
end


