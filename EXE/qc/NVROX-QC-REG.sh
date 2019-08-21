StudyID=$1
#CFTY720D2301
#=============== FUNCTIONS================

PROGNAME=$(basename $0)
error_exit()
{
	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
        exit 1
}

#=========================================

SOURCE2PATH=${HOME}/NVROXBOX/SOURCE

ml Python

if [ -z $StudyID ]; then
	error_exit "***** ERROR $LINENO: StudyID should be set!"
fi

DataDir="/data/ms/processed/mri"

StudyID_Date=$(ls ${DataDir} | grep "${StudyID}.anon") #because the damn Study names has inconsistant dates in them!

echo ${StudyID_Date}

QC_html_file=""

ProcessedPath="${DataDir}/${StudyID_Date}"
QC_Results=${DataDir}/QC/${StudyID}
mkdir -p ${QC_Results}

######################### FSL #################################################
echo "+_+_+_+_+_+_+_+_+_+_+_+_+_ FSL +_+_+_+_+_+_+_+_+_+_+_+_+_+_"
echo ""
echo ""

DirSuffix=fslanat

### Registration
echo "_+_+_+_+_+ REGISTRATION "

MNISTANDARD=$FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz

for ImageName in T1_to_MNI_nonlin T1_to_MNI_lin
do
	echo "+_+_+_+_+_+_ ${DirSuffix} ${ImageName}"
	TargetDir=${QC_Results}/${DirSuffix}_${ImageName}
	mkdir -p ${TargetDir}

	T12D_Dir=${ProcessedPath}/sub-*/ses-V*[0-9]/anat/sub-*_ses-V*[0-9]_run-1_T1w.${DirSuffix}/sub-*_ses-V*[0-9]_run-1_T1w.anat/${ImageName}.nii.gz

	NUMIMG=$(ls $T12D_Dir | wc -l)
#	NUMIMG=5
	sh ${SOURCE2PATH}/NVR-OX-slicer-overlay.sh "$T12D_Dir" $MNISTANDARD $TargetDir $NUMIMG
	python3 ${SOURCE2PATH}/img_htm_mri.py -i ${TargetDir} -o ${TargetDir} -sn ${StudyID}_${DirSuffix}_${ImageName} -nc 1 -nf $NUMIMG
done


######################### ANTs ##################################################
echo "+_+_+_+_+_+_+_+_+_+_+_+_+_ ANTs +_+_+_+_+_+_+_+_+_+_+_+_+_+_"
echo ""
echo ""

DirSuffix=ants

## Registration --------------------------------------------
ImageName=BrainExtractionBrain_MNI_2mm
# Nonlinear Registration
TargetDir=${QC_Results}/${DirSuffix}_${ImageName}
mkdir -p ${TargetDir}
#cd ${TargetDir}
T12D_Dir=${ProcessedPath}/sub-*/ses-V*[0-9]/anat/sub-*_ses-V*[0-9]_run-1_T1w.${DirSuffix}/MNI/${ImageName}.nii.gz
NUMIMG=$(ls $T12D_Dir | wc -l)
#NUMIMG=5

sh ${SOURCE2PATH}/NVR-OX-slicer-overlay.sh "$T12D_Dir" $MNISTANDARD $TargetDir $NUMIMG
python3 ${SOURCE2PATH}/img_htm_mri.py -i ${TargetDir} -o ${TargetDir} -sn ${StudyID}_${DirSuffix}_${ImageName} -nc 1 -nf $NUMIMG

######################### CAT12 ##################################################
#DirSuffix=cat12

######################### FS #####################################################
#echo "+_+_+_+_+_+_+_+_+_+_+_+_+_ FREESURFER +_+_+_+_+_+_+_+_+_+_+_+_+_+_"
#echo ""
#echo ""

#DirSuffix=autorecon12
#ImageName=norm_RAS
#echo "+_+_+_+_+_+_ ${DirSuffix} ${ImageName}"
#T12D_Dir=${ProcessedPath}/sub-*/ses-V*[0-9]/anat/sub-*_ses-V*[0-9]_run-1_T1w.${DirSuffix}/sub-*_ses-V*[0-9]_run-1_T1w/mri/nii/norm_RAS.nii.gz
#TargetDir=${QC_Results}/${DirSuffix}_${ImageName}
#mkdir -p ${TargetDir}
#cd ${TargetDir}
#slicesdir ${T12D_Dir}
#QC_html_file="$QC_html_file $TargetDir/slicesdir/index.html"
#echo ${QC_html_file}
#slicesdir2imghtm ${TargetDir} ${StudyID}_${DirSuffix}_${ImageName}
# I don't think if we ever going to use slicesdir directly to get the images out 
# but it is stil
