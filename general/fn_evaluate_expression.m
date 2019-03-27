function [ outPut,outStruct ] = fn_evaluate_expression( inEQ,inData )
%Allows for complex processing of expressions. inData should be a 1 x N
%cell array each column number should corrospond to an 'x' value in the
%inEQ variable. column 1 of 'inData' should be marked as 'x1' in the 'inEQ'
%string. All equations should follow and be written with respect to oder of
%operations. output a data structure with value and detials of process

%   inData   | inEQ
%  ----------------
%   column 1 = x1
%   column 2 = x2
%   column N = xN

if 1 == 0
    inData = {50,100};
    inEQ = '(x1/x2)*x1';
    %inEQ = 'x1+x2';
end
%% Create list of variable index holders 
eqID = cell(1,length(inData));
for ii = 1:length(inData); eqID{ii} = ['x',num2str(ii)]; end

%% break up equation in cell array inorder to replace varibles
s = strtrim(inEQ);
aDelim = strjoin(eqID, '|');
[nonCell, matchCell] = regexp(s, aDelim,'split','match');
[nonIndx, matchIndx] = regexp(s, aDelim);

if min(nonIndx) < min(matchIndx)
    startCell = nonCell; secondCell = matchCell;
else
    startCell = matchCell; secondCell = nonCell;
end

brCell = cell(1,length(startCell) + length(secondCell));
c_start = 0;
c_second = 0;

for ii = 1:length(brCell)
    if rem(ii,2) ~= 0 
        c_start = c_start + 1;
        brCell{ii} = startCell{c_start};
    else
        c_second = c_second + 1;
        brCell{ii} = secondCell{c_second};
    end
end
%% Process equation
outPut = [];
modEQ = brCell;
    
for iiEQ = 1:length(modEQ)
    if ismember(modEQ{iiEQ},eqID)
       numLoc = regexp(modEQ{iiEQ},'\d');
       numVal = str2double(modEQ{iiEQ}(numLoc));
       modEQ{iiEQ} = num2str(inData{numVal});
    end
end
    manExpr = strjoin(modEQ);
    eval(['outPut = ',manExpr]);   
    
%% collect details
outStruct.val      = outPut;
outStruct.expr_mod = manExpr;
outStruct.expr_in  = inEQ;
outStruct.data     = inData;
end

