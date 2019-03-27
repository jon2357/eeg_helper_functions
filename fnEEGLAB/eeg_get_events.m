function [ events,numEvents ] = eeg_get_events( EEG )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%% Get event info to manipulate
eventstruct = EEG.event;
numEvents   = size(eventstruct,2);

% Create a singular structure with event list info
events = zeros(numEvents,4);
for i = 1:numEvents
    if strcmp(eventstruct(i).type, 'boundary');
        events(i,1) = -99;
        events(i,2) = eventstruct(i).latency;
        events(i,3) = NaN;
        if isfield('duration',eventstruct); 
            events(i,4) = eventstruct(i).duration; 
        else
            events(i,4) = 0;
        end
    else
        
    if ischar(eventstruct(1).type)
         events(i,1) = str2double(eventstruct(i).type);
    else
        events(i,1) = eventstruct(i).type;
    end 
    events(i,2) = eventstruct(i).latency;
    events(i,3) = eventstruct(i).urevent; 
        if isfield('duration',eventstruct); 
            events(i,4) = eventstruct(i).duration; 
        else
            events(i,4) = 0;
        end
    
    end
end
end

