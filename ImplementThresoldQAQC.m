function d = ImplementThresoldQAQC(din, daten, Para)
% 
% Threshold data or Gross Range Test in QARTOD and missing value test.
% 
% ScaleFactor allows the unit used in the DEEP data to be adjusted 
% to that in the data. eg. for the SUNA, the unit is  muM/g but the 
% CTDEEP use mg/l so Scale Factor = 1000/14 is required.
% 
% Called from MakeDataArchive.m
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