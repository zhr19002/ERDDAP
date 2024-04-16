function d = GetUCONNTSSDataForComps(aBuoy, NoFig)
% 
% Get the TSS sample data from the XLS file
% Calls "smc2021Data.xlsx"
% 

% aBuoy = 'ARTG'; NoFig = 1;

aBuoy = upper(aBuoy);
opts = detectImportOptions('smc2021Data.xlsx');
opts = setvaropts(opts,1,'InputFormat','MM/dd/uuuu');
T = readtable('smc2021Data.xlsx', opts);

% ColumnNames: {'TIMESTAMP_EST','STATION','DEPTH_M','SampleID','smc_mgL'}
% Units all mg/L
% Find the rows with the ARTG data
iBuoy = strfind(upper(T.STATION), aBuoy);
nBuoy = zeros(size(T.STATION));
for nn = 1:size(T.STATION,1)
    if iBuoy{nn} == 1
        nBuoy(nn) = 1;
    end
end
inBuoy = find(nBuoy==1);

% Now get the date of the water samples and the value of NO3
d.daten = datetime(T.TIMESTAMP_EST(inBuoy));
d.TSSmean = T.smc_mgL(inBuoy);

if NoFig == 1
    figure;
    plot(d.daten, d.TSSmean, 'r+');
    ylabel('mg/l');
    legend({'Tss'});
    xtickformat('yy/MM');
    title(aBuoy);
end