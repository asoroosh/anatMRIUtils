clear

addpath(genpath('/home/bdivdi.local/dfgtyk/NVROXBOX/AUX/matlab'))

StudyID='CFTY720D2201E2'; 
IDPs=['/data/output/habib/processed/' StudyID '/anat'];
%% FSL FIRST SEG

ImageType_List={'T12D','T13D'};

WhatROI=4;

IT_cnt = 1;
for IT = ImageType_List
    tab_tmp = NVROX_readIDPtables_FIRSTSEGVOL([IDPs '/IDP_' StudyID '_' IT{1} '_FIRSTSEGVOL.txt']);
    A{IT_cnt} = table2array(tab_tmp(:,3+WhatROI));
    
    IT_cnt = IT_cnt+1;
end
fh_firstseg = figure; 

