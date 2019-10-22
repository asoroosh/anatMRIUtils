ml ANTs
ml FreeSurfer
ml Perl
source /apps/eb/software/FreeSurfer/6.0.1-centos6_x86_64/FreeSurferEnv.sh

set -e

#--------- SubID, StudyID, info from ANTs SST -----------------------------------------
SubID=sub-CFTY720D2324.0217.00001
NonLinTempImgName=${SubID}_ants_temp_med_nutemplate0

VisitLabelList=(V2 V3 V4 V5)
NumVisit=${#VisitLabelList[@]}

# ------
CWDD=/home/bdivdi.local/dfgtyk/NVROXBOX/EXE/brainmasks
ImgDir=${CWDD}/brainimg
SST_Dir=${CWDD}/brainimg/T12D.autorecon12ws.nuws_mrirobusttemplate

# Nonlinear Template
NonLinSSTDirImg=${SST_Dir}/${NonLinTempImgName}

# Linear Template
LinSST=${SST_Dir}/${SubID}_norm_nu_median.nii.gz # this should be moved

# MNI templates
MNITMP_DIR=${ImgDir}/MNITMPLT

# -------- Application initialisations ------------------------------------------------
VoxRes=2
SWOP=FNIRT

MNIImg=${FSLDIR}/data/standard/MNI152_T1_${VoxRes}mm
MNIImg_FS=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_FS

MaskInMNI=${FSLDIR}/data/standard/MNI152_T1_${VoxRes}mm_brain_mask
MaskInMNI_FS=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_FS_brain_mask

cp ${MNIImg}.nii.gz ${MNIImg_FS}.nii.gz
cp ${MaskInMNI}.nii.gz ${MaskInMNI_FS}.nii.gz
#mri_convert --in_orientation LAS --out_orientation RAS ${MNIImg}.nii.gz ${MNIImg_FS}.nii.gz
#mri_convert --in_orientation LAS --out_orientation RAS ${MaskInMNI}.nii.gz ${MaskInMNI_FS}.nii.gz

echo "*************************************************************"
echo "=== BRING THE MNI TEMPLATE & MASK INTO RAS ORIENTATION:"
echo "MNI RAS: ${MNIImg_FS}"
echo "BrainMask RAS: ${MaskInMNI_FS}"
echo "*************************************************************"

# ------- Path inistialisations --------------------------------------------------------

#register to MNI
FSLRegOutputPrefix=${NonLinSSTDirImg}_FSL-MNI-${VoxRes}mm-
NonLinSST_MNI=${FSLRegOutputPrefix}FNIRTWarped
NonLinSST_MNI_InvWarp=${FSLRegOutputPrefix}1InverseWarp
NonLinSST_MNI_Affine=${FSLRegOutputPrefix}FLIRTAffine.mat

# ------- Do the job ---------------------------------------------------------------------

## REGISTRATION ######

refmask=${SST_Dir}/MNI152_T1_2mm_brain_mask_dil1
$FSLDIR/bin/fslmaths $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask -fillh -dilF $refmask

echo "*************************************************************"
echo "REGISTER NONLINEAR SST > MNI RAS"
echo "MOVING: ${NonLinSSTDirImg}.nii.gz"
echo "FIXED: ${MNIImg_FS}.nii.gz"
echo "RefMASK: ${refmask}"
echo "*************************************************************"

#antsRegistrationSyN.sh -d 3 \
#-f ${MNIImg_FS}.nii.gz \
#-m ${NonLinSSTDirImg}.nii.gz \
#-t s \
#-x ${NonLinSSTDirImg_mask}.nii.gz \
#-o ${antsRegOutputPrefix}

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
--iout=${antsRegOutputPrefix}warped.nii.gz \
--logout=${FSLRegOutputPrefix}log.txt \
--cout=${FSLRegOutputPrefix}coeff.nii.gz \
--aff=${FSLRegOutputPrefix}affine.mat \
--refmask=$refmask \
--config=${HOME}/NVROXBOX/EXE/FSL/fnirt/tests/FNIRTCHECK_infwhm4322-lambda3001005030-sbsmpl1111-nomask_T1_2_MNI152_2mm.cnf

######################

# extract the brain of nonlinear template in MNI
fslmaths ${antsRegOutputPrefix}warped.nii.gz -mas ${MaskInMNI_FS}.nii.gz ${antsRegOutputPrefix}warped_brain.nii.gz # brain in MNI space

# Bring back the brain *mask* into Nonlinear SST space

# NonLinear SST Brain Mask
NonLinSST_BrainMask=${SST_Dir}/${SubID}_NonLinearSST_${SWOP}_BrainMask
rm -f ${NonLinSST_BrainMask}.nii.gz

echo "*************************************************************"
echo "BRAIN MASK:::  MNI > NonLinSST   ::::"
echo "Inverse Warp: ${FSLRegOutputPrefix}warp"
echo "& the Affine: ${FSLRegOutputPrefix}affine.mat"
echo " "
echo "Output: ${NonLinSST_BrainMask}"
echo "*************************************************************"

$FSLDIR/bin/invwarp --ref=${NonLinSSTDirImg}.nii.gz -w ${FSLRegOutputPrefix}coeff.nii.gz -o ${FSLRegOutputPrefix}invwarp.nii.gz

$FSLDIR/bin/applywarp \
--interp=nn \
--in=${MaskInMNI_FS}.nii.gz \
--ref=${NonLinSSTDirImg}.nii.gz \
-w ${FSLRegOutputPrefix}invwarp.nii.gz \
-o ${NonLinSST_BrainMask}.nii.gz

$FSLDIR/bin/fslmaths ${NonLinSST_BrainMask}.nii.gz -fillh ${NonLinSST_BrainMask}.nii.gz

#$FSLDIR/bin/fslmaths ${T1}_biascorr -mas ${T1}_biascorr_brain_mask ${T1}_biascorr_brain
# threshold the mask to get rid of rubbishes
#fslmaths ${NonLinSST_BrainMask}.nii.gz -thr 0.01 -bin ${NonLinSST_BrainMask}.nii.gz
# fill out the holes
#fslmaths ${NonLinSST_BrainMask}.nii.gz -fillh ${NonLinSST_BrainMask}.nii.gz

# use the brain mask in Nonlinear SST to mask the Nonlinear SST image
fslmaths ${NonLinSSTDirImg}.nii.gz -mas ${NonLinSST_BrainMask}.nii.gz ${NonLinSSTDirImg}_brain.nii.gz

####
echo "++++++Now sort out the masks...."
echo ""

SubTag=sub-CFTY720D2324 # this has to be removed later -- a mess up in ANTs prefix output

XSectionalDirSuffix=autorecon12ws
# Get subject specific brain masks
for v_cnt in $(seq 0 $(($NumVisit-1)))
do

	SesID=${VisitLabelList[v_cnt]}

	FreeSurfer_Dir=${ImgDir}/${SubID}_ses-${SesID}_run-1_T1w.${XSectionalDirSuffix}/
	FreeSurfer_Vol_Dir=${FreeSurfer_Dir}/${SubID}_ses-${SesID}_run-1_T1w/mri
	FreeSurfer_Vol_nuImg=${FreeSurfer_Vol_Dir}/nu

	# Maybe to mgz>nifti?

	#Moving Image
	FreeSurferVol_SubInMedian=${SST_Dir}/${SubID}_ses-${SesID}_nu_2_median_nu
	Sub2NonLinSST_InvWarpFile=${SST_Dir}/${SubID}_ants_temp_med_nu${SubTag}${v_cnt}1InverseWarp
	Sub2NonLinSST_AffineFile=${SST_Dir}/${SubID}_ants_temp_med_nu${SubTag}${v_cnt}0GenericAffine

	LinearSSTBrainMask=${SST_Dir}/${SubID}_${SesID}_${SWOP}_BrainMaskLinearSST
	rm -f ${LinearSSTBrainMask}.nii.gz

	echo "*************************************************************"
	echo "--Session ID: ${SesID}, ${v_cnt}/${NumVisit}"
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

	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Nonlinear SST > Linear SST : DONE"
	fslinfo ${LinearSSTBrainMask}.nii.gz
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

	# Now take back the masks from Linear SST to the subject space (i.e. FreeSurfer space 1x1x1, 256x256x256)
	# MOV_FILE=${ImgDir}/${SubID}/ses-${SesID}/anat/${SubID}_ses-${SesID}_run-1_T1w.nii.gz

	# Get inverse of LTA
	LTA_FILE=${SST_Dir}/${SubID}_ses-${SesID}_norm_xforms.lta
	INV_LTA_FILE=${SST_Dir}/${SubID}_ses-${SesID}_norm_xforms_inv.lta
	# conver the LTA
	lta_convert --inlta ${LTA_FILE} --outlta ${INV_LTA_FILE} --invert

	SubjBrainMaskFS=${SST_Dir}/${SubID}_${SesID}_${SWOP}_BrainMaskFS

	rm -f ${SubjBrainMaskFS}.nii.gz

	# take everything back into the nu.mgz space using inverse LTA
	mri_vol2vol --lta ${LTA_FILE} \
	--targ ${LinearSSTBrainMask}.nii.gz \
	--mov ${FreeSurfer_Vol_nuImg}.mgz \
	--inv \
	--o ${SubjBrainMaskFS}.nii.gz

	fslmaths ${SubjBrainMaskFS}.nii.gz -thr 0.01 -bin ${SubjBrainMaskFS}.nii.gz

	echo "*************************************************************"
	echo "--Session ID: ${SesID}, ${v_cnt}"
	echo "NU FS IMAGES: ${FreeSurfer_Vol_nuImg}"
	echo "Subject level brain masks: ${SubjBrainMaskFS}"
	echo "*************************************************************"

	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Linear SST > FS SUBJ : DONE"
	fslinfo ${SubjBrainMaskFS}
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

done
