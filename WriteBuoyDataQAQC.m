% 
% Calls CheckBuoyDataQAQC.m
% Calls WriteNETCDFbuoyfile.m
% 

clc; clear;
buoy = 'ARTG'; locs = {'btm1', 'btm2', 'sfc'};

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
    buoyData = sqlread(conn,append('"',dbname,'"'));
    buoyData = sortrows(buoyData,'TmStamp');
    
    % Calculate rho and DOsat
    buoyData.('kg/m^3') = sw_dens(buoyData.('psu'),buoyData.('degC'),buoyData.('dBars'))-1000;
    sat = sw_satO2(buoyData.('psu'),buoyData.('degC'))*1.33; % Converted to mg/L
    buoyData.('percent') = 100*buoyData.('mg/L')./sat;
    
    % Add the pH column
    switch strcmp([buoy '_' loc{1}], 'ARTG_btm1')
        case 0
            buoyData.none(:) = NaN;
        case 1
            buoyData.none(:) = NaN;
            d = load('artg_sbe37_2013-2021_tablesrev.mat'); 
            d = d.d.artgbtm2_21; d = sortrows(d,'EST');
            buoyData.none(year(buoyData.TmStamp)==2021) = [d.pH; d.pH(end)];
    end
    
    close(conn);
    
    BuoyQAQC.(loc{1}).time = buoyData.TmStamp;
    BuoyQAQC.(loc{1}).depth = buoyData.depth;
    for av = {'T','S','DO','P','C','pH','rho','DOsat'}
        tbvars = categorical(buoyData.Properties.VariableNames);
        if iscategory(tbvars, av_by.(av{1}))
            % QAQC checks
            [~,dQAQC] = CheckBuoyDataQAQC(buoyData,loc{1},av{1});
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