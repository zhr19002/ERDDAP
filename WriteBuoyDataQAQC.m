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
buoy = 'ARTG'; locs = {'btm1','btm2','sfc'};
% buoy = 'EXRX'; locs = {'btm2','mid','sfc'};
% buoy = 'CLIS'; locs = {'btm'};

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
    buoyT = sqlread(conn,append('"',dbname,'"'));
    buoyT = sortrows(buoyT,'TmStamp');
    close(conn);

    % Calculate rho
    sw_S = buoyT.('psu');
    sw_T = buoyT.('degC');
    sw_P = buoyT.('dBars');
    buoyT.('kg/m^3') = real(sw_dens(sw_S,sw_T,sw_P)-1000);
    % Calculate DOsat
    sat = sw_satO2(buoyT.('psu'),buoyT.('degC'))*1.33; % Converted to mg/L
    buoyT.('percent') = 100*buoyT.('mg/L')./sat;
    % Replace DOsat values greater than 1000 with NaN
    buoyT.('percent')(buoyT.('percent') > 1000) = NaN;
    
    % Add the pH column
    switch strcmp([buoy '_' loc{1}], 'ARTG_btm1')
        case 0
            buoyT.none(:) = NaN;
        case 1
            buoyT.none(:) = NaN;
            d = load('artg_sbe37_2013-2021_tablesrev.mat'); 
            d = d.d.artgbtm2_21; d = sortrows(d,'EST');
            buoyT.none(year(buoyT.TmStamp)==2021) = [d.pH; d.pH(end)];
    end
    
    % Clean buoy data
    buoyData = CleanBuoyData(buoyT, av_by);
    
    BuoyQAQC.(loc{1}).time = buoyData.TmStamp;
    BuoyQAQC.(loc{1}).depth = buoyData.depth;
    for av = {'T','S','DO','P','C','pH','rho','DOsat'}
        tbvars = categorical(buoyData.Properties.VariableNames);
        if iscategory(tbvars, av_by.(av{1}))
            % QAQC tests
            dQAQC = CheckBuoyDataQAQC(buoyData, buoy, loc{1}, av{1});
            BuoyQAQC.(loc{1}).(av{1}) = dQAQC;
        end
    end
end

% Save QAQC results
save([buoy '_QAQC.mat'], 'BuoyQAQC');

%%
% Save all the data plotted in a structure that can be exported to NETCDF
latlon = [mode(buoyData.latitude), mode(buoyData.longitude)];
for i = 1:length(locs)
    stnDep = max(BuoyQAQC.(locs{i}).depth);
    WriteBuoyNETCDF(buoy, locs{i}, latlon, stnDep, BuoyQAQC.(locs{i}));
end