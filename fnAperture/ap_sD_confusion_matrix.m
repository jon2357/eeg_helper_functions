function [ outS ] = ap_sD_confusion_matrix( sD )
allsize = [length(sD.params.info.dim.chan.mat),...
    length(sD.params.info.dim.time.mat),...
    length(sD.params.info.dim.freq.mat)];

dict_proc = cell(prod(allsize),4);
for i1 = 1:prod(allsize)
    [iC, iT, iF] = ind2sub(allsize,i1);
        dict_proc{i1, 1} = ['c',num2str(iC),'t',num2str(iT),'f',num2str(iF)];
        dict_proc{i1, 2} =sD.params.info.dim.chan.mat(iC).label;
        dict_proc{i1, 3} =sD.params.info.dim.time.mat(iT).label;
        dict_proc{i1, 4} =sD.params.info.dim.freq.mat(iF).label;
end

fnames = fieldnames(sD.ev);
if isempty(sD.selector{1})
    if ~iscell(sD.regressor{1})
        origReg = sD.regressor{2};
    else
        origReg = sD.regressor{1}{2};
    end
else
    if ~iscell(sD.selector{1})
        origReg = sD.selector{2};
    else
        origReg = sD.selector{1}{2};
    end
end

accIndx = cellfun(@endsWith,fnames,repmat({'_ap_acc'},size(fnames)));
accLabels = fnames(accIndx); 
pLabels = cell(1,length(accLabels));
for ii = 1:length(accLabels); pLabels{ii} = accLabels{ii}(1:end-7); end

outS = [];
for iP = 1:length(pLabels)
    pIndx = cellfun(@startsWith,fnames,repmat(pLabels(iP),size(fnames)));

    details = dict_proc(ismember(dict_proc(:,1),pLabels{iP}),:);
    desired = [sD.ev.([pLabels{iP},'_ap_desired'])];
    guess   = [sD.ev.([pLabels{iP},'_ap_guess'])];
    allreg  = unique(desired);
    
    desLine   = cell(1,length(allreg));
    so = nan(length(allreg),length(allreg),3);
    totalN = nan(length(allreg),1); 
    for iR = 1:length(allreg)
        guessReg = guess(desired == allreg(iR));
        
        tmpCount = nan(1,length(allreg));
        tmpProb = nan(1,length(allreg));
        tmpLbl = cell(1,length(allreg));
        totalN(iR,1) = length(guessReg); 
        for iN = 1:length(allreg)
            tmpCount(iN) = sum(ismember(guessReg,allreg(iN)));
            tmpProb(iN) = tmpCount(iN) / length(guessReg);
            tmpLbl{iN} = allreg(iN);
        end
        desLine{iR} = horzcat(allreg(iR),num2cell(tmpProb));
        nLine{iR} = horzcat(allreg(iR),num2cell(tmpCount));
    end
    probCell = vertcat(horzcat(pLabels{iP},num2cell(allreg)),desLine{:});
    nCell = vertcat(horzcat(pLabels{iP},num2cell(allreg)),nLine{:});
    
    outS(iP).lbl = pLabels{iP};
    outS(iP).dets =details;
    outS(iP).regValue = origReg;
    outS(iP).regLbl = allreg;
    outS(iP).dataLbl = {'desired','guess'};
    outS(iP).data = [desired;guess]';
    outS(iP).probCell = probCell;
    outS(iP).desiredLbl = probCell(2:end,1);
    outS(iP).guessLbl = probCell(1,2:end);
    outS(iP).prob = cell2mat(probCell(2:end,2:end));
    outS(iP).n = cell2mat(nCell(2:end,2:end));
    outS(iP).Ndesired = totalN;
end

end

