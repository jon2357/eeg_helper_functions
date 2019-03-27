function [ pat, sav_proc ] = ap_update_event_structure( pat, inSetup )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

% adds or update the "label" field of the event data structure
% If we want to select spesific trials {label,identity}
% inSetup = {...
%     'study_scene',{'strcmp(cond_str, ''study'') & scene_id > 0'};...
%     'study_only',{'strcmp(cond_str, ''study'')'};...
%     };

events = pat.dim.ev.mat;
        sav_proc = cell(2,size(inSetup,1));
        for iRm = 1:size(inSetup,1)
            rmLbl = inSetup{iRm,1}; rmID  = inSetup{iRm,2};
            if ~isempty(rmID)
                [index, levels] = make_event_index(events, rmID);
                sav_proc{1,iRm} = index;
                sav_proc{2,iRm} = levels;
                for ii = 1:length(events)
                    events(ii).(rmLbl) = index(ii);
                end
            else
                if mean(cellfun(@isnumeric,{events.(rmLbl)})) == 1
                    sav_proc{2,iRm} = unique([events.(rmLbl)]);
                else
                    sav_proc{2,iRm} = unique({events.(rmLbl)});
                end
            end
        end
        pat.dim.ev.mat = events;
        
end

