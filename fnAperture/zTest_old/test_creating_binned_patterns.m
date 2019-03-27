%% initialize paths / toolboxes
ini_gasp
ini_Dattn
gp_initialize_external_toolbox( 'aperture' )


%% load classifier evidence for the correct context on each trial for each subject

% remember to load the correct pattern that includes the correct dimensions
% for time and frequency

%pat1.stat = struct('res', res, 'stat', stat, 'obj', obj);%try loading stat
%object first before using this.

pat1.stat = load('Z:\Shared Storage\Directed Attention Confidence\DAttn_proc\data_oa\24\encode\oa24enc_pow.mat');

pat1.stat = stat;

pat1.dim.time = time;

perf = create_perf_pattern(pat1, 'oa7_8timebins_and_7freqbins_minibl', 'stat_type', 'acts', 'class_output', 'correct'); 

%% calculate average classifier evidence for each attended context x likelihood of context condition
binned = bin_pattern(perf, 'eventbins', {'eventsource', 'eventtypecolor'}); 
events = get_dim(binned.dim, 'ev');
disp_events(events)



%% calculate average classifier evidence for each hits vs miss & color vs scene & attend vs unattend 
%averages performance across 0 to 2000ms and across all frequencies
binned = bin_pattern(perf, 'eventbins', {'eventnewEventCode', 'eventsource'}, 'timebins', [0 2000], 'freqbins', [1 99]); 
events = get_dim(binned.dim, 'ev');
disp(events)

%% examples of averaging across specificed time windows (e.g., 0 to 600ms; 600 to 2000ms)

binnedtime = bin_pattern(perf, 'eventbins', {'eventsource', 'eventtypecolor'}, 'timebins', [0 600]); 
events = get_dim(binned.dim, 'ev');
disp_events(events)


binnedtime2000 = bin_pattern(perf, 'eventbins', {'eventsource', 'eventtypecolor'}, 'timebins', [600 2000]); 