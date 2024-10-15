function d = GetCTDEEP_Nut_Data(Astn, deletion)
% 
% Get CTDEEP nutrient data for Astn from ERDDAP
% 
% Called from WriteNutDataQAQC.m
% Called from QAQC_Para_Nut.m
% 

wopts = weboptions; wopts.Timeout = 120;

% Form ERDDAP request
al = ['http://merlin.dms.uconn.edu:8080/erddap/tabledap/DEEP_Nutrient.mat?' ...
      'Station_Name%2CDepth_Code%2CParameter%2CResult%2Clatitude%2Clongitude' ...
      '%2Ctime%2CB_Sample_Depth%2CS_Sample_Depth&Station_Name=%22XX%22'];
aurl = strrep(al, 'XX', Astn);

afile = ['CTDEEP_Nut_' Astn '.mat'];
if ~exist(afile, 'file')
    disp(['Getting data from ERDDAP at ' Astn]);
    try
        af = websave(afile, aurl, wopts);
        d = load(af);
        d = d.DEEP_Nutrient;
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