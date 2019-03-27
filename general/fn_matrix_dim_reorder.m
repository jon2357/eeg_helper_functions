function [ outX ] = fn_matrix_dim_reorder( inX, in_order, out_order )
%Reorders data dimensions based on cell array of string values

if 1 == 0
    inX = randi(16,2,3,4);
    in_order  = {'chan','time','freq'};
    out_order = {'time','chan','freq'};
end

%% Run Data Checks
% if length(out_order) ~= length(size(inX)) || length(in_order) ~= length(size(inX))
%     error('Data dimensions must match: \n Data dims: %s \n Input Dims: %s \n Output Dims: %s',...
%             num2str(length(size(inX))), strjoin(in_order,'_'),strjoin(out_order,'_'));
% end

if ~ismember(in_order,out_order)
    error('Input and Output must have exact same values: \n Input Dims:  %s \n Output Dims: %s',...
            strjoin(in_order,'_'),strjoin(out_order,'_'));
end

%% Reorder data
outIndx = nan(1,length(out_order));
for i1 = 1:length(out_order)
    outIndx(i1) = find(ismember(in_order,out_order{i1}));
end
outX = permute(inX,outIndx);

end

