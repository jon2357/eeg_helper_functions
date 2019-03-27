function [ outData ] = fdtp_avg_over_time( timeMatrix, dataInput )

% timeMatrix = n x 2 array in seconds to average over
%   example: timeMatrix = [0.0  0.5; 0.5  1.0; 1.0  1.5];
% dataInput = fieldtrip data structure
%   example = dataInput = grpData{1}(1).c1_data;

data = cell(1,size(timeMatrix,1));
for iTime = 1:length(data)
    cfg= [];
    cfg.latency     = timeMatrix(iTime,:);
    cfg.avgovertime = 'yes';
    [data{iTime}] = ft_selectdata(cfg, dataInput);
end

outData = data{1};
for ii = 2:length(data)
    outData.powspctrm(:,:,ii) = data{ii}.powspctrm;
    outData.time(ii) = data{ii}.time;
    outData.cfg.latency(ii,:) = data{ii}.cfg.latency;
end

end

