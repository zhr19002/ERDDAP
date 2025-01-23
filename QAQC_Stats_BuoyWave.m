% 
% Generate a statistics table of buoy wave QAQC results
% 

clc; clear;
buoy = 'WLIS'; % {'CLIS','EXRX','WLIS'}

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);

% Extract table from PostgreSQL
dT = sqlread(connQ, ['"' buoy '_Wave_QAQC"']);
dT = dT(dT.TmStamp < datetime(2025,1,1), :);
close(connQ);

% Statistics of QAQC results
stats_tbl = table((0:4)','VariableNames',{'FailedCount'});
for av = {'Hsig_m','Hmax_m','Tdom_s','Tavg_s','waveDir','meanDir'}
    tmp = tabulate(dT.([av{1} '_FailedCount']));
    for n = 0:4
        if ~ismember(n,tmp(:,1))
            tmp = [tmp; [n 0 0]];
        end
    end
    tmp = sortrows(tmp);
    av_count = arrayfun(@(i) sprintf('%d (%.2f%%)', tmp(i,2), tmp(i,3)), 1:5, 'UniformOutput', false);
    stats_tbl.(av{1}) = av_count';
end
disp(stats_tbl);