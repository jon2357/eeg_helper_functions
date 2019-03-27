function [ EEG, chk ] = eeg_place_events( EEG, eventlist )
%[ EEG, chk ] = place_EEG_events( EEG, eventlist )
%   Detailed explanation goes here

if size(eventlist,1) < size(eventlist,2); eventlist = eventlist';end

if size(EEG.event,2) ~= size(eventlist,1)
    disp('eventcode disagreement');
    chk = 0;
else
    for i = 1:size(EEG.event,2)
        EEG.event(i).type = eventlist(i);
        chk = i;
    end
    disp('Event Codes Replaced');
end

