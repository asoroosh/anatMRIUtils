clear
addpath(genpath('/home/bdivdi.local/dfgtyk/NVROXBOX/AUX/matlab'))

HOME='/home/bdivdi.local/dfgtyk';
StudyIDList=readtable([HOME '/NVROXBOX/EXE/getinfo/StudyIDs_Clean.txt'],'ReadVariableNames',false);
StudyIDList=StudyIDList.Var1;

DirSuffixList={'ants','fslanat','autorecon12'};
FileNameList={'BrainExtractionBrain','T1_biascorr_brain','norm_RAS'};

stid=1;
for StudyID=StudyIDList'
    disp(['ID:' StudyID{1}])
    for cnt=1:3
        tmp_tbl = readtable(['/data/ms/processed/mri/QC/' StudyID{1} '/' DirSuffixList{cnt} '_' FileNameList{cnt} '/' StudyID{1} '_' DirSuffixList{cnt} '_' FileNameList{cnt} '_Summary.txt']);
        Stat_tmp = tmp_tbl.Var2;
        Stat(:,cnt,stid) = [Stat_tmp(1),Stat_tmp(2),Stat_tmp(3)]/Stat_tmp(end)*100;
    end
    stid=stid+1;
end

sf_titles={'Excellent','Average','Failed'};
fh = figure('position',[50,500,1200,450]); 
for i = 1:3
    sh = subplot(1,3,i);
    hold on; 
    title(sf_titles{i})
    bh = bar(squeeze(Stat(i,:,:))');
    
    sh.XTick=1:numel(StudyIDList);
    sh.XTickLabel=StudyIDList;
    sh.XTickLabelRotation=45;
    
    legend(DirSuffixList)
    ylabel('%')
    xlabel('Clinical Trial')
end

set(fh,'color','w')
export_fig(fh,['Reports/QCReport_BrainExtraction.pdf'])