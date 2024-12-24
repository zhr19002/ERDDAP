% 
% Generate a statistics table of buoy meteorology QAQC results
% 

clc; clear;
buoy = 'ARTG'; % {'ARTG','CLIS1','CLIS2','EXRX','WLIS'}

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);

% Extract table from PostgreSQL
dT = sqlread(connQ, ['"' buoy '_Met_QAQC"']);
close(connQ);

% Statistics of QAQC results
stats_tbl = table((0:4)','VariableNames',{'FailedCount'});
for av = {'windSpd_Kts','windSpd_Max','fiveSecAvg_Max','windDir_M', ...
          'airTemp_Avg','relHumid_Avg','baroPress_Avg','dewPT_Avg'}
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