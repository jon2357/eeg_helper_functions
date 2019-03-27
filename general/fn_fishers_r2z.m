function [ outS ] = fn_fishers_r2z( r,n, r0,n0 )
% Converts Correlection Coefficients to Z-score, and uses the Z-score to
% create confidince intervals. It will also take a second correlation and
% compute the Z-score difference to assess hif the 2 correlations
% coeefieients are significantly differnet.
% Example Loop:
% rData = [-0.601, 24; -0.306, 23];
%
% rData = [...
%     -0.601, 24, -0.306, 23;...
%     -0.442, 24, -0.335, 23;...
%     -0.567, 24, -0.295, 23;...
%     -0.255, 24, 0.58, 23;...
%     -0.007, 24, -0.654, 23;...
%     -0.021, 24, -0.589, 23;...
%     -0.586, 24, -0.394, 23;...
%     -0.599, 24, -0.328, 23;...
%      0.53,  24,  0.518, 23;...
%     -0.553, 24, -0.259, 23;...
%     -0.648, 24, -0.17, 23;...
%     ];
%
% cOut = {};
% for ii = 1:size(rData,1)
%     cOut{ii} = fn_fishers( rData(ii,1),rData(ii,2),rData(ii,3),rData(ii,4)  );
% end
% outS = vertcat(cOut{:}); outCC = vertcat(fieldnames(outS)',struct2cell(outS)');

if nargin < 3; r0 = []; end
if nargin < 4; n0 = []; end

z = .5*log( (1+r)/(1-r) );
sErr = 1/sqrt(n-3);
tmp = 1.96*sErr;

ci=[tanh(z-tmp),tanh(z+tmp)];

outS.r = round(r*1000)/1000;
outS.n = round(n*1000)/1000;
outS.z = round(z*1000)/1000;
outS.err = round(sErr*1000)/1000;
outS.ci = round(ci*1000)/1000;

if ~isempty(r0)
    z0 = .5*log( (1+r0)/(1-r0) );
    if isempty(n0); n0 = n; end
    sErr0 = 1/sqrt(n0-3);
    tmp0 = 1.96*sErr0;
    ci0=[tanh(z0-tmp0),tanh(z0+tmp0)];
    
    sCombined = sqrt((1/(n-3)) + (1/(n0-3)));
    zDiff = (z-z0)/sCombined;
    p = 2*(1-normcdf(abs(zDiff)));
    
    outS.r0  = round(r0*1000)/1000;
    outS.n0   = round(n0*1000)/1000;
    outS.z0   = round(z0*1000)/1000;
    outS.err0 = round(sErr0*1000)/1000;
    outS.ci0  = round(ci0*1000)/1000;
    outS.z_diff = round(zDiff*1000)/1000;
    outS.err_diff = round(sCombined*1000)/1000;
    outS.p = round(p*1000)/1000;
end


end

