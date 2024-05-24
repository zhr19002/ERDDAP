function VarBad = CheckMatFileVarNames(T, vnames)
% 
% Function to check variable names
% 
% Called from MakeDataArchive.m
% 

% Set variable names required
VarBad = zeros(length(vnames), 1);
% Get names in tables
Cnames = T.Properties.VariableNames;

for nv = 1:length(vnames)   % Look for required variables
    chkname = strfind(Cnames, vnames(nv));
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