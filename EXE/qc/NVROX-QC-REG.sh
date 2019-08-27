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
echo "_+_+_+_+_+ BRAIN REGISTRATION "
DirSuffix=fslanat
ImageName_NONLIN=T1_to_MNI_nonlin
ImageName_LIN=T1_to_MNI_lin

TargetDir=${QC_Results}/${DirSuffix}_${ImageName_LIN}-${ImageName_NONLIN}
mkdir -p ${TargetDir}

# Linear paths
T12D_Dir_LIN=${ProcessedPath}/sub-*/ses-V*[0-9]/anat/sub-*_ses-V*[0-9]_run-1_T1w.${DirSuffix}/sub-*_ses-V*[0-9]_run-1_T1w.anat/${ImageName_LIN}.nii.gz
NUMIMG_LIN=$(ls $T12D_Dir_LIN | wc -l)

# Nonlinear paths
T12D_Dir_NONLIN=${ProcessedPath}/sub-*/ses-V*[0-9]/anat/sub-*_ses-V*[0-9]_run-1_T1w.${DirSuffix}/sub-*_ses-V*[0-9]_run-1_T1w.anat/${ImageName_NONLIN}.nii.gz
NUMIMG_LIN=$(ls $T12D_Dir_NONLIN | wc -l)

# Standard space -- MNI 2mm
STANDARDDIR=$FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz

sh ${SOURCE2PATH}/NVR-OX-slicer-overlay.sh "$T12D_Dir_LIN" "$STANDARDDIR" $TargetDir $NUMIMG
sh ${SOURCE2PATH}/NVR-OX-slicer-overlay.sh "$T12D_Dir_NONLIN" "$STANDARDDIR" $TargetDir $NUMIMG

mkdir -p $TargetDir/TRI

for imgnam in $TargetDir/COMB_*${ImageName_NONLIN}*
do
	imgnam_basename=$(basename $imgnam)
	SubIDVar=$(echo $imgnam_basename | awk -F"_" '{print $2}')
	SesIDVar=$(echo $imgnam_basename | awk -F"_" '{print $3}')
	$FSLDIR/bin/pngappend \
	${TargetDir}/COMB_${SubIDVar}_${SesIDVar}_${ImageName_LIN}_on_MNI152_T1_2mm_brain.png - ${TargetDir}/COMB_${SubIDVar}_${SesIDVar}_${ImageName_NONLIN}_on_MNI152_T1_2mm_brain.png \
	${TargetDir}/TRI/TRI_${SubIDVar}_${SesIDVar}_${ImageName_LIN}-${ImageName_NONLIN}.png
done

python3 ${SOURCE2PATH}/img_htm_mri_reg.py -i ${TargetDir}/TRI -o ${TargetDir}/TRI -sn ${StudyID}_${DirSuffix}_${ImageName_LIN}-${ImageName_NONLIN} -nc 1 -nf $NUMIMG_LIN

######################### ANTs ##################################################
echo "+_+_+_+_+_+_+_+_+_+_+_+_+_ ANTs +_+_+_+_+_+_+_+_+_+_+_+_+_+_"
echo ""
echo ""
echo "_+_+_+_+_+ BRAIN REGISTRATION "

DirSuffix=ants

ImageName_NONLIN=BrainExtractionBrain_MNI_2mm
ImageName_LIN=BrainExtractionBrain_MNI_2mm_affine

TargetDir=${QC_Results}/${DirSuffix}_${ImageName_LIN}-${ImageName_NONLIN}
mkdir -p ${TargetDir}

# Linear paths
T12D_Dir_LIN=${ProcessedPath}/sub-*/ses-V*[0-9]/anat/sub-*_ses-V*[0-9]_run-1_T1w.${DirSuffix}/MNI/${ImageName_LIN}.nii.gz
NUMIMG_LIN=$(ls $T12D_Dir_LIN | wc -l)

# Nonlinear paths
T12D_Dir_NONLIN=${ProcessedPath}/sub-*/ses-V*[0-9]/anat/sub-*_ses-V*[0-9]_run-1_T1w.${DirSuffix}/MNI/${ImageName_NONLIN}.nii.gz
NUMIMG_NONLIN=$(ls $T12D_Dir_NONLIN | wc -l)

# Standard space -- MNI 2mm
STANDARDDIR=$FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz

sh ${SOURCE2PATH}/NVR-OX-slicer-overlay.sh "$T12D_Dir_LIN" "$STANDARDDIR" $TargetDir $NUMIMG
sh ${SOURCE2PATH}/NVR-OX-slicer-overlay.sh "$T12D_Dir_NONLIN" "$STANDARDDIR" $TargetDir $NUMIMG

mkdir -p $TargetDir/TRI

for imgnam in $TargetDir/COMB_*${ImageName_NONLIN}*
do
	imgnam_basename=$(basename $imgnam)
	SubIDVar=$(echo $imgnam_basename | awk -F"_" '{print $2}')
	SesIDVar=$(echo $imgnam_basename | awk -F"_" '{print $3}')

	$FSLDIR/bin/pngappend \
	${TargetDir}/COMB_${SubIDVar}_${SesIDVar}_${ImageName_LIN}_on_MNI152_T1_2mm_brain.png - ${TargetDir}/COMB_${SubIDVar}_${SesIDVar}_${ImageName_NONLIN}_on_MNI152_T1_2mm_brain.png \
	${TargetDir}/TRI/TRI_${SubIDVar}_${SesIDVar}_${ImageName_LIN}-${ImageName_NONLIN}.png
done

python3 ${SOURCE2PATH}/img_htm_mri_reg.py -i ${TargetDir}/TRI -o ${TargetDir}/TRI -sn ${StudyID}_${DirSuffix}_${ImageName_LIN}-${ImageName_NONLIN} -nc 1 -nf $NUMIMG_LIN
