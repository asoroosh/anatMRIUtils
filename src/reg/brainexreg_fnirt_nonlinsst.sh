#!/bin/bash

#source ${HOME}/NVROXBOX/SOURCE/reg/setpathinanalytics
source ${HOME}/NVROXBOX/EXE/proc50/nvr-ox-path-setup

echo "Paths imported:"
echo "processed: $PRSD_DIR"
echo "unprocessed: $UPRSD_DIR"
echo "home: $MyHOME"
echo "datadir: $DataDir"
echo "==================="

set -e

do_reg=1

#--------- SubID, StudyID, info from ANTs SST -----------------------------------------

StudyID=$1
SubID=$2

NonLinTempImgName=sub-${SubID}_ants_temp_med_nutemplate0

OrFlag=LIA
BETREGOP="BETFNIRT"

CONFGFILE=${MyHOME}/NVROXBOX/AUX/NVROX-FNIRTCONFIG-T12MNI.cnf

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

cat $SessionsFileName

AA=$(echo "${UnprocessedPath}" | awk -F"/" '{print NF-1}'); AA=$((AA+1))
while read SessionPathsFiles
do
	ses_SesID_tmp=$(echo $SessionPathsFiles | awk -F"/" -v xx=$((AA+3)) '{print $xx}')
	SesID_tmp=$(echo $ses_SesID_tmp | awk -F"-" '{print $2}');
	SesIDList="${SesIDList} $SesID_tmp"
	echo ${SesIDList}
done<${SessionsFileName}

SesIDList=(${SesIDList})
NumSes=${#SesIDList[@]}
echo "NUMBER OF SESSIONS: ${NumSes}"

#--------------------------------------------------------------------------------------
ImgTyp=T12D
XSectionalDirSuffix=autorecon12ws
LogitudinalDirSuffix=nuws_mrirobusttemplate
# ------

PRSD_SUBDIR=${PRSD_DIR}/${StudyID}/sub-${SubID}

#-------------= X Sectional paths
SST_Dir=${PRSD_SUBDIR}/${ImgTyp}.${XSectionalDirSuffix}.${LogitudinalDirSuffix}

#--------------= Unprocessed paths
#UPRSD_DIR="/well/My-mri-temp/data/ms/unprocessed"
UnprocessedDir=${UPRSD_DIR}/${StudyID}

#--------------= Path to SST templates
# Nonlinear Template
NonLinSSTDirImg=${SST_Dir}/${NonLinTempImgName}
# Linear Template
LinSST=${SST_Dir}/sub-${SubID}_norm_nu_median.nii.gz # this should be moved

# -------- Application initialisations ------------------------------------------------
VoxRes=2
MaskThr=0.5

#MyHOME=/well/My-mri-temp/users/scf915
MNITMP_DIR=${MyHOME}/NVROXBOX/AUX/MNItemplates/${OrFlag}
MNIImg_FS=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_${OrFlag}

MaskInMNI_FS=${SST_Dir}/MNI152_T1_${VoxRes}mm_brain_mask_${OrFlag}
cp ${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_brain_mask_${OrFlag}.nii.gz ${MaskInMNI_FS}.nii.gz

echo "*************************************************************"
echo "=== BRING THE MNI TEMPLATE & MASK INTO ${OrFlag} ORIENTATION:"
echo "MNI ${OrFlag}: ${MNIImg_FS}"
echo "*************************************************************"

# ------- Path inistialisations --------------------------------------------------------

if [ $do_reg == 1 ] || [ $do_reg == 10 ]; then
		echo "TEST"
	else
		echo "############# No Registration will be done..."
fi

# ------- Do the job ---------------------------------------------------------------------

## REGISTRATION ######

echo "*************************************************************"
echo "REGISTER NONLINEAR SST > MNI ${OrFlag}"
echo "MOVING: ${NonLinSSTDirImg}.nii.gz"
echo "FIXED: ${MNIImg_FS}.nii.gz"
echo "*************************************************************"


refmask=${SST_Dir}/MNI152_T1_2mm_brain_mask_dil1

mkdir -p ${SST_Dir}/${BETREGOP}

$FSLDIR/bin/fslmaths $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask.nii.gz -fillh -dilF $refmask
mri_convert --in_orientation LAS --out_orientation ${OrFlag} ${refmask}.nii.gz ${refmask}.nii.gz > /dev/null 2>&1

#echo "============================================================="

FSLRegOutputPrefix=${SST_Dir}/${NonLinTempImgName}_MNI-FNIRT-${VoxRes}mm-
NonLinSST_MNI=${FSLRegOutputPrefix}warped
NonLinSST_MNI_InvWarp=${FSLRegOutputPrefix}invwarp
NonLinSST_MNI_Affine=${FSLRegOutputPrefix}affine.mat


if [ $do_reg == 1 ]; then

	## REGISTRATION ######

	$FSLDIR/bin/flirt -interp spline \
	-dof 12 \
	-in ${NonLinSSTDirImg}.nii.gz \
	-ref ${MNIImg_FS}.nii.gz \
	-omat ${FSLRegOutputPrefix}affine.mat \
	-out ${FSLRegOutputPrefix}Lin.nii.gz

	$FSLDIR/bin/fnirt \
	--in=${NonLinSSTDirImg}.nii.gz \
	--ref=${MNIImg_FS}.nii.gz \
	--fout=${FSLRegOutputPrefix}warp.nii.gz \
	--jout=${FSLRegOutputPrefix}jac.nii.gz \
	--iout=${FSLRegOutputPrefix}warped.nii.gz \
	--logout=${FSLRegOutputPrefix}log.txt \
	--cout=${FSLRegOutputPrefix}coeff.nii.gz \
	--aff=${FSLRegOutputPrefix}affine.mat \
	--config=${CONFGFILE}

	######################

	# extract the brain of nonlinear template in MNI
	${FSLDIR}/bin/fslmaths ${FSLRegOutputPrefix}warped.nii.gz -mas $refmask ${FSLRegOutputPrefix}warped_brain.nii.gz # brain in MNI space

	$FSLDIR/bin/invwarp --ref=${NonLinSSTDirImg}.nii.gz \
	-w ${FSLRegOutputPrefix}coeff.nii.gz \
	-o ${FSLRegOutputPrefix}invwarp.nii.gz

else
	echo "############# No Registration will be done..."

fi


NonLinSST_BrainMask=${SST_Dir}/sub-${SubID}_NonLinearSST_BrainMask
$FSLDIR/bin/applywarp \
--interp=nn \
--in=$refmask \
--ref=${NonLinSSTDirImg}.nii.gz \
-w ${FSLRegOutputPrefix}invwarp.nii.gz \
-o ${NonLinSST_BrainMask}.nii.gz

$FSLDIR/bin/fslmaths ${NonLinSST_BrainMask}.nii.gz -fillh ${NonLinSST_BrainMask}.nii.gz
${FSLDIR}/bin/fslmaths ${NonLinSSTDirImg}.nii.gz -mas ${NonLinSST_BrainMask}.nii.gz ${NonLinSSTDirImg}_${BETREGOP}_brain.nii.gz
${FSLDIR}/bin/fslmaths ${NonLinSSTDirImg}.nii.gz -sub ${NonLinSSTDirImg}_${BETREGOP}_brain.nii.gz ${NonLinSSTDirImg}_${BETREGOP}_skull.nii.gz


######################

echo "++++++Now sort out the masks...."
echo ""

v_cnt=0
for SesID in ${SesIDList[@]}
do
	#SesID=${SesIDList[v_cnt]}

	echo "============================================================"
	echo "** StudyID: ${StudyID}, SubID: ${SubID}, SesID: ${SesID}"
	echo "============================================================"

	echo " ------------------------------------------------- SESSION: ${SesID} -------------"

	FreeSurfer_Dir=${PRSD_SUBDIR}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_run-1_T1w.${XSectionalDirSuffix}
	FreeSurfer_Vol_Dir=${FreeSurfer_Dir}/sub-${SubID}_ses-${SesID}_run-1_T1w/mri
	FreeSurfer_Vol_nuImg=${FreeSurfer_Vol_Dir}/nu

	#Moving Image
	Sub2NonLinSST_InvWarpFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nusub-${SubID}_ses-${SesID}_nu_2_median_nu${v_cnt}1InverseWarp
	Sub2NonLinSST_AffineFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nusub-${SubID}_ses-${SesID}_nu_2_median_nu${v_cnt}0GenericAffine
	FreeSurferVol_SubInMedian=${SST_Dir}/sub-${SubID}_ses-${SesID}_nu_2_median_nu

	LinearSSTBrainMask=${SST_Dir}/sub-${SubID}_ses-${SesID}_BrainMaskLinearSST
	#rm -f ${LinearSSTBrainMask}.nii.gz

	echo "*************************************************************"
	echo "--Session ID: ${SesID}, ${v_cnt}/${NumSes}"
	echo "MEDIAN LINEAR TEMPLATE: ${FreeSurferVol_SubInMedian}"
	echo "NU FS IMAGE IN MEDIAN LINEAR TEMPLATE: ${FreeSurferVol_SubInMedian}"
	echo "BRAIN MASK IN LINEAR SST: ${LinearSSTBrainMask}"
	echo "*************************************************************"

	# Take the mask from Nonlinear SST to single subjects in the median linear space -- all with skull
	antsApplyTransforms -d 3 \
	-i ${NonLinSST_BrainMask}.nii.gz \
	-r ${FreeSurferVol_SubInMedian}.nii.gz \
	-t [${Sub2NonLinSST_AffineFile}.mat, 1] \
	-t ${Sub2NonLinSST_InvWarpFile}.nii.gz \
	-o ${LinearSSTBrainMask}.nii.gz

	echo "*************************************************************"
	echo "Brain Extraction on nu of each subject, in Linear SST"
	${FSLDIR}/bin/fslmaths ${LinearSSTBrainMask}.nii.gz -thr ${MaskThr} -bin ${LinearSSTBrainMask}.nii.gz
	${FSLDIR}/bin/fslmaths ${LinearSSTBrainMask}.nii.gz -fillh ${LinearSSTBrainMask}.nii.gz
	${FSLDIR}/bin/fslmaths ${FreeSurferVol_SubInMedian}.nii.gz -mas ${LinearSSTBrainMask}.nii.gz ${FreeSurferVol_SubInMedian}_${BETREGOP}_brain.nii.gz
	#skull
	${FSLDIR}/bin/fslmaths ${FreeSurferVol_SubInMedian}.nii.gz -sub ${FreeSurferVol_SubInMedian}_${BETREGOP}_brain.nii.gz ${FreeSurferVol_SubInMedian}_${BETREGOP}_skull.nii.gz
	echo "*************************************************************"

	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Nonlinear SST > Linear SST : DONE"
	${FSLDIR}/bin/fslinfo ${LinearSSTBrainMask}.nii.gz
	${FSLDIR}/bin/fslhd ${LinearSSTBrainMask}.nii.gz | grep sform
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

	# Get inverse of LTA
	LTA_FILE=${SST_Dir}/sub-${SubID}_ses-${SesID}_norm_xforms.lta
	INV_LTA_FILE=${SST_Dir}/sub-${SubID}_ses-${SesID}_norm_xforms_inv.lta # Inverse LTA
	lta_convert --inlta ${LTA_FILE} --outlta ${INV_LTA_FILE} --invert # Convert the LTAs

	SubjBrainMaskFS=${SST_Dir}/sub-${SubID}_ses-${SesID}_BrainMaskFS
	#rm -f ${SubjBrainMaskFS}.nii.gz

	# take everything back into the nu.mgz space using inverse LTA
	mri_vol2vol --lta ${LTA_FILE} \
	--targ ${LinearSSTBrainMask}.nii.gz \
	--mov ${FreeSurfer_Vol_nuImg}.mgz \
	--no-resample \
	--inv \
	--o ${SubjBrainMaskFS}.nii.gz > /dev/null

	echo "*************************************************************"
	echo "Brain Extraction on FreeSurfer 1x1x1 256^3 space"
	${FSLDIR}/bin/fslmaths ${SubjBrainMaskFS}.nii.gz -thr ${MaskThr} -bin ${SubjBrainMaskFS}.nii.gz
	${FSLDIR}/bin/fslmaths ${SubjBrainMaskFS}.nii.gz -fillh ${SubjBrainMaskFS}.nii.gz
	mri_convert ${FreeSurfer_Vol_nuImg}.mgz ${FreeSurfer_Vol_nuImg}.nii.gz
	${FSLDIR}/bin/fslmaths ${FreeSurfer_Vol_nuImg}.nii.gz -mas ${SubjBrainMaskFS}.nii.gz ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain.nii.gz
	#skull
	${FSLDIR}/bin/fslmaths ${FreeSurfer_Vol_nuImg}.nii.gz -sub ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain.nii.gz ${FreeSurfer_Vol_nuImg}_${BETREGOP}_skull.nii.gz
	echo "*************************************************************"

	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Linear SST > 1x1x1 256^3 : DONE"
	${FSLDIR}/bin/fslinfo ${SubjBrainMaskFS}.nii.gz
	${FSLDIR}/bin/fslhd ${SubjBrainMaskFS}.nii.gz | grep sform
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

	echo ""
	echo ""
	echo "*************************************************************"
	echo "Take the brains from FreeSurfer brain images to the rawavg space."
	echo "Make a mask of the rawavg."
	echo "*************************************************************"
	echo ""
	echo ""

	UnprocessedImg=${UnprocessedDir}/sub-${SubID}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_run-1_T1w
#
#	# Now take me from 1x1x1 256^3 to the subject space
	#mri_vol2vol --mov ${FreeSurfer_Vol_nuImg}_brain.nii.gz --targ ${UnprocessedImg}.nii.gz --regheader \
	#--o ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg.nii.gz --no-save-reg
#
#	${FSLDIR}/bin/fslmaths ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg.nii.gz -bin ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg_mask.nii.gz
#	${FSLDIR}/bin/fslmaths ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg_mask.nii.gz -fillh ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg_mask.nii.gz
#
#	#skull
	#mri_vol2vol --mov ${FreeSurfer_Vol_nuImg}_${BETREGOP}_skull.nii.gz --targ ${UnprocessedImg}.nii.gz --regheader \
	#--o ${FreeSurfer_Vol_nuImg}_${BETREGOP}_skull_rawavg.nii.gz --no-save-reg

        #skull
        mri_vol2vol --mov ${FreeSurfer_Vol_nuImg}_${BETREGOP}_skull.nii.gz --targ ${UnprocessedImg}.nii.gz --regheader \
        --o ${FreeSurfer_Vol_nuImg}_${BETREGOP}_skull_rawavg.nii.gz --no-save-reg

        #-- BRAIN MASKS
        mri_vol2vol --mov ${SubjBrainMaskFS}.nii.gz --targ ${UnprocessedImg}.nii.gz --regheader \
        --o ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg_mask.nii.gz --nearest --no-save-reg

        ${FSLDIR}/bin/fslmaths ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg_mask.nii.gz -fillh ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg_mask.nii.gz
        ${FSLDIR}/bin/fslmaths ${UnprocessedImg}.nii.gz -mas ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg_mask.nii.gz ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg.nii.gz

        #echo "+_+_+_+_+__CHECK THIS:"
        #echo "${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg.nii.gz"
        #echo "${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg_mask.nii.gz"

		v_cnt=$((v_cnt+1))

done

echo "==================================="
echo "DONE-DONE-DONE-DONE-DONE-DONE-DONE"
echo "STARTED @" $(date)
echo "==================================="
