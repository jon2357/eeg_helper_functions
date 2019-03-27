function [ cellData ] = fn_convertCell2num( cellheaders, cellData,cols2cycle  )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

%cols2cycle = {'ratingResp.keys', 'ratingResp.rt'};

cellheaders = cellheaders(~cellfun(@isempty, cellheaders));
for jj = 1:length(cols2cycle)
    if ~isempty(cols2cycle(jj))
        if sum(ismember(cellheaders,cols2cycle{jj})) ==1
            for ii = 1:size(cellData,1)
                
                str2check = cellData{ii,ismember(cellheaders,cols2cycle{jj})};
                if ~isempty(str2check) && ischar(str2check)
                    if strcmp(str2check,'None')
                        numOnly = 0;
                    else
                        numOnly = regexp(str2check,'-?\d+\.?\d*|-?\d*\.?\d+','match');
                    end
                    if length(numOnly) == 1
                        cellData{ii,ismember(cellheaders,cols2cycle{jj})} = str2double(numOnly);
                    else
                        cellData{ii,ismember(cellheaders,cols2cycle{jj})} = NaN;
                    end
                else
                    cellData{ii,ismember(cellheaders,cols2cycle{jj})} = 0;
                end
            end
        end
    else
        disp('labels are incorrect')
    end
end
end

