clc; clear;
Astn = 'E1'; Ayear = 2021; ZT = 0; ZB = 3;

% Get cruise names from CTDEEP data in a specific year
[~,~,CruiseNames] = GetCTDEEP_WQDataForComps(Astn, Ayear, 1:12);

% Get CTDEEP ship survey data
dCTD_Station = GetCTDEEP_CTD_Stats(Astn,CruiseNames,ZT,ZB);
