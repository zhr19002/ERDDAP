% 
% Generate a statistics table of buoy nutrients QAQC results
% 

clc; clear;

buoy = 'CLIS';
% tvars = {'PAR','FL','NTU'};
% avars = {'Adjusted_PAR','Adjusted_CHLA','Adjusted_TSS'};
tvars = {'NO3'};
avars = {'Adjusted_NO3'};

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);

% Statistics of QAQC results
stats_tbl = table((0:4)','VariableNames',{'FailedCount'});
for i = 1:length(tvars)
    dT = sqlread(connQ, ['"' buoy '_' tvars{i} '_QAQC"']);
    tmp = tabulate(dT.([avars{i} '_FailedCount']));
    for n = 0:4
        if ~ismember(n,tmp(:,1))
            tmp = [tmp; [n 0 0]];
        end
    end
    tmp = sortrows(tmp);
    av_count = arrayfun(@(i) sprintf('%d (%.2f%%)', tmp(i,2), tmp(i,3)), 1:5, 'UniformOutput', false);
    stats_tbl.(avars{i}) = av_count';
end

close(connQ);
disp(stats_tbl);