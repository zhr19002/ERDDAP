clc; clear;

% {'A2','A4','B3','C1','C2','D3','E1','09','15'}
% {'F2','F3','H2','H4','H6'}
% {'I2','J2','K2','M3'}
Astn = 'A2';

% Fixed parameters
stnVars = {'sea_water_temperature','sea_water_salinity','oxygen_concentration_in_sea_wat', ...
           'sea_water_pressure','sea_water_electrical_conductivi','pH','sea_water_density', ...
           'percent_saturation','PAR','Chlorophyll','Corrected_Chlorophyll'};
avars = {'T','S','DO','P','C','pH','rho','DOsat','PAR','Chl','Corrected_Chl'};

% Read station group QAQC parameters
if ismember(Astn, {'A2','A4','B3','C1','C2','D3','E1','09','15'})
    stnGroup = 'WStations';
elseif ismember(Astn, {'F2','F3','H2','H4','H6'})
    stnGroup = 'CStations';
else
    stnGroup = 'EStations';
end
QAQC = load(['QAQC_Para_' stnGroup '.mat']);
QAQC = QAQC.QAQC;

% Write QAQCed station WQ files
for ZT = 0:5:100
    ZB = ZT+5;
    % Get station climatology data
    d = GetCTDEEP_Clim_Data(Astn, ZT, ZB, 1);
    if isempty(d)
        break;
    else
        clim = table();
        dpth = ['depth_' num2str(ZT) '_' num2str(ZB)];
        for field = fieldnames(d)'
            if ismember(field{1}, {'time','Start_Date','End_Date'})
                clim.(field{1}) = d.(field{1})/(24*3600) + datetime(1970,1,1);
                clim.(field{1}).TimeZone = 'UTC';
                clim.(field{1}).TimeZone = 'America/New_York';
            elseif ismember(field{1}, stnVars)
                i = find(strcmp(stnVars, field{1}));
                % Form QAQC structure
                clim.([avars{i} '_data']) = d.(stnVars{i});
                if ZT > 40
                    clim.([avars{i} '_Q'])(:) = 0;
                else
                    clim.([avars{i} '_Q']) = ...
                        ImplementThresholdTest(d.(stnVars{i}), clim.time, QAQC, dpth, avars{i});
                end
            else
                clim.(field{1}) = d.(field{1});
            end
        end
        % Create the "StationQAQC" table
        if ZT == 0
            StationQAQC = clim;
        else
            StationQAQC = [StationQAQC(:,:); clim(:,:)];
        end
    end
end

% Save the updated "StationQAQC" table to a CSV file
writetable(StationQAQC, ['DEEP_' Astn '_WQ_QAQC.csv']);

%%
% Read the CSV file into a table
tbl = ['DEEP_' Astn '_WQ_QAQC'];
StationQAQC = readtable([tbl '.csv']);
StationQAQC.time.Format = 'dd-MMM-yyyy HH:mm:ss';
StationQAQC.Start_Date.Format = 'dd-MMM-yyyy HH:mm:ss';
StationQAQC.End_Date.Format = 'dd-MMM-yyyy HH:mm:ss';
StationQAQC.Time_ON_Station = cellstr(StationQAQC.Time_ON_Station);
StationQAQC.Time_OFF_Station = cellstr(StationQAQC.Time_OFF_Station);
if ismember(Astn, {'09','15'})
    StationQAQC.station_name = ...
    arrayfun(@(x) sprintf('%02d',x),StationQAQC.station_name,'UniformOutput',false);
end

% Quoted to preserve case sensitivity
tblName = strcat('"',tbl,'"');
colNames = strcat('"',StationQAQC.Properties.VariableNames,'"');
StationQAQC.Properties.VariableNames = colNames;

% Define data type for each column
vNames = cell(1, 2*length(avars));
for i = 1:length(avars)
    vNames{2*i-1} = sprintf('"%s_data" %s',avars{i},'FLOAT');
    vNames{2*i} = sprintf('"%s_Q" %s',avars{i},'INTEGER');
end
query = strjoin(vNames, ', ');
query = ['CREATE TABLE ' tblName ' (' ...
         '"cruise_name" VARCHAR, "station_name" VARCHAR, "time" TIMESTAMP, ' ...
         '"latitude" FLOAT, "longitude" FLOAT, "depth_code" VARCHAR, "depth" FLOAT, ', ...
         query, ', "oxygen_sensor_temp" FLOAT, "winkler" FLOAT, ' ... 
         '"corrected_oxygen" FLOAT, "percent_saturation_100" FLOAT, ' ...
         '"Start_Date" TIMESTAMP, "End_Date" TIMESTAMP, ' ...
         '"Time_ON_Station" VARCHAR, "Time_OFF_Station" VARCHAR);'];

% Write the table to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','stationQAQC','PortNumber',5432);
execute(connQ, query);
try
    batchSize = 10000;
    for i = 1:ceil(height(StationQAQC)/batchSize)
        startRow = (i-1)*batchSize + 1;
        endRow = min(i*batchSize, height(StationQAQC));
        batchData = StationQAQC(startRow:endRow, :);
        % Write the batch to PostgreSQL
        sqlwrite(connQ, tblName, batchData);
        disp(['Row ' num2str(startRow) '-' num2str(endRow) ' written to PostgreSQL successfully.']);
    end
catch ME
    disp(ME.message);
end

% % Check the table in PostgreSQL
% tbldata = sqlfind(connQ, "");
% dT = sqlread(connQ, tblName);
% % Drop the table from PostgreSQL
% execute(connQ, strcat("DROP TABLE ",tblName));

close(connQ);

%%
% Write the "QAQC_Para_Stations" table to PostgreSQL
clc; clear;

dir = 'West'; % {'West','Center','East'}
QAQC = load(['QAQC_Para_' dir(1) 'Stations.mat']);
QAQC = QAQC.QAQC;

% Specify row and column names
rows = {'count';'mean';'std';'median';'upper';'lower';'bd99';'bd84';'bd16';'bd1'};
cols = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};

% Prepare data for the table
dps = fieldnames(QAQC)';
vars = fieldnames(QAQC.depth_0_5)';
col1 = cell(length(dps)*length(vars)*10, 1);
data = zeros(length(dps)*length(vars)*10, 12);
for i = 1:length(dps)
    for j = 1:length(vars)
        for k = 1:10
            index = (i-1)*length(vars)*10 + (j-1)*10 + k;
            col1{index} = [dps{i} '_' vars{j} '_' rows{k}];
            data(index, :) = table2array(QAQC.(dps{i}).(vars{j})(k,:));
        end
    end
end

% Generate the table
col1T = table(col1, 'VariableNames', {'Stats'});
dataT = array2table(data, 'VariableNames', cols);
qaqcT = [col1T, dataT];

% Connect to PostgreSQL
username = 'lisicos';
password = 'vncq489';
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','stationQAQC','PortNumber',5432);

% Write the table to PostgreSQL
tblName = strcat('"',['QAQC_Parameters_' dir '_Stations_WQ'],'"');
qaqcT.Properties.VariableNames = strcat('"',qaqcT.Properties.VariableNames,'"');
sqlwrite(connQ, tblName, qaqcT);

close(connQ);