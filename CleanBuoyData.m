function res = CleanBuoyData(d, avars)
% 
% Identify and mark outliers NaN near the start/end date of each year
% 
% Called from WriteBuoyDataQAQC.m
% 

res = d;
uYears = unique(year(d.TmStamp));
for i = 1:numel(uYears)
    idx = (year(d.TmStamp)==uYears(i)); % Filter a specific year
    iu = (idx & (d.TmStamp<min(d.TmStamp(idx))+5 | ...
                 d.TmStamp>max(d.TmStamp(idx))-5) & ... % Filter dates
         (d.S < 5 | d.P < 0.2));        % Filter unusual S or P values
    for av = avars
        res.(av{1})(iu) = NaN;
    end
end

end