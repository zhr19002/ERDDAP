function d = GetCTDEEP_Nut_Data(Astn, deletion)
% 
% Get CTDEEP nutrient data for Astn from ERDDAP
% 
% Called from QAQC_Para_Nut.m
% Called from WriteNutDataQAQC.m
% 

wopts = weboptions; wopts.Timeout = 120;

% Form ERDDAP request
al = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_Nutrient.mat?' ...
      'cruise%2CLab_ID%2CStation_Name%2CDepth_Code%2CDetection_Limit%2CDilution_Factor%2CPQL%2C' ...
      'Parameter%2CResult%2Cnon_detect%2CUnits%2CComment%2CMonth%2Clatitude%2Clongitude%2C' ...
      'Time_ON_Station%2CTime_OFF_Station%2Ctime%2CStart_Date%2CEnd_Date%2C' ...
      'B_Sample_Depth%2CM_Sample_Depth%2CS_Sample_Depth%2CNB_Sample_Depth' ...
      '&Station_Name=%22XX%22'];
aurl = strrep(al, 'XX', Astn);

afile = ['CTDEEP_Nut_' Astn '.mat'];
if ~exist(afile, 'file')
    disp(['Getting data from ERDDAP at ' Astn]);
    try
        af = websave(afile, aurl, wopts);
        d = load(af);
        d = d.DEEP_Nutrient;
        % Convert char array to cell array
        for field = fieldnames(d)'
            if ischar(d.(field{1}))
                d.(field{1}) = cellstr(d.(field{1}));
            end
        end
        % Remove non-detect values
        iu = strcmp(d.non_detect, 'f');
        for field = fieldnames(d)'
            d.(field{1}) = d.(field{1})(iu);
        end
        d = rmfield(d, 'non_detect');
        % Save the updated .mat file
        DEEP_Nutrient = d;
        save(afile, 'DEEP_Nutrient');
        % Delete the generated .mat file
        if deletion == 1
            delete(afile);
        end
    catch
        disp(['No data at ' Astn]);
        d = {};
        % Delete the generated .mat file
        if deletion == 1
            delete(afile);
        end
    end
else
    if ~isempty(dir(afile)) & dir(afile).bytes>0
        d = load(afile);
        d = d.DEEP_Nutrient;
    else
        d = {};
    end
end

end