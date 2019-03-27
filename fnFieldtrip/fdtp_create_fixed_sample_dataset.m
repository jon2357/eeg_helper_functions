function [ fixDS ] = fdtp_create_fixed_sample_dataset( inDS, data_field, fixed_sample )
%Copies the fieldtrip datastructure and replaces the data field with a
%single value (default = 0), useful for testing activation vs baseline
%after baseline correction.

if nargin < 2; data_field = []; end
if isempty(data_field); data_field = 'powspctrm' ; end

if nargin < 3; fixed_sample = []; end
if isempty(fixed_sample); fixed_sample = 0 ; end

fixDS = inDS;

data_size = size(fixDS.(data_field));
fixDS.(data_field) = ones(data_size)*fixed_sample;
end

