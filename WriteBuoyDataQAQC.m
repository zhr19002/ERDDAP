% 
% Calls GetDEEPWQClimStats.m
% Calls CleanBuoyData.m
% Calls CheckBuoyDataQAQC.m
% Calls WriteNETCDFbuoyfile.m
% 

clc; clear;
buoy = 'ARTG'; locs = {'btm1', 'btm2', 'sfc'};

% Write buoy files with QAQC tests to NETCDF buoy files
for loc = locs
    % Fixed parameters
    av_by = struct('T','degC','S','psu','DO','mg/L','P','dBars','C','S/m', ...
                   'pH','none','rho','kg/m^3','DOsat','percent');
    by_stn = struct('ARTG','E1','CLIS','C1','EXRX','A4');
    
    switch loc{1}
        case 'sfc'
            ZT = 0; ZB = 3;
        case 'mid'
            ZT = 5; ZB = 15;
        case {'btm','btm1','btm2'}
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
    
    % Add the pH column
    switch strcmp([buoy '_' loc{1}], 'ARTG_btm1')
        case 0
            buoy_loc.none(:) = NaN;
        case 1
            buoy_loc.none(:) = NaN;
            d = load('artg_sbe37_2013-2021_tablesrev.mat'); 
            d = d.d.artgbtm2_21; d = sortrows(d,'EST');
            buoy_loc.none(year(buoy_loc.TmStamp)==2021) = [d.pH; d.pH(end)];
    end
    
    close(conn);
    
    BuoyQAQC.(loc{1}).time = buoy_loc.TmStamp;
    BuoyQAQC.(loc{1}).depth = buoy_loc.depth;
    for av = {'T','S','DO','P','C','pH','rho','DOsat'}
        tbvars = categorical(buoy_loc.Properties.VariableNames);
        if iscategory(tbvars, av_by.(av{1}))
            % Get station climatology data
            stats = GetDEEPWQClimStats(by_stn.(buoy),ZT,ZB,av{1});
            % Buoy data cleaning
            para = mean(stats.bd84 - stats.bd16);
            buoyData = CleanBuoyData(buoy_loc,av{1},para);
            % QAQC checks
            [~,dQAQC] = CheckBuoyDataQAQC(buoyData,loc{1},av{1},av_by);
            BuoyQAQC.(loc{1}).(av{1}) = dQAQC;
        end
    end
end

% Save QAQC results
save([buoy '_QAQC.mat'], 'BuoyQAQC');

%%
% Save all the data plotted in a structure that can be exported to NETCDF and to ERDDAP
latlon = [41 + 0.60/60, -(73 + 17.29/60)];
stnDep = 30;
WriteNETCDFbuoyfile(buoy, locs, latlon, stnDep, BuoyQAQC);