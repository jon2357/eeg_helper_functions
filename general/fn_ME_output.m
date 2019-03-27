function fn_ME_output( ME )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

disp(ME)
for iR = 1:size(ME.stack,1)
    fprintf('%s | line: %i | full: %s\n',...
        ME.stack(iR,1).name, ME.stack(iR,1).line,ME.stack(iR,1).file);
end

