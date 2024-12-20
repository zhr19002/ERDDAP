% 
% Generate a statistics table of station climatology QAQC results
% 

clc; clear;
Astn = 'A4'; % {'A4','C1','E1','I2'}

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','stationQAQC','PortNumber',5432);

% Extract table from PostgreSQL
dT = sqlread(connQ, ['"DEEP_' Astn '_WQ_QAQC"']);

% Statistics of QAQC results
stats_tbl = table((1:4)','VariableNames',{'Flag'});
for av = {'T','S','DO','P','C','rho','pH','DOsat'}
    tmp = tabulate(dT.([av{1} '_Q']));
    for n = 1:4
        if ~ismember(n,tmp(:,1))
            tmp = [tmp; [n 0 0]];
        end
    end
    tmp = sortrows(tmp);
    av_count = arrayfun(@(i) sprintf('%d (%.2f%%)', tmp(i,2), tmp(i,3)), 1:4, 'UniformOutput', false);
    stats_tbl.(av{1}) = av_count';
end
disp(stats_tbl);