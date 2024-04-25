% Plot the summary DO, S and T for the EPA LISS ARTG 2021 Report
% 
% Calls:
%   MakeDataArchive.m
%   GetSpikeStats.m
%   WriteNETCDFbuoyfile.m
% 

% Define the names of the variables in the input data
av = {'artgbtm1_', 'artgbtm2_', 'artgsfc_'};
ac = 'gkm';
IplotDOY = 1;           % = 1 makes plots relative to Day of year

% Variable that are options
% {'sal00','sbeopoxMg','tv290C','prdM','cond0mS','pH'}
avar = 'sal00';
S = MakeDataArchive(avar, av, ac, IplotDOY);
[prcS] = GetSpikeStats(S, avar, av);

avar = 'sbeopoxMg';
DO = MakeDataArchive(avar, av, ac, IplotDOY);
[prcDO] = GetSpikeStats(DO, avar, av);

avar = 'tv290C';
T = MakeDataArchive(avar, av, ac, IplotDOY);
[prcT] = GetSpikeStats(T, avar, av);

avar = 'prdM';
P = MakeDataArchive(avar, av, ac, IplotDOY);
[prcP] = GetSpikeStats(P,avar,av);

avar = 'cond0mS';
C = MakeDataArchive(avar, av, ac, IplotDOY);
[prcC] = GetSpikeStats(C, avar, av);

avar = 'pH';
pH = MakeDataArchive(avar, av, ac, IplotDOY);
[prcpH] = GetSpikeStats(pH, avar, av);
%%
% Output file created
save('ARTG_2013-2021.mat','S','T','DO','P','C','pH');

% Save all the data plotted in a structure that can be exported to NETCDF and to ERDDAP
latlon = [41 + 0.60/60, -(73 + 17.29/60)];
stnDep = 30;
% Pass all the screened data from the buoy at each level to output nc file
WriteNETCDFbuoyfile('ARTG', av, latlon, stnDep, S, T, DO, P, C, pH);