function d = ImplementDeltaQAQC(din, Para)
% 
% Implement sample to sample difference test
% 
% Called from MakeDataArchive.m
% 

d = ones(size(din));
dd = abs(diff(din));  % The first and second are treated the same
dd = dd([1 1:end]);

inan = find(dd > Para.Delta(1));
if ~isempty(inan)
    d(inan) = 3;
end

inan = find(dd > Para.Delta(2));
if ~isempty(inan)
    d(inan) = 4;
end

end