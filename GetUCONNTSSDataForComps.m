function d = GetUCONNTSSDataForComps(buoy, NoFig)
% 
% Get TSS sample data from "smc2021Data.xlsx"
% 

% buoy = 'ARTG'; NoFig = 1;

opts = detectImportOptions('smc2021Data.xlsx');
opts = setvaropts(opts,1,'InputFormat','MM/dd/uuuu');
T = readtable('smc2021Data.xlsx', opts);

% ColumnNames: {'TIMESTAMP_EST','STATION','DEPTH_M','SampleID','smc_mgL'}
% Unit: mg/L
% Find rows with ARTG data
iu = find(contains(T.STATION,buoy));

% Get dates and TSS values of water samples
d.daten = datetime(T.TIMESTAMP_EST(iu));
d.TSSmean = T.smc_mgL(iu);

if NoFig == 1
    figure;
    plot(d.daten, d.TSSmean, 'r+');
    ylabel('TSS (mg/l)');
    xtickformat('MM/yy');
    title(buoy);
end

end