function VarBad = CheckMatFileVarNames(T, vnames)
% 
% function to check the variable names in Kay' Tables
% called from FixKaysMatFile.m
% 

% set variable names required
VarBad = zeros(length(vnames), 1);
% get names in Tables
Cnames = T.Properties.VariableNames;

for nv = 1:length(vnames)                      % look for the required 
    chkname = strfind(Cnames, vnames(nv));     % variables in each year
    nameOK = cellfun(@(x) any(x), chkname);
    nameOK = double(nameOK);
    if sum(nameOK) == 0                        % VarBad=0 => missing
        disp([vnames{nv} ':  missing']);
    elseif sum(nameOK) == 1                    % VarBad=1 => found
        disp([vnames{nv} ':  OK']);
        VarBad(nv) = 1;
    else                                       % VarBad>1 => more than one
        disp(['Problem with ' vnames{nv}]);
        VarBad = sum(nameOK);
    end
end

end