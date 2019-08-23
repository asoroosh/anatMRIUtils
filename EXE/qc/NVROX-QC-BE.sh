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
echo "_+_+_+_+_+ BRAIN EXTRACTION "
DirSuffix=fslanat
ImageName=T1_biascorr_brain
AUXImageName=T1_biascorr

TargetDir=${QC_Results}/${DirSuffix}_${ImageName}
mkdir -p ${TargetDir}
T12D_Dir=${ProcessedPath}/sub-*/ses-V*[0-9]/anat/sub-*_ses-V*[0-9]_run-1_T1w.${DirSuffix}/sub-*_ses-V*[0-9]_run-1_T1w.anat/${AUXImageName}.nii.gz
NUMIMG=$(ls $T12D_Dir | wc -l)

STANDARDDIR=${ProcessedPath}/sub-*/ses-V*[0-9]/anat/sub-*_ses-V*[0-9]_run-1_T1w.${DirSuffix}/sub-*_ses-V*[0-9]_run-1_T1w.anat/${ImageName}.nii.gz

sh ${SOURCE2PATH}/NVR-OX-slicer.sh "$T12D_Dir" $TargetDir $NUMIMG
sh ${SOURCE2PATH}/NVR-OX-slicer-overlay.sh "$T12D_Dir" "$STANDARDDIR" $TargetDir $NUMIMG
sh ${SOURCE2PATH}/NVR-OX-slicer.sh "$STANDARDDIR" $TargetDir $NUMIMG

mkdir -p $TargetDir/TRI
for imgnam in $TargetDir/COMB_*
do
	imgnam_basename=$(basename $imgnam)
	SubIDVar=$(echo $imgnam_basename | awk -F"_" '{print $2}')
	SesIDVar=$(echo $imgnam_basename | awk -F"_" '{print $3}')
	$FSLDIR/bin/pngappend \
	${TargetDir}/COMB_${SubIDVar}_${SesIDVar}_${AUXImageName}_on_${ImageName}.png - ${TargetDir}/IMG_${SubIDVar}_${SesIDVar}_${ImageName}.png \
	${TargetDir}/TRI/TRI_${SubIDVar}_${SesIDVar}_${ImageName}.png

done

python3 ${SOURCE2PATH}/img_htm_mri.py -i ${TargetDir}/TRI -o ${TargetDir}/TRI -sn ${StudyID}_${DirSuffix}_${ImageName} -nc 1 -nf $NUMIMG

######################### ANTs ##################################################
echo "+_+_+_+_+_+_+_+_+_+_+_+_+_ ANTs +_+_+_+_+_+_+_+_+_+_+_+_+_+_"
echo ""
echo ""

DirSuffix=ants

### Brain extraction ---------------------------------------
ImageName=BrainExtractionBrain
AUXImageName=T1_orig
TargetDir=${QC_Results}/${DirSuffix}_${ImageName}
mkdir -p ${TargetDir}
STANDARDDIR=${ProcessedPath}/sub-*/ses-V*[0-9]/anat/sub-*_ses-V*[0-9]_run-1_T1w.${DirSuffix}/antsCorticalThickness/${ImageName}.nii.gz
T12D_Dir=${ProcessedPath}/sub-*/ses-V*[0-9]/anat/sub-*_ses-V*[0-9]_run-1_T1w.fslanat/sub-*_ses-V*[0-9]_run-1_T1w.anat/${AUXImageName}.nii.gz
NUMIMG=$(ls $STANDARDDIR | wc -l)

sh ${SOURCE2PATH}/NVR-OX-slicer.sh "$T12D_Dir" $TargetDir $NUMIMG
sh ${SOURCE2PATH}/NVR-OX-slicer-overlay.sh "$T12D_Dir" "$STANDARDDIR" $TargetDir $NUMIMG
sh ${SOURCE2PATH}/NVR-OX-slicer.sh "$STANDARDDIR" $TargetDir $NUMIMG

mkdir -p $TargetDir/TRI
for imgnam in $TargetDir/COMB_*
do
	imgnam_basename=$(basename $imgnam)
	SubIDVar=$(echo $imgnam_basename | awk -F"_" '{print $2}')
	SesIDVar=$(echo $imgnam_basename | awk -F"_" '{print $3}')
	$FSLDIR/bin/pngappend ${TargetDir}/IMG_${SubIDVar}_${SesIDVar}_${AUXImageName}.png - ${TargetDir}/COMB_${SubIDVar}_${SesIDVar}_${AUXImageName}_on_${ImageName}.png - ${TargetDir}/IMG_${SubIDVar}_${SesIDVar}_${ImageName}.png \
	${TargetDir}/TRI/TRI_${SubIDVar}_${SesIDVar}_${ImageName}.png
done

python3 ${SOURCE2PATH}/img_htm_mri.py -i ${TargetDir}/TRI -o ${TargetDir}/TRI -sn ${StudyID}_${DirSuffix}_${ImageName} -nc 1 -nf $NUMIMG

######################### CAT12 ##################################################
#DirSuffix=cat12

######################### FS #####################################################
#echo "+_+_+_+_+_+_+_+_+_+_+_+_+_ FREESURFER +_+_+_+_+_+_+_+_+_+_+_+_+_+_"
#echo ""
#echo ""
#DirSuffix=autorecon12
#ImageName=norm_RAS
#echo "+_+_+_+_+_+_ ${DirSuffix} ${ImageName}"
