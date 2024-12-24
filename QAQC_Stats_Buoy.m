% 
% Generate a statistics table of buoy climatology QAQC results
% 

clc; clear;

buoy = 'ARTG'; locs = {'btm1','btm2','sfc'};
% buoy = 'CLIS'; locs = {'btm','sfc'};
% buoy = 'EXRX'; locs = {'btm2','mid','sfc'};
% buoy = 'WLIS'; locs = {'btm1','btm2','mid','sfc'};

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);

% Extract table from PostgreSQL
dT = sqlread(connQ, ['"' buoy '_' locs{1} '_QAQC"']);
close(connQ);

% Statistics of QAQC results
stats_tbl = table((0:5)','VariableNames',{'FailedCount'});
for av = {'T','S','DO','P','C','rho','pH','DOsat'}
    tmp = tabulate(dT.([av{1} '_FailedCount']));
    for n = 0:5
        if ~ismember(n,tmp(:,1))
            tmp = [tmp; [n 0 0]];
        end
    end
    tmp = sortrows(tmp);
    av_count = arrayfun(@(i) sprintf('%d (%.2f%%)', tmp(i,2), tmp(i,3)), 1:6, 'UniformOutput', false);
    stats_tbl.(av{1}) = av_count';
end
disp(stats_tbl);