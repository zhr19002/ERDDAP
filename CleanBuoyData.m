function d_clean = CleanBuoyData(d, avar, para)
% 
% Identify and remove outliers near the start/end date
% 
% Called from VisualizeQAQCResults.m
% 

[YY, MM, DD] = datevec(d.TmStamp);
d.date = datetime(YY,MM,DD);
avar_buoy = struct('T','degC','S','psu','DO','mg/L','P','dBars','C','S/m', ...
                   'pH','pH','rho','kg/m^3','DOsat','sat_mg/L');
num_days = 4; % Number of days to be included near the start/end date

for idate = min(d.date):min(d.date)+num_days
    iu = find(d.date==idate);
    if max(d.(avar_buoy.(avar))(iu)) - min(d.(avar_buoy.(avar))(iu)) > para
        d = d(d.date ~= idate, :);
    end
end

for idate = max(d.date)-num_days:max(d.date)
    iu = find(d.date==idate);
    if max(d.(avar_buoy.(avar))(iu)) - min(d.(avar_buoy.(avar))(iu)) > para
        d = d(d.date ~= idate, :);
    end
end

d_clean = d(:, ["TmStamp", "depth", avar_buoy.(avar)]);

end