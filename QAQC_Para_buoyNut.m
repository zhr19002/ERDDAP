% 
% Create QAQC tables for buoy nutrients
% Generate the "QAQC_Para_buoyNut.mat" file
% 

clc; clear;

% Fixed parameters
para1 = {'PAR_Raw','PAR_Density_Flux'};
para2 = {'PAR_Flux_Total'};
para3 = {'chl_ugL'};
para4 = {'turbidity_NTU'};
para5 = {'NO3conc','NNO3'};
paras = {para1, para2, para3, para4, para5};

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','provLNDB','PortNumber',5432);

% Extract tables from PostgreSQL
dT1 = sqlread(conn, '"ARTG_pb1_PARdenDat"');
dT1 = dT1(dT1.TmStamp <= datetime(2024,5,10), :);

dT2 = sqlread(conn, '"ARTG_pb1_PARtotDat"');
dT2 = dT2(dT2.TmStamp <= datetime(2024,5,8), :);

dT3 = sqlread(conn, '"ARTG_pb1_sbeECOFL"');
dT3 = renamevars(dT3, 'chl_ug/L', 'chl_ugL');
dT3 = dT3(dT3.TmStamp <= datetime(2024,5,7), :);

dT4 = sqlread(conn, '"ARTG_pb1_sbeECONTU"');
dT4 = dT4(dT4.TmStamp <= datetime(2024,7,28), :);

dT5 = sqlread(conn, '"CLIS_pb4_SunaNO3"');
dT5 = dT5(dT5.TmStamp <= datetime(2020,4,5), :);

dTs = {dT1, dT2, dT3, dT4, dT5};
close(conn);

for i = 1:length(paras)
    for av = paras{i}
        para = table('Size', [10,12], ...
                     'VariableTypes', repmat({'double'},1,12), ...
                     'VariableNames', arrayfun(@num2str,1:12,'UniformOutput',false), ...
                     'RowNames',{'count','mean','std','median','upper','lower','bd99','bd84','bd16','bd1'});
        for nm = 1:12
            iu = find(month(dTs{i}.TmStamp)==nm);
            if ~isempty(iu)
                data = dTs{i}.(av{1})(iu);
                data = data(~isnan(data));
            else
                data = 0;
            end
            
            % Calibrate thresholds
            switch av{1}
                case 'chl_ugL'
                    rng = [0 1500];
                case {'NO3conc', 'NNO3'}
                    rng = [0 25];
                otherwise
                    rng = [0 5000];
            end
            
            para{1,nm} = length(iu);
            para{2,nm} = mean(data);
            para{3,nm} = std(data);
            para{4,nm} = median(data);
            para{5,nm} = min(prctile(data,99.99), rng(2));
            para{6,nm} = max(prctile(data,0.01), rng(1));
            para{7,nm} = min(prctile(data,99), rng(2));
            para{8,nm} = min(prctile(data,84), rng(2));
            para{9,nm} = max(prctile(data,16), rng(1));
            para{10,nm} = max(prctile(data,1), rng(1));
        end
        QAQC.(av{1}) = para;
    end
end

% Save QAQC parameters of buoy nutrients
save('QAQC_Para_buoyNut.mat', 'QAQC');