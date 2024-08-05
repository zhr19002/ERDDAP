function d = GetUCONNDataForComps(buoy, NoFig)
% 
% Get nutrient sample data from "ArtGNutients.csv"
% 

% buoy = 'ARTG'; NoFig = 1;

opts = detectImportOptions('ArtGNutients.csv');
opts = setvaropts(opts,3:4,'InputFormat','MM/dd/uuuu');
T = readtable('ArtGNutients.csv', opts);

% ColumnNames: {'LIM #','FIELD #','Collected','Delivered','NOX','NO2','NO3','O-Phos'}
% Unit: mg/L
% Find rows with ARTG data
iu = find(contains(T.Var2,buoy));

% Get dates and NO3 values of water samples
d.daten = datetime(T.Var3(iu));
d.NOX = T.Var5(iu);
d.NO2 = T.Var6(iu);
d.NO3 = T.Var7(iu);
d.Phos = T.Var8(iu);

if NoFig == 1
    figure;
    plot(d.daten, d.NO2, 'r+', d.daten, d.NO3, 'b+', d.daten, d.Phos, 'g*');
    ylabel('mg/l');
    legend({'NO2','NO3','Phos'});
    xtickformat('MM/yy');
    title(buoy);
end

end