% 
% Identify and flag buoy climatology data outliers through 5 QAQC tests
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 
% Calls sw_dens.m
% Calls sw_satO2.m
% Calls CleanBuoyData.m
% Calls CheckBuoyTableQAQC.m
% 

clc; clear;

stns = 'WStations'; buoy = 'ARTG'; locs = {'btm1','btm2','sfc'};
% stns = 'WStations'; buoy = 'EXRX'; locs = {'btm2','mid','sfc'};
% stns = 'CStations'; buoy = 'CLIS'; locs = {'btm'};
% stns = 'WStations'; buoy = 'WLIS'; locs = {'btm1','btm2','mid','sfc'};
% stns = 'CStations'; buoy = 'clis_cr1x'; locs = {'Btm','Sfc'};

% Fixed parameters
av_by = struct('T','degC','S','psu','DO','mg/L','P','dBars','C','S/m', ...
               'pH','none','rho','kg/m^3','DOsat','percent');

% Read station group QAQC parameters
QAQC = load(['QAQC_Para_' stns '.mat']);
QAQC = QAQC.QAQC;

% Write buoy files with QAQC tests to NETCDF buoy files
for loc = locs
    % Connect to database
    username = 'lisicos';
    password = 'vncq489';
    conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
        'DatabaseName','provLNDB','PortNumber',5432);
    
    % Extract tables from database
    dbname = append(buoy,"_pb2_sbe37",loc{1});
    if contains(buoy, '_')
        dbname = append(buoy,"PB4_sbe37",loc{1});
    end
    dT = sqlread(conn,append('"',dbname,'"'));
    dT = sortrows(dT,'TmStamp');
    close(conn);
    
    % Calculate rho
    sw_S = dT.('psu');
    sw_T = dT.('degC');
    sw_P = dT.('dBars');
    dT.('kg/m^3') = real(sw_dens(sw_S,sw_T,sw_P)-1000);
    % Calculate DOsat
    sat = sw_satO2(dT.('psu'),dT.('degC'))*1.33; % Converted to mg/L
    dT.('percent') = 100*dT.('mg/L')./sat;
    % Replace DOsat values greater than 1000 with NaN
    dT.('percent')(dT.('percent') > 1000) = NaN;
    
    % Add the pH column
    switch strcmp([buoy '_' loc{1}], 'ARTG_btm1')
        case 0
            dT.none(:) = NaN;
        case 1
            dT.none(:) = NaN;
            d0 = load('artg_sbe37_2013-2021_tablesrev.mat'); 
            d0 = d0.d.artgbtm2_21; d0 = sortrows(d0,'EST');
            dT.none(year(dT.TmStamp)==2021) = [d0.pH; d0.pH(end)];
    end
    
    % Eliminate outliers for specific columns
    dT.latitude(:) = mode(dT.latitude);
    dT.longitude(:) = mode(dT.longitude);
    dT.station(:) = mode(categorical(dT.station));
    dT.mooring_site_desc(:) = mode(categorical(dT.mooring_site_desc));
    
    % Clean buoy climatology data
    d = CleanBuoyData(dT, av_by);
    
    % Initialize BuoyQAQC table
    BuoyQAQC = table();
    BuoyQAQC.TmStamp = d.TmStamp;
    BuoyQAQC.depth = d.dBars;
    
    for av = {'T','S','DO','P','C','pH','rho','DOsat'}
        tbvars = categorical(d.Properties.VariableNames);
        if iscategory(tbvars, av_by.(av{1}))
            % Run QAQC tests
            [dQ, dC] = CheckBuoyTableQAQC(d, loc{1}, QAQC, av_by, av{1});
            BuoyQAQC.(av{1}) = d.(av_by.(av{1}));
            BuoyQAQC.([av{1} 'Q']) = dQ;
            BuoyQAQC.(['Failed' av{1} 'Q']) = dC;
        end
    end
    
    BuoyQAQC.latitude = d.latitude;
    BuoyQAQC.longitude = d.longitude;
    BuoyQAQC.station = d.station;
    BuoyQAQC.mooring_site_desc = d.mooring_site_desc;
    
    % Save the updated BuoyQAQC table
    save([buoy '_' loc{1} '_QAQC.mat'], 'BuoyQAQC');
end

%%
% Prepare the "BuoyQAQC" table to be inserted
num = 3;
load([buoy '_' locs{num} '_QAQC.mat'], 'BuoyQAQC');
BuoyQAQC.TmStamp = datetime(BuoyQAQC.TmStamp);
BuoyQAQC.depth = double(BuoyQAQC.depth);
for av = {'T','S','DO','P','C','pH','rho','DOsat'}
    BuoyQAQC.(av{1}) = double(BuoyQAQC.(av{1}));
    BuoyQAQC.([av{1} 'Q']) = int32(BuoyQAQC.([av{1} 'Q']));
    BuoyQAQC.(['Failed' av{1} 'Q']) = int32(BuoyQAQC.(['Failed' av{1} 'Q']));
end
BuoyQAQC.latitude = double(BuoyQAQC.latitude);
BuoyQAQC.longitude = double(BuoyQAQC.longitude);
BuoyQAQC.station = string(BuoyQAQC.station);
BuoyQAQC.mooring_site_desc = string(BuoyQAQC.mooring_site_desc);

% Connect to the "buoyQAQC" database
driver = 'org.postgresql.Driver';
url = 'jdbc:postgresql://merlin.dms.uconn.edu:5432/buoyQAQC';
connQ = database('buoyQAQC', username, password, driver, url);

% Construct the SQL INSERT statement
tblName = [buoy '_' locs{num} '_QAQC'];
colNames = strjoin(BuoyQAQC.Properties.VariableNames, ', ');
plcHolder = strjoin(repmat({'?'}, 1, width(BuoyQAQC)), ', ');
query = sprintf('INSERT INTO public.%s (%s) VALUES (%s)', tblName, colNames, plcHolder);

% Begin a transaction
exec(connQ, 'BEGIN');

% Insert data into PostgreSQL table row by row
tblCell = table2cell(BuoyQAQC);
for i = 1:5
    rowData = tblCell(i,:);
    exec(connQ, query, rowData{:});
end

% Commit the transaction
exec(connQ, 'COMMIT');

close(connQ);

%%
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);
tbldata = sqlfind(connQ, "")
dT = sqlread(connQ, tblName);
close(connQ);