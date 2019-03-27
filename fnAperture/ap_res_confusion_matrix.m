function [ outS ] = ap_res_confusion_matrix( res )

outS = [];
for iIter = 1:numel(res.iterations)
    
[d1, d2, d3, d4] = ind2sub(size(res.iterations),iIter);
iterLbl = ['c',num2str(d2),'t',num2str(d3),'f',num2str(d4)];
tmpI = res.iterations(iIter);

inD = [tmpI.perfmet{1, 1}.desireds',tmpI.perfmet{1, 1}.guesses'];
regs = unique(inD);

vallbl = {'desired','guess','desN','guessN','prob'};
valmat = nan((length(regs)*length(regs)),5);
for ii = 1:size(valmat,1)
    [i1, i2] = ind2sub([length(regs),length(regs)],ii);
    valmat(ii,1) = regs(i2);
    valmat(ii,2) = regs(i1);
    
    desIndx = ismember(inD(:,1),regs(valmat(ii,1)));
    regD = inD(desIndx,:);
    guessIndx = ismember(regD(:,2),regs(valmat(ii,2)));
    guessD = regD(guessIndx,:);
    
    valmat(ii,3) = size(regD,1);
    valmat(ii,4) = size(guessD,1);
    valmat(ii,5) =valmat(ii,4) / valmat(ii,3);
end



    outS(iIter).lbl = iterLbl;
    outS(iIter).vallbl = vallbl;
    outS(iIter).valmat = valmat;

    outS(iIter).dets ={};
    outS(iIter).regValue = {};
    outS(iIter).regLbl = regs;
    outS(iIter).dataLbl = {'desired','guess'};
    outS(iIter).data = inD;
    
    tmpR = reshape(valmat,[length(regs),length(regs),5]);
    desCell = vertcat(num2cell(tmpR(1,:,1)),num2cell(tmpR(:,:,5)))';
    probCell = vertcat(horzcat(iterLbl, num2cell(tmpR(:,1,2))'),desCell);

    outS(iIter).probCell = probCell;
    outS(iIter).desiredLbl = num2cell(tmpR(1,:,1))';
    outS(iIter).guessLbl = num2cell(tmpR(:,1,2))';
    outS(iIter).prob = tmpR(:,:,5)';
    outS(iIter).n = tmpR(:,:,4)';
    outS(iIter).Ndesired = tmpR(1,:,3)';

end

