ml ANTs
ml FreeSurfer
ml Perl
source /apps/eb/software/FreeSurfer/6.0.1-centos6_x86_64/FreeSurferEnv.sh

source /home/bdivdi.local/dfgtyk/NVROXBOX/SOURCE/reg/XXX

set -e

do_reg=1

seglab=No
reglab=2SyN

#--------- SubID, StudyID, info from ANTs SST -----------------------------------------

StudyID=$1
SubID=$2

NonLinTempImgName=sub-${SubID}_ants_temp_med_nutemplate0

OrFlag=LIA

#--------------------------------------------------------------------------------------
echo "======================================="
echo "STARTED @" $(date)
echo "======================================="
echo ""
echo "======================================="
echo "======================================="
echo "** StudyID: ${StudyID}, SubID: ${SubID}"
echo "======================================="
echo "======================================="

SessionsFileName=${DataDir}/${StudyID}/T12D/Sessions/${StudyID}_sub-${SubID}_T12D.txt
while read SessionPathsFiles
do
	ses_SesID_tmp=$(echo $SessionPathsFiles | awk -F"/" '{print $8}')
	SesID_tmp=$(echo $ses_SesID_tmp | awk -F"-" '{print $2}');
	SesIDList="${SesIDList} $SesID_tmp"
	echo ${SesIDList}
done<${SessionsFileName}

SesIDList=(${SesIDList})
NumSes=${#SesIDList[@]}
#--------------------------------------------------------------------------------------
ImgTyp=T12D
XSectionalDirSuffix=autorecon12ws
LogitudinalDirSuffix=nuws_mrirobusttemplate
# ------

#------------= Main paths
#PRSD_DIR="/data/ms/processed/mri"
PRSD_SUBDIR=${PRSD_DIR}/${StudyID}/sub-${SubID}

#-------------= X Sectional paths
SST_Dir=${PRSD_SUBDIR}/${ImgTyp}.${XSectionalDirSuffix}.${LogitudinalDirSuffix}

#--------------= Unprocessed paths
#UPRSD_DIR="/data/ms/unprocessed/mri"
UnprocessedDir=${UPRSD_DIR}/${StudyID}

#--------------= Path to SST templates
# Nonlinear Template
NonLinSSTDirImg=${SST_Dir}/${NonLinTempImgName}
# Linear Template
LinSST=${SST_Dir}/sub-${SubID}_norm_nu_median.nii.gz # this should be moved

# -------- Application initialisations ------------------------------------------------
VoxRes=2
MaskThr=0.5

MNITMP_DIR=${HOME}/NVROXBOX/AUX/MNItemplates/${OrFlag}
MNIImg_FS=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_${OrFlag}
MaskInMNI_FS=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_brain_mask_${OrFlag}

echo "*************************************************************"
echo "=== BRING THE MNI TEMPLATE & MASK INTO ${OrFlag} ORIENTATION:"
echo "MNI ${OrFlag}: ${MNIImg_FS}"
echo "BrainMask ${OrFlag}: ${MaskInMNI_FS}"
echo "*************************************************************"

# ------- Path inistialisations --------------------------------------------------------

#register to MNI
antsRegOutputPrefix=${NonLinSSTDirImg}_MNI-${VoxRes}mm-BE${seglab}-REG${reglab}-
NonLinSST_MNI=${antsRegOutputPrefix}Warped
NonLinSST_MNI_InvWarp=${antsRegOutputPrefix}1InverseWarp
NonLinSST_MNI_Affine=${antsRegOutputPrefix}0GenericAffine.mat
REG_LOG=${NonLinSSTDirImg}_MNI.log


if [ $do_reg == 1 ] || [ $do_reg == 10 ]; then
#	rm -f ${NonLinSST_MNI_InvWarp} ${NonLinSST_MNI_Affine} ${NonLinSST_MNI}
		echo "TEST"
	else
		echo "############# No Registration will be done..."
fi

# ------- Do the job ---------------------------------------------------------------------

## PAD THE IMAGE!

echo "PAD THE IMAGE"
NonLinSSTDirImg_pad=${NonLinSSTDirImg}_pad10
ImageMath 3 ${NonLinSSTDirImg_pad}.nii.gz PadImage ${NonLinSSTDirImg}.nii.gz 10

echo "PADDING DONE - CHECK: ${NonLinSSTDirImg_pad}.nii.gz"

## REGISTRATION ######

# prepare a mask for ANTs
NonLinSSTDirImg_pad_mask=${NonLinSSTDirImg}_mask
${FSLDIR}/bin/fslmaths ${NonLinSSTDirImg_pad}.nii.gz -bin ${NonLinSSTDirImg_pad_mask}.nii.gz
# delineate the mask
#${FSLDIR}/bin/fslmaths ${NonLinSSTDirImg_pad_mask}.nii.gz -dilM ${NonLinSSTDirImg_pad_mask}.nii.gz

echo "Mask: ${NonLinSSTDirImg_pad_mask}.nii.gz"

echo "*************************************************************"
echo "REGISTER NONLINEAR SST > MNI ${OrFlag}"
echo "MOVING: ${NonLinSSTDirImg_pad}.nii.gz"
echo "FIXED: ${MNIImg_FS}.nii.gz"
echo "*************************************************************"

if [ $do_reg == 1 ]; then

#-------------------------------
ShrnkFctrs="2x2x1x1"
SmthFctrs="3x2x1x0vox"
ItrNum="1000x500x250x0"
#-------------------------------
#ShrnkFctrs="1x1x1x1"
#SmthFctrs="3x2x1x0vox"
#ItrNum="1000x500x250x0"

	echo " " > ${REG_LOG}

fslmaths ${MNIImg_FS}.nii.gz -fillh -bin ${MNIImg_FS}_mask.nii.gz

antsRegistration \
--verbose 1 \
--dimensionality 3 \
--float 0 \
--collapse-output-transforms 1 \
--interpolation Linear \
--use-histogram-matching 1 \
--winsorize-image-intensities [0.005,0.995] \
--initial-moving-transform [${MNIImg_FS}.nii.gz,${NonLinSSTDirImg_pad}.nii.gz,1] \
--transform Rigid[0.1] \
--metric CC[${MNIImg_FS}.nii.gz,${NonLinSSTDirImg_pad}.nii.gz,1,10] \
--convergence [1000x500x250x100,1e-6,10] \
--shrink-factors 12x8x4x2 \
--smoothing-sigmas ${SmthFctrs} \
-x [NULL,NULL] \
--transform Affine[0.1] \
--metric CC[${MNIImg_FS}.nii.gz,${NonLinSSTDirImg_pad}.nii.gz,1,10] \
--convergence [1000x500x250x100,1e-6,10] \
--shrink-factors 12x8x4x2 \
--smoothing-sigmas ${SmthFctrs} \
-x [NULL,NULL] \
--transform SyN[0.1,3,0] \
--metric CC[${MNIImg_FS}.nii.gz,${NonLinSSTDirImg_pad}.nii.gz,1,10] \
--convergence [100x100x70x50x20,1e-6,10] \
--shrink-factors 10x6x4x2x1 \
--smoothing-sigmas 6x4x2x1x0vox \
-x [${MNIImg_FS}_mask.nii.gz,${NonLinSSTDirImg_pad_mask}.nii.gz] \
--transform SyN[0.1,3,1] \
--metric CC[${MNIImg_FS}.nii.gz,${NonLinSSTDirImg_pad}.nii.gz,1,10] \
--convergence [100x100x70x50x20,1e-6,10] \
--shrink-factors 10x6x4x2x1 \
--smoothing-sigmas 6x4x2x1x0vox \
-x [${MNIImg_FS}_mask.nii.gz,${NonLinSSTDirImg_pad_mask}.nii.gz] \
--output [${antsRegOutputPrefix}SYN1,${antsRegOutputPrefix}SYN1.nii.gz]

#--metric MI[${MNIImg_FS}.nii.gz,${NonLinSSTDirImg_pad}.nii.gz,1,32,Regular,0.25]
#-x [${MNIImg_FS}_mask.nii.gz,${NonLinSSTDirImg_pad_mask}.nii.gz]

fi

	echo "*************************************************************"
	echo "********** Registration is DONE! ****************************"
	echo "*************************************************************"

echo "==================================="
echo "DONE-DONE-DONE-DONE-DONE-DONE-DONE"
echo "STARTED @" $(date)
echo "==================================="

echo "CHECK: ${antsRegOutputPrefix}Warped.nii.gz"
