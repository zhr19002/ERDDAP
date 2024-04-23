function d = GetUCONNDataForComps(aBuoy, NoFig)
% 
% Get the nutrient sample data from the XLS file
% 
% Calls "ArtGNutients.csv"
% Called from Proc2021_pH_data.m
% 

% aBuoy = 'ARTG'; NoFig = 1;

aBuoy = upper(aBuoy);
opts = detectImportOptions('ArtGNutients.csv');
opts = setvaropts(opts,3:4,'InputFormat','MM/dd/uuuu');
T = readtable('ArtGNutients.csv', opts);

% ColumnNames: {'LIM #','FIELD #','Collected','Delivered','NOX','NO2','NO3','O-Phos'}
% Units all mg/L
% Find the rows with the ARTG data
iBuoy = strfind(upper(T.Var2), aBuoy);
nBuoy = zeros(size(T.Var2));
for nn = 1:size(T.Var2,1)
    if iBuoy{nn} == 1
        nBuoy(nn) = 1;
    end
end
inBuoy = find(nBuoy==1);

% Now get the date of the water samples and the value of NO3
d.daten = datetime(T.Var3(inBuoy));
d.NOX = T.Var5(inBuoy);
d.NO2 = T.Var6(inBuoy);
d.NO3 = T.Var7(inBuoy);
d.Phos = T.Var8(inBuoy);

if NoFig == 1
    figure;
    plot(d.daten, d.NO2, 'r+', d.daten, d.NO3, 'b+', d.daten, d.Phos, 'g*'); 
    ylabel('Mg/l');
    legend({'NO_2','NO_3','Phos'});
    xtickformat('MMM-yy');
    title(aBuoy);
end

end