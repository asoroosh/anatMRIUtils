clear
addpath(genpath('/home/bdivdi.local/dfgtyk/NVROXBOX/AUX/matlab'))

HOME='/home/bdivdi.local/dfgtyk';
StudyIDList=readtable([HOME '/NVROXBOX/EXE/getinfo/StudyIDs_Clean.txt'],'ReadVariableNames',false);
StudyIDList=StudyIDList.Var1;

DirSuffixList={'fslanat','ants'};
FileNameList={'T1_to_MNI_lin-T1_to_MNI_nonlin','BrainExtractionBrain_MNI_2mm_affine-BrainExtractionBrain_MNI_2mm'};

StatList={'PASSED','TENTATIVE', 'LINFAILED', 'LINCHECK', 'NONLINFAILED', 'NONLINCHECK'};
stid=1;
for StudyID=StudyIDList'
    disp(['StudyID:' StudyID{1}])
    for cnt=1:2

        tmp_tbl = readtable(['/data/ms/processed/mri/QC/' StudyID{1} '/' DirSuffixList{cnt} '_' FileNameList{cnt} '/' StudyID{1} '_' DirSuffixList{cnt} '_' FileNameList{cnt} '_Summary.txt']);

        Stat_tmp = tmp_tbl.Var2;
        Stat(:,cnt,stid) = [Stat_tmp(1),Stat_tmp(2),Stat_tmp(3)+Stat_tmp(4),Stat_tmp(5)+Stat_tmp(6)]/Stat_tmp(end)*100;
    end
    stid=stid+1;
end

sf_titles={'Excellent','Average','Failed on Linear Reg','Failed on Non-Linear Reg'};
fh = figure('position',[50,500,1500,450]); 
for i = 1:numel(sf_titles)
    sh = subplot(1,numel(sf_titles),i);
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
export_fig(fh,['Reports/QCReport_BrainReg.pdf'])
