
        abs_sub_file = 'C:\Dropbox\GT\dissertation\cuep_matlab_data\101\proc_fam_ap_1\ya101fam_ap_bs(none).mat';
          % Load subject pat file
        disp(['Loading: ',abs_sub_file]);
        inPat = load(abs_sub_file);
        pat = inPat.pat;  %creates workspace variable 'pat'
        
               %% run MVPA stuff
        disp(['initializing for MVPA: ',abs_sub_file]);
        % initialize the 'params' data structure
        params = struct();
        
        % this is a field specified in the events for my pattern,
        % indicating stimulus category
        params.regressor={'scene_id'};
        
        % uses each unique combination of the session and trial fields in events,
        % so the cross-validation is at the level of lists
        params.selector={'block_num', 'trial_num'};
        %Other parameters?
        params.f_train=@train_logreg;
        params.train_args=struct('penalty',10);
        %params.train_sampling = 'over';
        params.n_reps = (1);    
        params.res_dir = pwd;
        
        %params.iter_cell = {[],[],'iter','iter'};

        [pat, bins] = patBins(pat, 'timebins', [0 .5;.5 1;1 1.5;1.5 2],...
                                   'timebinlabels', {'one','two','three','four'},... 
                                   'freqbins',  [4 7; 8 12; 16 26],...
                                   'freqbinlabels', {'theta','alpha','beta'},...
                                   'chanbins', [12;13;14;15;16;17;18;19;32]);       
        params.iter_cell= bins;
        
        disp(['Running "classify_pat": ',abs_sub_file]);
        pat = classify_pat(pat,'fam_test', params);
        %creates 3 variables
           % res: res.iterationcs: 4D matrix, (epochs,chans,time,freq)
           % stat
           % obj
        
        

