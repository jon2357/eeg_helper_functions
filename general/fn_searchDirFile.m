function [ outCell] = fn_searchDirFile( mainABS, firstLvlFld, searchExt, secondLvlFld)
%Recursively searchs in file with 2 lvls of sub directories 
%outputs a n x 5 cell array with folder structure break down (last column
%is the full absolute path)
if 1 == 0       
    mainABS     = 'Z:\dataTest\data_sub';
    firstLvlFld = {'1','4','5','7','10','14'};
    secondLvlFld= {'sess1','sess2'};
    searchExt   = {'*_mean.ftwaveavg',;'*.fteeg'};
    
end


if nargin < 3; searchExt = []; end
if nargin < 4; secondLvlFld = '';end

if ~iscell(firstLvlFld); firstLvlFld  = {firstLvlFld}; end
if ~iscell(secondLvlFld);secondLvlFld = {secondLvlFld};end
if ~iscell(searchExt);   searchExt    = {searchExt};end

%% Search main ABS and find folders that match the first level folders
aa = dir(mainABS);
alldirs = {aa([aa.isdir]).name};
sD = cell(1,length(firstLvlFld));
for ii = 1:length(firstLvlFld)
    sD{ii} = find(ismember(alldirs, firstLvlFld{ii}) == 1);
end
firstLvlFound = alldirs(vertcat(sD{:}));

%% Search each first level for the second level directories and search extentions
outCell  = []; searchCount = 0;
for ii = 1:length(firstLvlFound)
    for i2 = 1:length(secondLvlFld)
        for i3 = 1:length(searchExt)
            searchCount = searchCount + 1;
            outCell{searchCount,1} = mainABS;
            outCell{searchCount,2} = firstLvlFound{ii};
            outCell{searchCount,3} = fullfile(secondLvlFld{i2});
            if ~isempty(searchExt{i3})
                findFile = dir(fullfile(outCell{ii,1},outCell{ii,2},outCell{ii,3},searchExt{i3}));
                outCell{searchCount,4} = findFile(1).name;
                outCell{searchCount,5} = fullfile(outCell{searchCount,1:4});
                if length(findFile) > 1
                    for i4 = 2:length(findFile)
                        searchCount = searchCount + 1;
                        outCell{searchCount,1} = mainABS;
                        outCell{searchCount,2} = firstLvlFound{ii};
                        outCell{searchCount,3} = fullfile(secondLvlFld{i2});  
                        outCell{searchCount,4} = findFile(i4).name;
                        outCell{searchCount,5} = fullfile(outCell{searchCount,1:4});
                    end
                end
            else
               outCell{searchCount,5} = fullfile(outCell{searchCount,1:3}); 
            end
        end
    end
end
end

