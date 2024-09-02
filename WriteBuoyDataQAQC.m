% 
% Identify and flag buoy climatology data outliers through 5 QAQC tests
% (1 = pass; 3 = beyond 98% data range; 4 = beyond max-min range)
% 
% Calls sw_dens.m
% Calls sw_satO2.m
% Calls CleanBuoyData.m
% Calls CheckBuoyDataQAQC.m
% Calls WriteBuoyNETCDF.m
% 

clc; clear;
output = 1; % (1 = struct, 2 = table)

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

% Write buoy files with QAQC tests
for loc = locs
    % Connect to database
    username = 'lisicos';
    password = 'vncq489';
    conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
        'DatabaseName','provLNDB','PortNumber',5432);
    
    % tbldata = sqlfind(conn,"")
    
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
    
    % Clean buoy data
    d = CleanBuoyData(dT, av_by);
    
    if output == 1
        % Create the "BuoyQAQC" struct
        BuoyQAQC = struct();
        BuoyQAQC.(loc{1}).time = d.TmStamp;
        BuoyQAQC.(loc{1}).depth = d.dBars;
        for av = {'T','S','DO','P','C','pH','rho','DOsat'}
            tbvars = categorical(d.Properties.VariableNames);
            if iscategory(tbvars, av_by.(av{1}))
                % Run QAQC tests
                [dQ, dC] = CheckBuoyDataQAQC(d, loc{1}, QAQC, av_by, av{1});
                BuoyQAQC.(loc{1}).(av{1}).data = d.(av_by.(av{1}));
                BuoyQAQC.(loc{1}).(av{1}).QAQCTests = dQ;
                BuoyQAQC.(loc{1}).(av{1}).FailedTestsCount = dC;
            end
        end
    else
        % Create the "BuoyQAQC" table
        BuoyQAQC = table();
        BuoyQAQC.TmStamp = d.TmStamp;
        BuoyQAQC.depth = d.dBars;
        for av = {'T','S','DO','P','C','pH','rho','DOsat'}
            tbvars = categorical(d.Properties.VariableNames);
            if iscategory(tbvars, av_by.(av{1}))
                % Run QAQC tests
                [dQ, dC] = CheckBuoyDataQAQC(d, loc{1}, QAQC, av_by, av{1});
                BuoyQAQC.(av{1}) = d.(av_by.(av{1}));
                BuoyQAQC.([av{1} 'Q']) = dQ;
                BuoyQAQC.(['Failed' av{1} 'Q']) = dC;
            end
        end
        BuoyQAQC.latitude = d.latitude;
        BuoyQAQC.longitude = d.longitude;
        BuoyQAQC.station = d.station;
        BuoyQAQC.mooring_site_desc = d.mooring_site_desc;

        % Save the updated "BuoyQAQC" table to a CSV file
        writetable(BuoyQAQC, [buoy '_' loc{1} '_QAQC.csv']);
    end
end

%%
if output == 1
    save(['Buoy_' buoy '_QAQC.mat'], 'BuoyQAQC');
    % Save all the data plotted in a structure that can be exported to NETCDF
    latlon = [mode(d.latitude), mode(d.longitude)];
    for loc = locs
        stnDep = max(BuoyQAQC.(loc{1}).depth);
        WriteBuoyNETCDF(buoy, loc{1}, latlon, stnDep, BuoyQAQC.(loc{1}));
    end
else
    % Read the CSV file into a table
    num = 3;
    tblName = [buoy '_' locs{num} '_QAQC'];
    BuoyQAQC = readtable(tblName);
    
    % Connect to the "buoyQAQC" database
    driver = 'org.postgresql.Driver';
    url = 'jdbc:postgresql://merlin.dms.uconn.edu:5432/buoyQAQC';
    connQ = database('buoyQAQC', username, password, driver, url);
    
    % Construct and execute the COPY command
    query = sprintf('COPY public.%s FROM ''%s'' WITH (FORMAT csv, HEADER true)', tblName, tblName);
    try
        exec(connQ, query);
        disp('Data successfully copied into PostgreSQL table.');
    catch ME
        disp('Error executing COPY command:');
        disp(ME.message);
    end
    
    close(connQ);
end

%%
connQ = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
     'DatabaseName','buoyQAQC','PortNumber',5432);
tbldata = sqlfind(connQ, "");
dT = sqlread(connQ, tblName);
close(connQ);