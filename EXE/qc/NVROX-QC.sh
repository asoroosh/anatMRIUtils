StudyID=CFTY720D2201

DataDir="/data/ms/processed/mri"

StudyID_Date=$(ls ${DataDir} | grep "${StudyID}.") #because the damn Study names has inconsistant dates in them!

QC_html_file=""

ProcessedPath="${DataDir}/${StudyID_Date}"
QC_Results=${DataDir}/QC/${StudyID}
mkdir -p ${QC_Results}

######################## RAW IMAGES ###########################################

TargetDir=${QC_Results}/Raw_T12D
mkdir -p ${TargetDir}
cd ${TargetDir}

T12D_Dir=/data/ms/unprocessed/mri/${StudyID_Date}/sub-*/ses-V*[0-9]/anat/sub-*_ses-V*[0-9]_run-1_T1w.nii.gz

slicesdir ${T12D_Dir}

QC_html_file="$QC_html_file $TargetDir/slicesdir/index.html"
echo ${QC_html_file}

######################### FSL #################################################
echo "+_+_+_+_+_+_+_+_+_+_+_+_+_ FSL +_+_+_+_+_+_+_+_+_+_+_+_+_+_"
echo ""
echo ""

DirSuffix=fslanat

for ImageName in T1_to_MNI_nonlin T1_to_MNI_lin
do
	echo "+_+_+_+_+_+_ ${DirSuffix} ${ImageName}"

	TargetDir=${QC_Results}/${DirSuffix}_${ImageName}
	mkdir -p ${TargetDir}
	cd ${TargetDir}

	T12D_Dir=${ProcessedPath}/sub-*/ses-V*[0-9]/anat/sub-*_ses-V*[0-9]_run-1_T1w.${DirSuffix}/sub-*_ses-V*[0-9]_run-1_T1w.anat/${ImageName}.nii.gz
#	T13D_Dir=${ProcessedPath}/sub-*/ses-V*[0-9]/anat/sub-*_ses-V*[0-9]_acq-3d_run-1_T1w.anat/${ImageName}.nii.gz

	slicesdir -p ${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz ${T12D_Dir}
#	slicesdir -p ${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz ${T13D_Dir}

	QC_html_file="$QC_html_file $TargetDir/slicesdir/index.html"
	echo ${QC_html_file}
done


#QC_html_file="$QC_html_file $TargetDir/slicesdir/index.html"
#echo ${QC_html_file}

echo "+_+_+_+_+_+_ ${DirSuffix} ${ImageName}"

ImageName=T1_biascorr_brain

TargetDir=${QC_Results}/${DirSuffix}_${ImageName}
mkdir -p ${TargetDir}
cd ${TargetDir}

T12D_Dir=${ProcessedPath}/sub-*/ses-V*[0-9]/anat/sub-*_ses-V*[0-9]_run-1_T1w.${DirSuffix}/\
	sub-*_ses-V*[0-9]_run-1_T1w.anat/${ImageName}.nii.gz
#T13D_Dir=${ProcessedPath}/sub-*/ses-V*[0-9]/anat/sub-*_ses-V*[0-9]_acq-3d_run-1_T1w.anat/T1_biascorr_brain.nii.gz

slicesdir ${T12D_Dir}
#slicesdir ${T13D_Dir}

QC_html_file="$QC_html_file $TargetDir/slicesdir/index.html"
echo ${QC_html_file}
######################### ANTs ##################################################
echo "+_+_+_+_+_+_+_+_+_+_+_+_+_ ANTs +_+_+_+_+_+_+_+_+_+_+_+_+_+_"
echo ""
echo ""

DirSuffix=ants
ImageName=BrainExtractionBrain_MNI_2mm

echo "+_+_+_+_+_+_ ${DirSuffix} ${ImageName}"

# Nonlinear Registration
TargetDir=${QC_Results}/${DirSuffix}_${ImageName}
mkdir -p ${TargetDir}
cd ${TargetDir}

T12D_Dir=${ProcessedPath}/sub-*/ses-V*[0-9]/anat/sub-*_ses-V*[0-9]_run-1_T1w.${DirSuffix}/MNI/${ImageName}.nii.gz
#T13D=${ProcessedPath}/${StudyID}/sub-*/ses-V*[0-9]/anat/sub-*_ses-V*[0-9]_acq-3d_run-1_T1w.ANTs/MNI/BrainExtractionBrain_MNI_2mm.nii.gz

slicesdir -p ${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz ${T12D_Dir}
#slicesdir -p ${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz ${T13D_Dir}

QC_html_file="$QC_html_file $TargetDir/slicesdir/index.html"
echo ${QC_html_file}
######################### CAT12 ##################################################
#DirSuffix=cat12


######################### FS #####################################################
echo "+_+_+_+_+_+_+_+_+_+_+_+_+_ FREESURFER +_+_+_+_+_+_+_+_+_+_+_+_+_+_"
echo ""
echo ""

DirSuffix=autorecon12
ImageName=norm_RAS

echo "+_+_+_+_+_+_ ${DirSuffix} ${ImageName}"

T12D_Dir=${ProcessedPath}/sub-*/ses-V*[0-9]/anat/sub-*_ses-V*[0-9]_run-1_T1w.${DirSuffix}/sub-*_ses-V*[0-9]_run-1_T1w/mri/nii/norm_RAS.nii.gz

TargetDir=${QC_Results}/${DirSuffix}_${ImageName}
mkdir -p ${TargetDir}
cd ${TargetDir}

slicesdir ${T12D_Dir}

QC_html_file="$QC_html_file $TargetDir/slicesdir/index.html"
echo ${QC_html_file}
runchrome="chromium-browser $QC_html_file"
echo $runchrome >> ${QC_Results}/runchrome.txt
