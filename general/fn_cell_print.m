function fn_cell_print( cellOut, ABSpathFile, missingDataValue )
%Will output a 2 dimensional cell array where each cell contains a
%character string or numerical, can change NaN values to use for missing
%data (default = NaN string)

if nargin < 3; missingDataValue = nan; end

fid = fopen(ABSpathFile,'w');
for ii =1:size(cellOut,1)
    line2proc = cellOut(ii,:);
    printLine = cell(size(line2proc));
    for i = 1:size(line2proc,2);
        chkVal = line2proc{i};
        if isnan(chkVal); chkVal = missingDataValue; end
        if ~ischar(chkVal)
            printLine{i} = num2str(round(chkVal*1000)/1000);
        else
            printLine{i} = chkVal;
        end
    end
    fprintf(fid,'%s\t',printLine{:}); fprintf(fid,'\n');
end
fclose(fid);
end

