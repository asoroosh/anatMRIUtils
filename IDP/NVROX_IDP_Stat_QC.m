clear

addpath(genpath('/home/bdivdi.local/dfgtyk/NVROXBOX/AUX/matlab'))

ImageType_List={'T12D','T13D'};

StudyID='CFTY720D2201E2'; 
IDPs_Dir=['/data/output/habib/processed/' StudyID '/anat'];
IDPs_Results_Dir=['/home/bdivdi.local/dfgtyk/NVROXBOX/IDP'];

%% FSL FIRST SEG

for WhatROI=1:15
    IT_cnt = 1;
    for IT = ImageType_List
        SI = NVROX_readIDPtables_FIRSTSEGVOL([IDPs_Dir '/IDP_' StudyID '_' IT{1} '_FIRSTSEGVOL.txt']);
        FIRSTSEG_Stat{IT_cnt} = table2array(SI(:,3+WhatROI));

        IT_cnt = IT_cnt+1;
    end
    fh_firstseg = figure; 
    hold on; title(['FSL FIRST SUBCORTICAL SEG VOLUMES -- ROI ' num2str(WhatROI)])
    ScatterBoxPlots(FIRSTSEG_Stat,'unequal','figure',fh_firstseg,'Line')
    fh_firstseg.Children.XTick=1:1:numel(ImageType_List);
    fh_firstseg.Children.XTickLabel=ImageType_List;
    ylabel('Volume')
    xlabel('Image Type')
    set(fh_firstseg,'color','w')
    export_fig(fh_firstseg,[IDPs_Results_Dir '/RFigs/FSLFIRST_SEG_SUBCORT_VOLS_' num2str(WhatROI) '.png'])
    
    
    fh_firstseg_scat=figure; 
    hold on; title(['FSL FIRST SUBCORTICAL SEG VOLUMES -- ROI ' num2str(WhatROI)])
    scatter(FIRSTSEG_Stat{1},FIRSTSEG_Stat{2},'Marker','o','MarkerFaceColor','k','MarkerEdgeColor','k')
    xlabel(ImageType_List{1});
    ylabel(ImageType_List{2});
    
    export_fig(fh_firstseg_scat,[IDPs_Results_Dir '/RFigs/FSLFIRST_SEG_SUBCORT_VOLS_' num2str(WhatROI) '_SCAT.png'])

    pause(2)
    
    close all
    
    clear FIRSTSEG_Stat
    
end

close all

%% SIENAX

TissueType_List={'BRN','WM','GM'};

for TT = 1:numel(TissueType_List)
    
    IT_cnt = 1;
    for IT = ImageType_List
        SI = NVROX_readIDPtables_SIENAX([IDPs_Dir '/IDP_' StudyID '_' IT{1} '_SIENAX_' TissueType_List{TT} '.txt']);
        SIENAX_Stat{IT_cnt} = table2array(SI(:,3+2)); %normalised by the brain volume

        IT_cnt = IT_cnt+1;
    end
    
    fh_sienax = figure; 
    hold on; title(['FSL SIENAX -- TIUSSE: ' TissueType_List{TT}])
    ScatterBoxPlots(SIENAX_Stat,'unequal','figure',fh_sienax,'Line')
    fh_sienax.Children.XTick=1:1:numel(ImageType_List);
    fh_sienax.Children.XTickLabel=ImageType_List;
    ylabel('Volume')
    xlabel('Image Type')
    set(fh_sienax,'color','w')
    export_fig(fh_sienax,[IDPs_Results_Dir '/RFigs/FSLSIENAX_VOLS_' TissueType_List{TT} '.png'])
    
    fh_sienax_scat = figure;
    hold on; box on; grid on; 
    title(['FSL SIENAX -- TIUSSE: ' TissueType_List{TT}])
    scatter(SIENAX_Stat{1},SIENAX_Stat{2},'Marker','o','MarkerFaceColor','k','MarkerEdgeColor','k')
    xlabel(ImageType_List{1});
    ylabel(ImageType_List{2});
    export_fig(fh_sienax_scat,[IDPs_Results_Dir '/RFigs/FSLSIENAX_VOLS_' TissueType_List{TT} '_SCAT.png'])

    clear SIENAX_Stat
    
end

close all

%% SIENA - Final PVBC 

SIENA_FINALPBVC_T13D = NVROX_readIDPtables_SIENA([IDPs_Dir '/IDP_' StudyID '_' ImageType_List{2} '_SIENA_FINALPBVC.txt']);
SIENA_FINALPBVC_T13D = table2array(SIENA_FINALPBVC_T13D(:,end));

SIENA_FINALPBVC_T12D = NVROX_readIDPtables_SIENA([IDPs_Dir '/IDP_' StudyID '_' ImageType_List{1} '_SIENA_FINALPBVC.txt']);
SIENA_FINALPBVC_T12D = table2array(SIENA_FINALPBVC_T12D(:,end)); 

fh_siena = figure; 
hold on; title(['FSL SIENA -- PBVC'])
ScatterBoxPlots({SIENA_FINALPBVC_T12D,SIENA_FINALPBVC_T13D},'unequal','figure',fh_siena,'Line')
fh_siena.Children.XTick=1:1:numel(ImageType_List);
fh_siena.Children.XTickLabel=ImageType_List;
ylabel('Percentage Brain Vol Change (%)')
xlabel('Image Type')
set(fh_siena,'color','w')
export_fig(fh_siena,[IDPs_Results_Dir '/RFigs/FSLSIENA_FinalPBVC.png'])

fh_siena_scat = figure; 
hold on; title(['FSL SIENA -- PBVC'])
scatter(SIENA_FINALPBVC_T12D,SIENA_FINALPBVC_T13D,'Marker','o','MarkerFaceColor','k','MarkerEdgeColor','k')
xlabel(ImageType_List{1});
ylabel(ImageType_List{2});
set(fh_siena_scat,'color','w')
export_fig(fh_siena_scat,[IDPs_Results_Dir '/RFigs/FSLSIENA_FinalPBVC_SCAT.png'])

close all

    








