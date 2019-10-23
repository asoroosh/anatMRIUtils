ml ANTs
ml FreeSurfer
ml Perl
source /apps/eb/software/FreeSurfer/6.0.1-centos6_x86_64/FreeSurferEnv.sh

set -e

do_reg=1

#--------- SubID, StudyID, info from ANTs SST -----------------------------------------
# comes from the user:
StudyID=CFTY720D2324
SubID=${StudyID}.0217.00001
SubTag=sub-CFTY720D2324 #this is what the antsMultivariateTemplate uses

#--------------------------------------------------------------------------------------
echo "======================================="
echo "STARTED @" $(date)
echo "======================================="

SessionsFileName=${HOME}/NVROXBOX/Data/${StudyID}/T12D/Sessions/${StudyID}_sub-${SubID}_T12D.txt
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
XSectionalDirSuffix=autorecon12ws
NonLinTempImgName=sub-${SubID}_ants_temp_med_nutemplate0

# ------
STRG=/data/users/dfgtyk
ImgDir=${STRG}/brainimg
SST_Dir=${STRG}/brainimg/T12D.autorecon12ws.nuws_mrirobusttemplate

# Nonlinear Template
NonLinSSTDirImg=${SST_Dir}/${NonLinTempImgName}

# Linear Template
LinSST=${SST_Dir}/sub-${SubID}_norm_nu_median.nii.gz # this should be moved

# MNI templates
MNITMP_DIR=${ImgDir}/MNITMPLT

# -------- Application initialisations ------------------------------------------------
VoxRes=2
MaskThr=0.5

MNIImg=${FSLDIR}/data/standard/MNI152_T1_${VoxRes}mm
MNIImg_FS=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_FS

MaskInMNI=${FSLDIR}/data/standard/MNI152_T1_${VoxRes}mm_brain_mask
MaskInMNI_FS=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_FS_brain_mask

#AtlasInMNI=${HOME}/NVROXBOX/AUX/atlas/GMatlas/GMatlas_2mm_intepNN
#AtlasInMNI_RAS=${HOME}/NVROXBOX/AUX/atlas/GMatlas/RAS/GMatlas_2mm_intepNN

mri_convert --in_orientation LAS --out_orientation RAS ${MNIImg}.nii.gz ${MNIImg_FS}.nii.gz
mri_convert --in_orientation LAS --out_orientation RAS ${MaskInMNI}.nii.gz ${MaskInMNI_FS}.nii.gz
#mri_convert --in_orientation LAS --out_orientation RAS ${AtlasInMNI}.nii.gz ${AtlasInMNI_RAS}.nii.gz


echo "*************************************************************"
echo "=== BRING THE MNI TEMPLATE & MASK INTO RAS ORIENTATION:"
echo "MNI RAS: ${MNIImg_FS}"
echo "BrainMask RAS: ${MaskInMNI_FS}"
echo "*************************************************************"

# ------- Path inistialisations --------------------------------------------------------

#register to MNI
antsRegOutputPrefix=${NonLinSSTDirImg}_MNI-${VoxRes}mm-
NonLinSST_MNI=${antsRegOutputPrefix}Warped
NonLinSST_MNI_InvWarp=${antsRegOutputPrefix}1InverseWarp
NonLinSST_MNI_Affine=${antsRegOutputPrefix}0GenericAffine.mat

if [ $do_reg == 1 ]; then
#	rm -f ${NonLinSST_MNI_InvWarp} ${NonLinSST_MNI_Affine} ${NonLinSST_MNI}
		echo "TEST"
	else
		echo "############# No Registration will be done..."
fi

# ------- Do the job ---------------------------------------------------------------------

## REGISTRATION ######

# prepare a mask for ANTs
NonLinSSTDirImg_mask=${NonLinSSTDirImg}_mask
${FSLDIR}/bin/fslmaths ${NonLinSSTDirImg}.nii.gz -bin ${NonLinSSTDirImg_mask}.nii.gz
# delineate the mask
${FSLDIR}/bin/fslmaths ${NonLinSSTDirImg_mask}.nii.gz -dilM ${NonLinSSTDirImg_mask}.nii.gz

echo "*************************************************************"
echo "REGISTER NONLINEAR SST > MNI RAS"
echo "MOVING: ${NonLinSSTDirImg}.nii.gz"
echo "FIXED: ${MNIImg_FS}.nii.gz"
echo "MASK: ${NonLinSSTDirImg_mask}"
echo "*************************************************************"

#------ TESTS
#antsRegistrationSyNQuick.sh -d 3 \
#-f ${MNIImg_FS}.nii.gz \
#-m ${NonLinSSTDirImg}.nii.gz \
#-t s \
#-x ${NonLinSSTDirImg_mask}.nii.gz \
#-o ${antsRegOutputPrefix}

#ShrnkFctrs="6x4x4x1"
#SmthFctrs="3x2x1x0vox"
#ItrNum="100x100x100x0"
#-------------------------------

ShrnkFctrs="1x1x1x1"
SmthFctrs="3x2x1x0vox"
ItrNum="1000x500x250x0"


if [ $do_reg == 1 ]; then

antsRegistration \
--verbose 0 \
--dimensionality 3 \
--float 0 \
--collapse-output-transforms 1 \
--output [${antsRegOutputPrefix},${antsRegOutputPrefix}Warped.nii.gz,${antsRegOutputPrefix}InverseWarped.nii.gz] \
--interpolation Linear \
--use-histogram-matching 1 \
--winsorize-image-intensities [0.005,0.995] \
-x [${NonLinSSTDirImg_mask}.nii.gz, NULL] \
--initial-moving-transform [${MNIImg_FS}.nii.gz,${NonLinSSTDirImg}.nii.gz,1] \
--transform Rigid[0.1] \
--metric MI[${MNIImg_FS}.nii.gz,${NonLinSSTDirImg}.nii.gz,1,32,Regular,0.25] \
--convergence [${ItrNum},1e-6,10] \
--shrink-factors ${ShrnkFctrs} \
--smoothing-sigmas ${SmthFctrs} \
--transform Affine[0.1] \
--metric MI[${MNIImg_FS}.nii.gz,${NonLinSSTDirImg}.nii.gz,1,32,Regular,0.25] \
--convergence [${ItrNum},1e-6,10] \
--shrink-factors ${ShrnkFctrs} \
--smoothing-sigmas ${SmthFctrs} \
--transform SyN[0.1,3,0] \
--metric CC[${MNIImg_FS}.nii.gz,${NonLinSSTDirImg}.nii.gz,1,4] \
--convergence [${ItrNum},1e-6,10] \
--shrink-factors ${ShrnkFctrs} \
--smoothing-sigmas ${SmthFctrs}


else
	echo "############# No Registration will be done..."

fi

# Take a picture
Reg_OUTPUTpngIMAGE=${antsRegOutputPrefix}Warped_Image
sh ${HOME}/NVROXBOX/SOURCE/NVR-OX-slicer-overlay.sh "${antsRegOutputPrefix}Warped.nii.gz" "$FSLDIR/data/standard/MNI152_T1_2mm_brain_mask.nii.gz" "${Reg_OUTPUTpngIMAGE}" 1

######################

# extract the brain of nonlinear template in MNI
${FSLDIR}/bin/fslmaths ${NonLinSST_MNI}.nii.gz -mas ${MaskInMNI_FS}.nii.gz ${NonLinSST_MNI}_brain.nii.gz # brain in MNI space

#Skull
${FSLDIR}/bin/fslmaths ${NonLinSST_MNI}.nii.gz -sub ${NonLinSST_MNI}_brain.nii.gz ${NonLinSST_MNI}_skull.nii.gz


# NonLinear SST Brain Mask
NonLinSST_BrainMask=${SST_Dir}/sub-${SubID}_NonLinearSST_BrainMask
rm -f ${NonLinSST_BrainMask}.nii.gz

echo "*************************************************************"
echo "BRAIN MASK:::  MNI > NonLinSST   ::::"
echo "Inverse Warp: ${NonLinSST_MNI_InvWarp}"
echo "& the Affine: ${NonLinSST_MNI_Affine}"
echo " "
echo "Output: ${NonLinSST_BrainMask}"
echo "*************************************************************"

antsApplyTransforms -d 3 \
-i ${MaskInMNI_FS}.nii.gz \
-r ${NonLinSSTDirImg}.nii.gz \
-t [${NonLinSST_MNI_Affine}, 1] \
-t ${NonLinSST_MNI_InvWarp}.nii.gz \
-o ${NonLinSST_BrainMask}.nii.gz

echo "*************************************************************"
echo "Brain Extraction on NonLinear SST"
# threshold the mask, fill the holes and mask the image
${FSLDIR}/bin/fslmaths ${NonLinSST_BrainMask}.nii.gz -thr ${MaskThr} -bin ${NonLinSST_BrainMask}.nii.gz
${FSLDIR}/bin/fslmaths ${NonLinSST_BrainMask}.nii.gz -fillh ${NonLinSST_BrainMask}.nii.gz
${FSLDIR}/bin/fslmaths ${NonLinSSTDirImg}.nii.gz -mas ${NonLinSST_BrainMask}.nii.gz ${NonLinSSTDirImg}_brain.nii.gz
#skull
${FSLDIR}/bin/fslmaths ${NonLinSSTDirImg}.nii.gz -sub ${NonLinSSTDirImg}_brain.nii.gz ${NonLinSSTDirImg}_skull.nii.gz
echo "*************************************************************"

#Take a picture of Nonlinear SST mask
NonLinSSTpngIMAGE=${NonLinSST_BrainMask}_Image
sh ${HOME}/NVROXBOX/SOURCE/NVR-OX-slicer-overlay.sh "${NonLinSSTDirImg}.nii.gz" "${NonLinSST_BrainMask}.nii.gz" "${NonLinSSTpngIMAGE}" 1

####
echo "++++++Now sort out the masks...."
echo ""

# Get subject specific brain masks
for v_cnt in $(seq 0 $(($NumSes-1)))
do
	SesID=${SesIDList[v_cnt]}

	echo " ------------------------------------------------- SESSION: ${SesID} -------------"

	FreeSurfer_Dir=${ImgDir}/sub-${SubID}_ses-${SesID}_run-1_T1w.${XSectionalDirSuffix}/
	FreeSurfer_Vol_Dir=${FreeSurfer_Dir}/sub-${SubID}_ses-${SesID}_run-1_T1w/mri
	FreeSurfer_Vol_nuImg=${FreeSurfer_Vol_Dir}/nu

	# Maybe to mgz>nifti?

	#Moving Image
	FreeSurferVol_SubInMedian=${SST_Dir}/sub-${SubID}_ses-${SesID}_nu_2_median_nu
	Sub2NonLinSST_InvWarpFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nu${SubTag}${v_cnt}1InverseWarp
	Sub2NonLinSST_AffineFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nu${SubTag}${v_cnt}0GenericAffine

	LinearSSTBrainMask=${SST_Dir}/sub-${SubID}_ses-${SesID}_BrainMaskLinearSST
	rm -f ${LinearSSTBrainMask}.nii.gz

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
	${FSLDIR}/bin/fslmaths ${FreeSurferVol_SubInMedian}.nii.gz -mas ${LinearSSTBrainMask}.nii.gz ${FreeSurferVol_SubInMedian}_brain.nii.gz
	#skull
	${FSLDIR}/bin/fslmaths ${FreeSurferVol_SubInMedian}.nii.gz -sub ${FreeSurferVol_SubInMedian}_brain.nii.gz ${FreeSurferVol_SubInMedian}_skull.nii.gz
	echo "*************************************************************"

	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Nonlinear SST > Linear SST : DONE"
	${FSLDIR}/bin/fslinfo ${LinearSSTBrainMask}.nii.gz
	${FSLDIR}/bin/fslhd ${LinearSSTBrainMask}.nii.gz | grep sform
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

	# Now take back the masks from Linear SST to the subject space (i.e. FreeSurfer space 1x1x1, 256x256x256)
	# MOV_FILE=${ImgDir}/${SubID}/ses-${SesID}/anat/${SubID}_ses-${SesID}_run-1_T1w.nii.gz

	# Get inverse of LTA
	LTA_FILE=${SST_Dir}/sub-${SubID}_ses-${SesID}_norm_xforms.lta
	INV_LTA_FILE=${SST_Dir}/sub-${SubID}_ses-${SesID}_norm_xforms_inv.lta # Inverse LTA
	lta_convert --inlta ${LTA_FILE} --outlta ${INV_LTA_FILE} --invert # Convert the LTAs

	SubjBrainMaskFS=${SST_Dir}/sub-${SubID}_ses-${SesID}_BrainMaskFS
	rm -f ${SubjBrainMaskFS}.nii.gz

	# take everything back into the nu.mgz space using inverse LTA
	mri_vol2vol --lta ${LTA_FILE} \
	--targ ${LinearSSTBrainMask}.nii.gz \
	--mov ${FreeSurfer_Vol_nuImg}.mgz \
	--no-resample \
	--inv \
	--o ${SubjBrainMaskFS}.nii.gz

	echo "*************************************************************"
	echo "Brain Extraction on FreeSurfer 1x1x1 256^3 space"
	${FSLDIR}/bin/fslmaths ${SubjBrainMaskFS}.nii.gz -thr ${MaskThr} -bin ${SubjBrainMaskFS}.nii.gz
	${FSLDIR}/bin/fslmaths ${SubjBrainMaskFS}.nii.gz -fillh ${SubjBrainMaskFS}.nii.gz
	mri_convert ${FreeSurfer_Vol_nuImg}.mgz ${FreeSurfer_Vol_nuImg}.nii.gz
	${FSLDIR}/bin/fslmaths ${FreeSurfer_Vol_nuImg}.nii.gz -mas ${SubjBrainMaskFS}.nii.gz ${FreeSurfer_Vol_nuImg}_brain.nii.gz
	#skull
	${FSLDIR}/bin/fslmaths ${FreeSurfer_Vol_nuImg}.nii.gz -sub ${FreeSurfer_Vol_nuImg}_brain.nii.gz ${FreeSurfer_Vol_nuImg}_skull.nii.gz
	echo "*************************************************************"

	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Linear SST > 1x1x1 256^3 : DONE"
	${FSLDIR}/bin/fslinfo ${SubjBrainMaskFS}.nii.gz
	${FSLDIR}/bin/fslhd ${SubjBrainMaskFS}.nii.gz | grep sform
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

	#Take a picture of subject level mask
	SubjBrainMaskFSpngIMAGE=${SubjBrainMaskFS}_Image
	sh ${HOME}/NVROXBOX/SOURCE/NVR-OX-slicer-overlay.sh "${FreeSurfer_Vol_nuImg}.nii.gz" "${SubjBrainMaskFS}" "${SubjBrainMaskFSpngIMAGE}" 1
	sh ${HOME}/NVROXBOX/SOURCE/NVR-OX-slicer.sh "${FreeSurfer_Vol_nuImg}_brain.nii.gz" "${SubjBrainMaskFSpngIMAGE}" 1
	sh ${HOME}/NVROXBOX/SOURCE/NVR-OX-slicer.sh "${FreeSurfer_Vol_nuImg}.nii.gz" "${SubjBrainMaskFSpngIMAGE}" 1

	# Now take me from 1x1x1 256^3 to the subject space
	UnprocessedImg=${ImgDir}/sub-${SubID}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_run-1_T1w

	mri_vol2vol --mov ${FreeSurfer_Vol_nuImg}_brain.nii.gz \
	--targ ${UnprocessedImg}.nii.gz --regheader \
	--o ${FreeSurfer_Vol_nuImg}_brain_rawavg.nii.gz --no-save-reg

	${FSLDIR}/bin/fslmaths ${FreeSurfer_Vol_nuImg}_brain_rawavg.nii.gz -bin ${FreeSurfer_Vol_nuImg}_brain_rawavg_mask.nii.gz
	${FSLDIR}/bin/fslmaths ${FreeSurfer_Vol_nuImg}_brain_rawavg_mask.nii.gz -fillh ${FreeSurfer_Vol_nuImg}_brain_rawavg_mask.nii.gz

	#skull
	mri_vol2vol --mov ${FreeSurfer_Vol_nuImg}_skull.nii.gz \
	--targ ${UnprocessedImg}.nii.gz --regheader \
	--o ${FreeSurfer_Vol_nuImg}_skull_rawavg.nii.gz --no-save-reg

done

echo "==================================="
echo "DONE-DONE-DONE-DONE-DONE-DONE-DONE"
echo "STARTED @" $(date)
echo "==================================="
