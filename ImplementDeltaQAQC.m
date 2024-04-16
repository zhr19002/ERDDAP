function d = ImplementDeltaQAQC(din, Para)
% 
% Implement sample to sample difference test.
% 
% Called from PlotARTG_2018_20_summary.m
% 
d = ones(size(din));
dd = abs(diff(din));                     % Note that the first and second
dd = dd([1 1:end]);                      % are treated the same

inan = find(dd > Para.Delta(1));
if ~isempty(inan)
    d(inan) = 3;
end

inan = find(dd > Para.Delta(2));
if ~isempty(inan)
    d(inan) = 4;
end

end