clc; clear;
buoy = 'EXRX'; loc = 'mid'; avar = 'percent';

% Connect to database
username = 'lisicos';
password = 'vncq489';
conn = postgresql(username,password,'Server','merlin.dms.uconn.edu', ...
    'DatabaseName','provLNDB','PortNumber',5432);

% Extract tables from database
dbname = append(buoy,"_pb2_sbe37",loc);
buoy_loc = sqlread(conn,append('"',dbname,'"'));
buoy_loc = sortrows(buoy_loc,'TmStamp');

% Calculate rho and DOsat
buoy_loc.('kg/m^3') = sw_dens(buoy_loc.('psu'),buoy_loc.('degC'),buoy_loc.('dBars'))-1000;
sat = sw_satO2(buoy_loc.('psu'),buoy_loc.('degC'))*1.33; % Converted to mg/L
buoy_loc.('percent') = 100*buoy_loc.('mg/L')./sat;

close(conn);

%%
% {'T','degC','S','psu','DO','mg/L','P','dBars','C','S/m'}
% {'pH','none','rho','kg/m^3','DOsat','percent'}
d = buoy_loc.(avar);
para1 = 0.05; para2 = 0.25; para3 = 0.5; 
para4 = 99.5; para5 = 99.75; para6 = 99.95;

max_min_value = prctile(d, [para1 para2 para3 para4 para5 para6]);
max_min_value

dd = abs(diff(d)); dd = dd([1 1:end]);
jump_value = prctile(dd, [para4 para5 para6]);
jump_value

SPK_REF = (d(1:end-2) + d(3:end))/2;
SPK_REF = SPK_REF([1 1:end end]);
spk = abs(d-SPK_REF);
spk_value = prctile(spk, [para4 para5 para6]);
spk_value