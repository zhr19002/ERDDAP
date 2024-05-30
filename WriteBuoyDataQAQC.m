clc; clear;
buoy = 'ARTG'; locs = {'btm1', 'btm2', 'sfc'};

% Write buoy files with QAQC tests to NETCDF buoy files
for loc = locs
    % Fixed parameters
    avar_buoy = struct('T','degC','S','psu','DO','mg/L','P','dBars','C','S/m', ...
                       'pH','none','rho','kg/m^3','DOsat','percent');
    buoy_station = struct('ARTG','E1','CLIS','C1','EXRX','A4');
    
    switch contains(loc{1},'btm')
        case 0
            ZT = 0; ZB = 3;
        case 1
            ZT = 20; ZB = 30;
    end
    
    % Connect to database
    username = 'lisicos';
    password = 'vncq489';
    conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
        'DatabaseName','provLNDB','PortNumber',5432);
    
    % tbldata = sqlfind(conn,"")
    
    % Extract tables from database
    dbname = append(buoy,"_pb2_sbe37",loc{1});
    buoy_loc = sqlread(conn,append('"',dbname,'"'));
    buoy_loc = sortrows(buoy_loc,'TmStamp');

    % Calculate rho and DOsat
    buoy_loc.('kg/m^3') = sw_dens(buoy_loc.('psu'),buoy_loc.('degC'),buoy_loc.('dBars'))-1000;
    sat = sw_satO2(buoy_loc.('psu'),buoy_loc.('degC'))*1.33; % Converted to mg/L
    buoy_loc.('percent') = 100*buoy_loc.('mg/L')./sat;
    
    close(conn);
    
    buoy_QAQC.(loc{1}).EST = buoy_loc.TmStamp;
    for avar = {'T','S','DO','P','C','pH','rho','DOsat'}
        tbvars = categorical(buoy_loc.Properties.VariableNames);
        if iscategory(tbvars, avar_buoy.(avar{1}))
            % Get station climatology data
            clim_stats = GetDEEPWQClimStats(buoy_station.(buoy),ZT,ZB,avar{1});
            % Buoy data cleaning
            para = mean(clim_stats.bd84 - clim_stats.bd16);
            buoydata = CleanBuoyData(buoy_loc,avar{1},para);
            % QAQC checks
            [~,buoydataQAQC] = CheckBuoyDataQAQC(buoydata,loc{1},avar{1},avar_buoy);
            buoy_QAQC.(loc{1}).(avar{1}) = buoydataQAQC;
            save([buoy '_' loc{1} '_QAQC.mat'], 'buoydataQAQC');
        end
    end
end

% Save all the data plotted in a structure that can be exported to NETCDF and to ERDDAP
latlon = [41 + 0.60/60, -(73 + 17.29/60)];
stnDep = 30;
WriteNETCDFbuoyfile(buoy, locs, latlon, stnDep, buoy_QAQC);