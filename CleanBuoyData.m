function res = CleanBuoyData(d, av, para)
% 
% Identify and remove outliers near the start/end date
% 

[YY, MM, DD] = datevec(d.time);
d.date = datetime(YY,MM,DD);
av_by = struct('T','degC','S','psu','DO','mg/L','P','dBars','C','S/m', ...
               'pH','none','rho','kg/m^3','DOsat','percent');
num_days = 4; % Number of days to be included near the start/end date

for idate = min(d.date):min(d.date)+num_days
    iu = find(d.date==idate);
    if max(d.(av_by.(av))(iu)) - min(d.(av_by.(av))(iu)) > para
        d = d(d.date ~= idate, :);
    end
end

for idate = max(d.date)-num_days:max(d.date)
    iu = find(d.date==idate);
    if max(d.(av_by.(av))(iu)) - min(d.(av_by.(av))(iu)) > para
        d = d(d.date ~= idate, :);
    end
end

res = d(:, ["TmStamp", "depth", av_by.(av)]);

end

% Get station climatology data
stats = GetDEEPWQClimStats(by_stn.(buoy),ZT,ZB,av{1});
% Buoy data cleaning
para = mean(stats.bd84 - stats.bd16);
buoyData = CleanBuoyData(buoyData,av{1},para);