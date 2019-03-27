function [ pat ] = ap_transform_data( incfg, pat )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
% inMat = pat.mat;



if ~isfield(incfg,'type'); incfg.type = ''; end
%'log', 'ztransform', events

if ~isfield(incfg,'baseline'); incfg.baseline = []; end
%For a ztransform, a baseline time is required, empty set will use the
%whole epoch
if ~isfield(incfg,'zapply'); incfg.zapply = 'all'; end % 'all', 'trials'
%For a ztransform, spesific if Zscores should be based on the average of
%all the data, or single trials

if ~isfield(incfg,'event_index'); incfg.event_index = []; end % 
%For selecting events, pass through the index numbers of which events you
%want to keep


if strcmpi(incfg.type,'events')
        newMat = pat.mat(incfg.event_index,:,:,:);
        newDim = pat.dim.ev;
        newDim.mat = newDim.mat(incfg.event_index);
        newDim.len = length(newDim.mat);
        
        pat.mat = newMat;
        pat.dim.ev = newDim;
        
elseif strcmpi(incfg.type,'log')
    % Log transform the data (does not baseline, just transforms the data)
    inMat = pat.mat;
    inMat(inMat==0) = eps(0); % if any values are exactly 0, make them eps
    inMat = log10(inMat);
    pat.mat = inMat;
    
elseif strcmpi(incfg.type,'ztransform')
    if ~isempty(incfg.baseline)
        [~, tIndx(1)] = min(abs([pat.dim.time.mat.avg] - min(incfg.baseline)));
        [~, tIndx(2)] = min(abs([pat.dim.time.mat.avg] - max(incfg.baseline)));
    else
        tIndx = [1 length(pat.dim.time.mat)];
    end
    % Z transform (normalize within session,channel, frequency)
    % base_mean and base_std are across events [epochs] for a prestimulus time
    % range and calculated seperately for each channel and frequnecy
    inMat = pat.mat;
    if strcmpi(incfg.zapply,'all')
        base_mean = nanmean(nanmean(inMat(:,:,tIndx,:),3),1);
        base_std  = nanstd(nanmean(inMat(:,:,tIndx,:),3),1);
        base_mean_rep = repmat(base_mean,[size(inMat,1),1,size(inMat,3),1]);
        base_std_rep  = repmat(base_std,[size(inMat,1),1,size(inMat,3),1]);
        zMat = (inMat - base_mean_rep) ./ base_std_rep;
    else
        zMat = nan(size(inMat));
        for iii = 1:size(inMat,1)
            tMean = nanmean(inMat(iii,:,tIndx,:),3);
            tStd  = nanmean(inMat(iii,:,tIndx,:),3);
            zMat(iii,:,:,:) = (inMat(iii,:,:,:) - tMean) ./ tStd;
        end
    end
    pat.mat = zMat;
    
    
end



