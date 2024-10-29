% 
% Identify and flag station nutrient data outliers
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 
% Calls GetCTDEEP_Nut_Data.m
% Calls ImplementThresholdTest.m
% Calls WriteStationNutNETCDF.m
% 

clc; clear;

% {'A2','A4','B3','C1','C2','D3','E1','09','15'}
% {'F2','F3','H2','H4','H6'}
% {'I2','J2','K2','M3'}
Astn = 'E1';

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
QAQC = load(['QAQC_Para_' stnGroup(1) 'Nutrients.mat']);
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

% Save QAQC results
NutQAQC = nut;
save(['CTDEEP_' Astn '_NutQAQC.mat'], 'NutQAQC');

%%
% Save all the data plotted in a structure that can be exported to NETCDF
latlon = [NutQAQC.latitude, NutQAQC.longitude];
for dp = {'S','B'}
    for field = fieldnames(NutQAQC.(dp{1}))'
        WriteNutNETCDF(Astn, dp{1}, field{1}, latlon, NutQAQC.(dp{1}).(field{1}));
    end
end