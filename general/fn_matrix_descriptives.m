function [ desc ] = fn_matrix_descriptives( inX,incfg )
%fucntion expects each column to be a variable and each row to be an
%observation, this can be switched with the incfg variable

%% Test / debug
if 1 == 0
    % inX = [NaN 1 2 3 4 5 6 7 8 9 0; 4 5 6 7 8 9 0 7 1 2 3; 14,-4,-7,-8,18,-22,18,5,10,5,-6];
    inX = rand(40,5)*10;
    incfg = [];
end
if length(size(inX)) > 2; error('Input Matrix can only have 2 dimensions'); end
%% setup configuration
if nargin < 2; incfg = []; end
if ~isfield(incfg,'variables');   incfg.variables    = 'columns'; end %or columns
if ~isfield(incfg,'varLabels');   incfg.varLabels    = []; end %or columns
if ~isfield(incfg,'dataLabels');  incfg.dataLabels   = []; end %or columns

if (size(inX,1) == 1 && size(inX,2) > size(inX,1)) || strcmpi(incfg.variables ,'rows')
    inX = inX';
end

if isempty(incfg.varLabels)
    incfg.varLabels = cell(1,size(inX,2));
    for ii = 1:size(inX,2)
        incfg.varLabels{ii} = ['x',num2str(ii)];
    end
end

if isempty(incfg.dataLabels)
    incfg.dataLabels = cell(1,size(inX,1));
    for ii = 1:size(inX,1)
        incfg.dataLabels{ii} = ['obs',num2str(ii)];
    end
end
%% Run Descriptives

% Get counts of the data
val_nData = size(inX,1);
val_nVar  = size(inX,2);

% how many are nan
val_nNan = sum(isnan(inX));
val_nDataPts = val_nData - val_nNan; % how many non NaN data points are in each Varible

% Find the maximum value in each column
val_max = max(inX);
% Find the maximum value in each column
val_min = min(inX);
% Calculate the mean of each column
val_mu = nanmean(inX); %removes the NaN values and treats then as if they don't exist
% Calculate the standard deviation of each column
val_sigma = nanstd(inX);
%Calculate the mode of each column (if there are no repeats make value NaN)
val_mode = NaN(1,val_nVar);
for ii = 1:val_nVar
    val_mode(ii)  = mode(inX(:,ii));
    if length(find(inX(:,ii) == val_mode(ii))) == 1
        val_mode(ii)  = NaN;
    end
end
% Calculate the range
val_range = range(inX);
% Calculate the median
val_median = median(inX);
%Calculate the interquartile range
val_iqr    = iqr(inX);

%Outlier detection with quartiles
outlier_min_iqr = quantile(inX,.25)-1.5*val_iqr;
outlier_max_iqr = quantile(inX,.75)+1.5*val_iqr;

val_iqr_outliers = cell(1,val_nVar);
lbl_iqr_outliers = cell(1,val_nVar);
val_iqr_nOutliers = NaN(1,val_nVar);
for ii = 1:val_nVar
    max_indx = find(inX(:,ii) >= outlier_max_iqr(ii));
    min_indx = find(inX(:,ii) <= outlier_min_iqr(ii));
    
    outlier_max_iqr_lbl = incfg.dataLabels(max_indx);
    outlier_min_iqr_lbl = incfg.dataLabels(min_indx);
     
    outlier_max_iqr_val = inX(max_indx,ii);
    outlier_min_iqr_val = inX(min_indx,ii);    

    val_iqr_outliers{ii} = vertcat(outlier_max_iqr_val,outlier_min_iqr_val);
    lbl_iqr_outliers{ii} = horzcat(outlier_max_iqr_lbl,outlier_min_iqr_lbl);
    val_iqr_nOutliers(ii) = size(val_iqr_outliers{ii},1);
end

%Calculate Varience
val_var    = nanvar(inX);
%Calcualte Standard error of the mean
val_sem    = val_sigma./sqrt(val_nDataPts);
% Calculate trim mean (using 10% trim)
val_mu_trim = trimmean(inX,10);
% Calculate harmonic mean 
val_mu_harmonic = harmmean(inX);

% Calculate kurtosis (corrected for bias) 
% The kurtosis of the normal distribution is 3. Distributions that are more 
% outlier-prone than the normal distribution have kurtosis greater than 3; 
% distributions that are less outlier-prone have kurtosis less than 3.
val_kurtosis = kurtosis(inX,0); 

%Calculate skewness
% Skewness is a measure of the asymmetry of the data around the sample mean. 
% If skewness is negative, the data are spread out more to the left of the mean 
% than to the right. If skewness is positive, the data are spread out more to the right.
% The skewness of the normal distribution (or any perfectly symmetric distribution) is zero
val_skewness = skewness(inX,0);

%% Checks on data

%% output info
desc = [];
desc.varDim     = incfg.variables;
desc.varLabels  = incfg.varLabels;
desc.dataLabels = incfg.dataLabels;

desc.nVar      = val_nVar;
desc.nDataPts  = val_nData;
desc.nDataPts_nonNAN = val_nDataPts;
desc.max      = val_max;
desc.min      = val_min;
desc.median   = val_median;
desc.mode     = val_mode;
desc.range    = val_range;
desc.mu       = val_mu;
desc.mu_trim10   = val_mu_trim;
desc.mu_harmonic = val_mu_harmonic;
desc.var        = val_var;
desc.sigma      = val_sigma;
desc.sem        = val_sem;

desc.iqr        = val_iqr;
desc.iqr_outliers_n   = val_iqr_nOutliers;
desc.iqr_outliers_pts = val_iqr_outliers;
desc.iqr_outliers_lbl = lbl_iqr_outliers;
desc.kurtosis = val_kurtosis;
desc.skewness = val_skewness;

%% Advanced details
desc.conf95z_2tailed = 1.96*desc.sem;
desc.tinv95_2tailed  = tinv(.975,desc.nDataPts_nonNAN-1);
desc.conf95t_2tailed = tinv(.975,desc.nDataPts_nonNAN-1).*desc.sem;

% Correlations
desc.corr.type       = 'Pearson'; %'Kendall','Spearman'
desc.corr.missingval = 'all';
desc.corr.sigval     = .05;
[desc.corr.rho,desc.corr.pval] = corr(inX,'type',desc.corr.type,'rows',desc.corr.missingval);
desc.corr.sigmask = desc.corr.pval < desc.corr.sigval;

desc.corr.cell_rho = horzcat(horzcat('rho',desc.varLabels)',vertcat(desc.varLabels,num2cell(desc.corr.rho)));
desc.corr.cell_p = horzcat(horzcat('rho',desc.varLabels)',vertcat(desc.varLabels,num2cell(desc.corr.pval)));
desc.corr.cell_rhoSig = horzcat(horzcat('rho',desc.varLabels)',vertcat(desc.varLabels,num2cell(desc.corr.rho.*desc.corr.sigmask)));
%% Stat notes about confidence levels (assumeing a normal distribution)
% 95% confidence interval is mu +/- 1.96*desc.sem %for a completely normal
% distribution when you know the variance

% 95% confidence interval is mu +/- ts*desc.sem %When you need to
% estimate the variance from the sample ts = tinv([0.025  0.975],df); df =
% number of observations - 1 [degrees of freedom]
end

