Standardization Protocol
*.mat : fieldtrip data structure
 - within a mat file possible data structures:
fdtp_sub: contains subject information, and some log information
fdtp_eeg: contains the eeg data
fdtp_pow: contains the power spectrum data
fdtp_c_*: prefix for a condition data structure 


EEGLAB
 - The time dimension should always be spesified in milliseconds
 - All custom helper functions should start with 'eeg_'

Fieldtrip
 - the time dimension should always be spesified in seconds
 - All custom helper functions should start with 'fdtp_'

General
 - All custom helper functions should start with 'fn_'