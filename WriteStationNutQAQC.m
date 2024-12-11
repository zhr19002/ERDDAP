% 
% Identify and flag station nutrient data outliers
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 
% Calls GetCTDEEP_Nut_Data.m
% Calls ImplementThresholdTest.m
% Calls WriteStationNutNETCDF.m
% 

clc; clear;
Astn = 'A4'; % {'A4','C1','E1','I2'}

% Fixed parameters
paras = {'BIOSI-LC','CHLA','DIP','DOC','NH#-LC','NOX-LC', ...
         'PC','PN','PP-LC','SIO2-LC','TDN-LC','TDP','TSS'};

% Read station group nutrients QAQC parameters
if ismember(Astn, {'A2','A4','B3','C1','C2','D3','E1','09','15'})
    stnGroup = 'WStations';
elseif ismember(Astn, {'F2','F3','H2','H4','H6'})
    stnGroup = 'CStations';
else
    stnGroup = 'EStations';
end
QAQC = load(['QAQC_' stnGroup '_Nutrient.mat']);
QAQC = QAQC.QAQC;

% Get station nutrient data
d = GetCTDEEP_Nut_Data(Astn, 1);
if ~isempty(d)
    nut.latitude = mode(d.latitude);
    nut.longitude = mode(d.longitude);
    % Seperate data based on depth_code
    for dp = {'S','B'}
        iu1 = find(startsWith(d.Depth_Code, dp{1}));
        for field = fieldnames(d)'
            dd.(dp{1}).(field{1}) = d.(field{1})(iu1);
        end
        % Seperate data based on parameters
        for para = paras
            iu2 = strcmp(dd.(dp{1}).Parameter, para{1});
            var = replace(para{1},'#-','_');
            var = replace(var,'-','_');
            nut.(dp{1}).(var).time = dd.(dp{1}).time(iu2)/(24*3600)+datetime(1970,1,1);
            dpth = [dp{1} '_Sample_Depth'];
            nut.(dp{1}).(var).depth = cellfun(@str2double, dd.(dp{1}).(dpth)(iu2));
            nut.(dp{1}).(var).data = cellfun(@str2double, dd.(dp{1}).Result(iu2));
            % Perform the threshold test
            d_tmp = nut.(dp{1}).(var).data;
            dt = nut.(dp{1}).(var).time;
            c_tmp = ImplementThresholdTest(d_tmp, dt, QAQC, dp{1}, var);
            nut.(dp{1}).(var).check = c_tmp;
        end
    end
end

% Save station nutrient QAQC parameters
for dp = {'S','B'}
    for av = paras
        var = replace(av{1},'#-','_');
        var = replace(var,'-','_');
        % Station nutrient data cleaning
        iu3 = find(nut.(dp{1}).(var).check==1);
        d_time = nut.(dp{1}).(var).time(iu3);
        d_data = nut.(dp{1}).(var).data(iu3);
        para = table('Size', [10,12], ...
                     'VariableTypes', repmat({'double'},1,12), ...
                     'VariableNames', arrayfun(@num2str,1:12,'UniformOutput',false), ...
                     'RowNames',{'count','mean','std','median','upper','lower','bd99','bd84','bd16','bd1'});
        for nm = 1:12
            iu4 = find(month(d_time)==nm);
            if ~isempty(iu4)
                data = d_data(iu4);
                data = data(~isnan(data));
            else
                data = 0;
            end
            
            para{1,nm} = length(iu4);
            para{2,nm} = mean(data);
            para{3,nm} = std(data);
            para{4,nm} = median(data);
            para{5,nm} = max(data);
            para{6,nm} = min(data);
            para{7,nm} = prctile(data,99);
            para{8,nm} = prctile(data,84);
            para{9,nm} = prctile(data,16);
            para{10,nm} = prctile(data,1);
        end
        QAQC.(dp{1}).(var) = para;
    end
end
save(['QAQC_' Astn '_Nutrient.mat'], 'QAQC');

%%
% Save all the data plotted in a structure that can be exported to NETCDF
latlon = [nut.latitude, nut.longitude];
for dp = {'S','B'}
    for field = fieldnames(nut.(dp{1}))'
        WriteNutNETCDF(Astn, dp{1}, field{1}, latlon, nut.(dp{1}).(field{1}));
    end
end