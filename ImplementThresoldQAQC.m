function d = ImplementThresoldQAQC(din, daten, Para)
%
%  threshold data or Gross Range Test in QARTOD 
%  and missing value test.
%  Called from PlotARTG_2018_20_summary.m
%
%  ScaleFactor allows the unit used in the DEEP data to be adjusted 
%  to that in the data. eg. for the SUNA, the unit is  muM/g but the 
%  CTDEEP use mg/l so Scale Factor = 1000/14 is required.
%
%  Updated Jan 2023 to implement the monthly climatology check.
%  That requires the climatology file created by
%  MakeMonthlyNutrientClimatology 
%  note that that data in in mg Nitrogen/l
%
ScaleFactor = 1000/14;
dclm = [];

d = ones(size(din));
inan = find(din<Para.Thesholds(1) | din>Para.Thesholds(2) | isnan(din));
if ~isempty(inan)
    d(inan) = 4;
end

[~, mm, ~] = datevec(daten);

if ~isempty(dclm)
    for ii = 1:12
        iu = (ii == mm);
        if(din>dclm.upper(ii)*ScaleFactor || din<0)
            d(iu) = 3;
        end
    end
end

end