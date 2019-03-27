function [ outCell ] = fn_import_tabular_data( incfg, fileABS )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if 1 == 0
    fileABS = 'C:\dataTest\cont01.csv';
    incfg = [];
    incfg.mark_rows = {'goodResp','KeyPress4RT',' '};
    incfg.colsOfInt = {'source_sheet','ExperimentName','Subject','Block','CorrectAns1',...
        'KeyPress1RESP','KeyPress1RT','KeyPress2RESP','KeyPress2RT','KeyPress3RESP','KeyPress3RT',...
        'List1','List1.Sample','List2','List2.Sample','matchColor','matchScene','object','source',...
        'SourceTrigger','status','StudyBlock','StudyColor','StudyScene','TestColor','TestScene','typecolor','typescene','Block_number'};
end

if ~isfield(incfg,'colsOfInt');      incfg.colsOfInt = {}; end %cell array with header names of columns to return (default: all)
if ~isfield(incfg,'header_row');     incfg.header_row = 1; end %row which has header names on it (default: 1)
if ~isfield(incfg,'first_data_row'); incfg.first_data_row = 2; end %row which starts the data
if ~isfield(incfg,'mark_rows');      incfg.mark_rows = {}; end % N x 3 cell array {'newlabel','header name',value};

%% Verify that file exists
if ~exist(fileABS,'file'); error(['Not Found: ' fileABS]); end

%% Import file

%load in with excel function (seems to work with comma seperated values)
[~,~,raw] = xlsread(fileABS);

%get the column labels and place into their own cell array
col_names = raw(incfg.header_row,:);
%remove the first 2 rows (1st row = eprime file name, 2nd row = column headers) 
col_data = raw(incfg.first_data_row:end,:);

%% if no column headers are passed through return all the columns
if isempty(incfg.colsOfInt); incfg.colsOfInt = col_names; end

%% Parse the data and mark those rows that match the desired pattern
if ~isempty(incfg.mark_rows)
    addrows   = cell(size(col_data,1),size(incfg.mark_rows,1));
    addLabels = cell(1,size(incfg.mark_rows,1));
    
    for i1 = 1:size(incfg.mark_rows,1)
        chkCol = ismember(col_names,incfg.mark_rows{i1,2});
        addLabels{i1} = incfg.mark_rows{i1,1};
        
        for i2 = 1:size(col_data,1)
            if strcmpi(incfg.mark_rows{i1,3},col_data(i2,chkCol))
                addrows{i2,i1} = 1;
            else
                addrows{i2,i1} = 0;
            end
        end
    end
    
    col_names = horzcat(col_names,addLabels);
    col_data  = horzcat(col_data,addrows);
    incfg.colsOfInt = horzcat(incfg.colsOfInt,addLabels);
end
        
%% Select out the appropriate columns
cut_names = col_names(ismember(col_names,incfg.colsOfInt));
cut_data  = col_data(:,ismember(col_names,incfg.colsOfInt));

outCell = vertcat(cut_names,cut_data);
end

