function [ dir2out, file2out ] = fn_IncrementFileStructure(inType, inputVal )
% Function will increment either a file or directory
%inType = 'file'; inputVal = 'C:\dataTest\test.txt';
%inType = 'dir';  inputVal = 'C:\dataTest\test';

if strcmpi(inType,'file')
    slashLoc = find(inputVal == '/' | inputVal == '\');
    extLoc   = find(inputVal == '.');
    baseDir  = inputVal(1:slashLoc(end)-1);
    baseFile = inputVal(slashLoc(end)+1:extLoc(end)-1);
    baseExt  = inputVal(extLoc(end):end);
elseif strcmpi(inType,'dir')
    baseDir  = inputVal;
    baseFile = [];
    baseExt  = [];
end

%%
chkBase = fullfile(baseDir,[baseFile,baseExt]);

addCounter = 0;
keepChecking = 1;
while keepChecking
    if exist(chkBase,inType)
        addCounter = addCounter + 1;
        if addCounter < 10;       addval = horzcat('000',num2str(addCounter));
        elseif addCounter < 100;  addval = horzcat('00',num2str(addCounter));
        elseif addCounter < 1000; addval = horzcat('0',num2str(addCounter));
        else addval = num2str(addCounter);
        end
        if strcmpi(inType,'file')
            chkBase = fullfile(baseDir,[baseFile,'_',addval,baseExt]);
        elseif  strcmpi(inType,'dir')
            chkBase = [baseDir,'_',addval];
        end
    else
        keepChecking = 0;
    end
end

if strcmpi(inType,'file')
    slashLoc = find(chkBase == '/' | chkBase == '\');
    dir2out  = chkBase(1:slashLoc(end)-1);
    file2out = chkBase(slashLoc(end)+1:end);
elseif strcmpi(inType,'dir')
    dir2out  = chkBase;
    file2out = [];
end
end