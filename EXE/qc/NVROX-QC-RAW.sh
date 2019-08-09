StudyID=CFTY720D2309E1
DataDir="/data/ms/processed/mri"
StudyID_Date=$(ls ${DataDir} | grep "${StudyID}.") #because the damn Study names has inconsistant dates in them!
echo ${StudyID_Date}
QC_Results=${DataDir}/QC/${StudyID}
mkdir -p ${QC_Results}

#echo "+_+_+_+_+_+_+_+_+_+_+_+_+_ RAW +_+_+_+_+_+_+_+_+_+_+_+_+_+_" 
#echo ""
#echo ""
TargetDir=${QC_Results}/Raw_T12D
rm -fr ${TargetDir}
mkdir -p ${TargetDir}
cd ${TargetDir}

T12D_Dir=/data/ms/unprocessed/mri/${StudyID_Date}/sub-*.{01*,02*,03*,04*,051*,052*,053*,054*}.*/ses-V*[0-9]/anat/sub-*ses-V*[0-9]_run-1_T1w.nii.gz

ls $T12D_Dir | wc -l 

echo "${T12D_Dir}"
slicesdir ${T12D_Dir}

QC_html_file=" $TargetDir/slicesdir/index.html"
echo ${QC_html_file}
runchrome="chromium-browser $QC_html_file"
echo $runchrome >> ${QC_Results}/raw_runchrome.txt
