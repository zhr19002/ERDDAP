% 
% Generate a statistics table of station nutrient QAQC results
% 

clc; clear;
Astn = 'A4'; % {'A4','C1','E1','I2'}

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','stationQAQC','PortNumber',5432);

% Extract table from PostgreSQL
dT = sqlread(connQ, ['"DEEP_' Astn '_Nutrient_QAQC"']);
close(connQ);

% Statistics of QAQC results
stats_tbl = table((0:4)','VariableNames',{'Flag'});
for av = {'BIOSI-LC','DIP','DOC','NH#-LC','NOX-LC','PC', ...
          'PN','PP-LC','SIO2-LC','TDN-LC','TDP','TSS'}
    iu = strcmp(dT.Parameter, av{1});
    tmp = tabulate(dT.Result_Q(iu));
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