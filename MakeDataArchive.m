function ARTG = MakeDataArchive(avar, av, ac, IplotDOY)

% set the QAQC parameters
switch avar
    case 'tv290C'
        QAQC.Thesholds = [0 30];   % only data in this range is acceptable
        QAQC.Delta = [2 2];            % only time changes smaller than this are allowed
        QAQC.THRSHLD = [1 1.9; 0.6 2];
    
    case 'sal00'
        QAQC.Thesholds = [25 30];  % only data in this range is acceptable
        QAQC.Delta = [0.75 0.75];         % only time changes smaller than this are allowed
        QAQC.THRSHLD = [0.6 5; 0.3 1];    % [surface high & Low ; bottom high and low]
    
    case 'sbeopoxMg'
        QAQC.Thesholds = [0 13];   % only data in this range is acceptable 
        QAQC.Delta = [1.25 1.25];         % only time changes smaller than this are allowed
        QAQC.THRSHLD = [0.5 5; 0.5 1];
    
    case 'prdM'
        QAQC.Thesholds = [0 30];   % only data in this range is acceptable 
        QAQC.Delta = [3 3];            % only time changes smaller than this are allowed
        QAQC.THRSHLD = [0.18 0.28; 0.6 1.17];
    
    case 'cond0mS'
        QAQC.Thesholds = [24 50];  % only data in this range is acceptable 
        QAQC.Delta = [0.2 0.2];          % only time changes smaller than this are allowed    
        QAQC.THRSHLD = [0.96 6; 0.5 1.5];
    
    case 'rho'
        QAQC.Thesholds = [24 50];  % only data in this range is acceptable 
        QAQC.Delta = [0.2 0.2];          % only time changes smaller than this are allowed    
        QAQC.THRSHLD = [0.96 6; 0.5 1.5];
        
    case 'pH'
        QAQC.Thesholds = [6 8];    % only data in this range is acceptable 
        QAQC.Delta = [0.04 0.04];         % only time changes smaller than this are allowed    
        QAQC.THRSHLD = [0.03 0.06; 0.03 0.06];
    
    otherwise
        disp('Variable name incorrect');
        return
end

QAQC.ExpectedTimeIncr = 0.25/24;     % expected data sample period (days)
QAQC.TolExpectedTimeIncr = 0.25/48;  % tolerance in sample period  (days)
QAQC.PresIntvTest = [0 3; 20 30];    % expected pressure range (dBar) for
                                     % surface and bottom

% this file was created from artg_sbe37_2013-2021_tablesrev.mat
NyMax = 21;
d = load('artg_sbe37_2013-2021_tablesrev.mat'); d = d.d;

% 
% check for the required data
% 

% field names
vnames = {'prdM','tv290C','cond0mS','sal00','sbeopoxMg','EST','pH'};

% if one is missing, fill with NaN
for nv = 1:length(av)
    for nn = 13:NyMax
        af = [av{nv} num2str(nn)];
        if isfield(d, af)
            T = d.(af);
            disp(['Year: ' num2str(2000+nn) ': ' av{nv}]);
            VarBad = CheckMatFileVarNames(T, vnames);       
            if any(VarBad ~= 1)
                nfx = find(VarBad == 0);
                disp([vnames{nfx} ' missing in ' af '********']); 
                for jn = 1:length(nfx)
                    disp(['filling ' vnames{nfx} ' in ' af ' with NaNs']);
                    d.(af).(vnames{nfx(jn)}) = d.(af).EST * NaN;
                end
            end    
        end
    end
end
                                  
avar1 = [avar 'QAQCTest1'];
avar2 = [avar 'QAQCTest2'];
avar3 = [avar 'QAQCTest3'];
avar4 = [avar 'QAQCTest4'];
avar5 = [avar 'QAQCTest5'];
avarT = [avar 'QAQCTestCount'];

figure; hold on;

for nv = 1:length(av)                           % for each sensor
    
    dataout = []; timeout = [];
    QAQCout1 = []; QAQCout2 = [];
    QAQCout3 = []; QAQCout4 = [];
    QAQCout5 = []; QAQCtest = [];
    
    for nn = 13:NyMax                           % for each year
        af = [av{nv} num2str(nn)];
        if isfield(d, af)
            T = table2struct(d.(af), 'ToScalar', true);
            
            if isfield(T, avar)
                T.(avarT) = zeros(size(T.(avar)));  % Zero Counter for number of tests
                                                    % Do tests and increment counter
                T.(avar1) = ImplementThresoldQAQC(T.(avar), T.EST, QAQC);
                T.(avarT) = T.(avarT) + 1;
                
                T.(avar2) = ImplementDeltaQAQC(T.(avar), QAQC);
                T.(avarT) = T.(avarT) + 1;
                
                T.(avar3) = ImplementGapTestQAQC(T.EST, QAQC);
                T.(avarT) = T.(avarT) + 1;
                
                T.(avar4) = ImplementPresIntvTestQAQC(T.prdM, QAQC, av{nv});
                T.(avarT) = T.(avarT) + 1;
                
                T.(avar5) = ImplementSpikeTestQAQC(T.(avar), QAQC, av{nv});
                T.(avarT) = T.(avarT) + 1;
                
                iu = find(T.(avar1)+T.(avar2)+T.(avar3)+T.(avar4)+ ...
                    T.(avar5) == T.(avarT));
                
                tmp = datevec(T.EST(iu));
                if IplotDOY == 1
                    [yr, ~, ~] = datevec(T.EST);
                    duration = days(datetime(tmp) - datetime(min(yr),1,1));
                    plot(duration, T.(avar)(iu), '-');
                else
                    plot(datetime(tmp), T.(avar)(iu), [ac(nv) '.']);
                end
            end
        end

        if isfield(T, avar)                         % create output arrays
            dataout = cat(1, dataout, T.(avar)(:)); % raw data
            timeout = cat(1, timeout, T.EST(:));    % data times
            QAQCout1 = cat(1, QAQCout1, T.(avar1)(:));
            QAQCout2 = cat(1, QAQCout2, T.(avar2)(:));
            QAQCout3 = cat(1, QAQCout3, T.(avar3)(:));
            QAQCout4 = cat(1, QAQCout4, T.(avar4)(:));
            QAQCout5 = cat(1, QAQCout5, T.(avar5)(:));
            QAQCtest = cat(1, QAQCtest, T.(avarT)(:));
        end
    end
            
    ARTG.(av{nv}).EST = timeout;
    if isfield(T, avar)
        ARTG.(av{nv}).(avar).data = dataout;
        ARTG.(av{nv}).(avar).QAQC(:,1:5) =...
            [QAQCout1 QAQCout2 QAQCout3 QAQCout4 QAQCout5];
        ARTG.(av{nv}).(avar).QAQC(:,10) = QAQCtest;
    end
end

% QAQC will be implemented once the data is in ERDDAP.
%
% See https://cdn.ioos.noaa.gov/media/2020/07/QARTOD-Data-Flags-Manual_version1.2final.pdf
% Pass=1 Data have passed critical real-time quality control tests and are 
%        deemed adequate for use as preliminary data.
% Not evaluated=2 Data have not been QC-tested, or the information on 
%        quality is not available. 
% Suspect or Of High Interest=3. Data are considered to be either
%        suspect or of high interest to data providers and users. 
%        They are flagged suspect to draw further attention to them by operators.
% Fail=4 Data are considered to have failed one or more critical 
%        real-time QC checks. If they are disseminated at all, 
%        it should be readily apparent that they are not of 
%        acceptable quality.
% Missing data=9 Data are missing; used as a placehold
% 

% Tests
% A. Globally impossible value (exceeds low or high thresholds)
% B. Monthly climatology standard deviation test (exceeds warning or failure thresholds)
% C. Excessive spike check (exceeds warning or failure, low or high thresholds)
% D. Excessive offset/bias when compared to a reference data set (exceeds warning or 
%    failure, low or high thresholds)
% E. Unexpected X/Y ratio (e.g., chemical stoichiometry or property-property X to T, S, 
%     density, among others)
% F. Excessive spatial gradient or pattern check (“bullseyes”) 
% G. Below detection limit of method
% 

grid on; box on;
ylabel(avar);
title('ARTG-Near Bottom & Near Surface');

end