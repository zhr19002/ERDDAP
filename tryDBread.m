% 
% Make Database Connection
% 

username = 'lisicos';
password = 'vncq489';

conn = postgresql(username,password,'Server','merlin.dms.uconn.edu',...
    'DatabaseName','provLNDB','PortNumber',5432);

%tbldata = sqlfind(conn,"")

%Extract tables from database
ARTG_btm1 = sqlread(conn, '"ARTG_pb2_sbe37btm1"');
ARTG_btm2 = sqlread(conn, '"ARTG_pb2_sbe37btm2"');
ARTG_sfc = sqlread(conn, '"ARTG_pb2_sbe37sfc"');

%Filter 2023 ARTG data
ARTG_btm1_rf = ARTG_btm1.TmStamp > datetime(2023,01,01);
ARTG_btm2_rf = ARTG_btm2.TmStamp > datetime(2023,01,01);
ARTG_sfc_rf = ARTG_sfc.TmStamp > datetime(2023,01,01);

ARTG_btm1_2023 = sortrows(ARTG_btm1(ARTG_btm1_rf, :), 'TmStamp');
ARTG_btm2_2023 = sortrows(ARTG_btm2(ARTG_btm2_rf, :), 'TmStamp');
ARTG_sfc_2023 = sortrows(ARTG_sfc(ARTG_sfc_rf, :), 'TmStamp');

close(conn);