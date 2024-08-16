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

stns = 'WStations'; buoy = 'ARTG'; locs = {'btm1','btm2','sfc'};
% stns = 'WStations'; buoy = 'EXRX'; locs = {'btm2','mid','sfc'};
% stns = 'CStations'; buoy = 'CLIS'; locs = {'btm'};

% Fixed parameters
av_by = struct('T','degC','S','psu','DO','mg/L','P','dBars','C','S/m', ...
               'pH','none','rho','kg/m^3','DOsat','percent');

% Write buoy files with QAQC tests to NETCDF buoy files
for loc = locs
    % Connect to database
    username = 'lisicos';
    password = 'vncq489';
    conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
        'DatabaseName','provLNDB','PortNumber',5432);
    
    % tbldata = sqlfind(conn,"")
    
    % Extract tables from database
    dbname = append(buoy,"_pb2_sbe37",loc{1});
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
    
    % Clean buoy data
    d = CleanBuoyData(dT, av_by);
    
    BuoyQAQC.(loc{1}).time = d.TmStamp;
    BuoyQAQC.(loc{1}).depth = d.depth;
    for av = {'T','S','DO','P','C','pH','rho','DOsat'}
        tbvars = categorical(d.Properties.VariableNames);
        if iscategory(tbvars, av_by.(av{1}))
            % QAQC tests
            dQ = CheckBuoyDataQAQC(d, stns, loc{1}, av_by, av{1});
            BuoyQAQC.(loc{1}).(av{1}) = dQ;
        end
    end
end

% Save QAQC results
save(['Buoy_' buoy '_QAQC.mat'], 'BuoyQAQC');

%%
% Save all the data plotted in a structure that can be exported to NETCDF
latlon = [mode(d.latitude), mode(d.longitude)];
for loc = locs
    stnDep = max(BuoyQAQC.(loc{1}).depth);
    WriteBuoyNETCDF(buoy, loc{1}, latlon, stnDep, BuoyQAQC.(loc{1}));
end