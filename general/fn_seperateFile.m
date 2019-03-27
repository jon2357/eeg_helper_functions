function [ outCell ] = fn_seperateFile( input_file )
%Tasks a string or cell array of locations and seperates them out based on
%folder folders 
% Returns a N x 2 cell array, column 1 = original file, column 2 = cell
% array, with each cell containing a folder or file
% For Example: 
%   input_file = 'Z:\dataTest\one\two\test.txt'
%   outCell{ii,1} = 'Z:\dataTest\one\two\test.txt';
%   outCell{ii,2} = {'Z:','dataTest','one','two','test.txt'};




if ~iscell(input_file)
        input_file = {input_file};
end
    
outCell = cell(length(input_file),2);

for ii = 1:length(input_file)
    uFile = input_file{ii};
    slashLoc = find(uFile == '/' | uFile == '\');
    partsCell = cell(1,length(slashLoc)+1);
    lastChar = length(uFile);
    for i2 = 1:length(partsCell)
        
        if i2 == 1
            startChar = 1;
            stopChar  = slashLoc(i2)-1;
        elseif i2 == length(partsCell);
            startChar = slashLoc(i2-1)+1;
            stopChar  = lastChar;
        else
            startChar = slashLoc(i2-1)+1;
            stopChar  = slashLoc(i2)-1;
        end
        partsCell{i2} = uFile(startChar:stopChar);
    end
outCell{ii,1} = uFile;
outCell{ii,2} = partsCell;
end

