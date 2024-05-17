function d_clean = CleanBuoyData(d, info, para)
% 
% Identify and remove outliers near the start/end date
% 
% Called from VisualizeQAQCResults.m
% 

[YY, MM, DD] = datevec(d.TmStamp);
d.date = datetime(YY,MM,DD);
info_para = struct('T','degC', 'S','psu', 'DO','mg/L', 'pH','pH');
num_days = 4; % Number of days to be included near the start/end date

for idate = min(d.date):min(d.date)+num_days
    iu = find(d.date==idate);
    if max(d.(info_para.(info))(iu)) - min(d.(info_para.(info))(iu)) > para
        d = d(d.date ~= idate, :);
    end
end

for idate = max(d.date)-num_days:max(d.date)
    iu = find(d.date==idate);
    if max(d.(info_para.(info))(iu)) - min(d.(info_para.(info))(iu)) > para
        d = d(d.date ~= idate, :);
    end
end

d_clean = d(:, ["TmStamp", "depth", info_para.(info)]);

end