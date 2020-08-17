
module load fsl
module load freesurfer
set -e

InputImg=$1
OutputDir=$2
FSLRegOutputPrefix=$3
CONFGFILE=$4

echo "Input: ${InputImg}"
echo "Output: ${OutputDir}"
# -------- Application initialisations ------------------------------------------------
VoxRes=2
SWOP=FNIRT
ORFLAG=LIA

MNIImg=${FSLDIR}/data/standard/MNI152_T1_${VoxRes}mm
MNIImg_FS=${OutputDir}/MNI152_T1_${VoxRes}mm_${ORFLAG}

MaskInMNI=${FSLDIR}/data/standard/MNI152_T1_${VoxRes}mm_brain_mask
MaskInMNI_FS=${OutputDir}/MNI152_T1_${VoxRes}mm_${ORFLAG}_brain_mask

refmask=${OutputDir}/MNI152_T1_2mm_brain_mask_dil1
$FSLDIR/bin/fslmaths $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask.nii.gz -fillh -dilF $refmask

mri_convert --in_orientation LAS --out_orientation ${ORFLAG} ${refmask}.nii.gz ${refmask}.nii.gz
mri_convert --in_orientation LAS --out_orientation ${ORFLAG} ${MNIImg}.nii.gz ${MNIImg_FS}.nii.gz
mri_convert --in_orientation LAS --out_orientation ${ORFLAG} ${MaskInMNI}.nii.gz ${MaskInMNI_FS}.nii.gz

echo "DONE"

# ------- Path inistialisations --------------------------------------------------------

## REGISTRATION ######

$FSLDIR/bin/flirt -interp spline \
-dof 12 \
-in ${InputImg}.nii.gz \
-ref ${MNIImg_FS}.nii.gz \
-omat ${FSLRegOutputPrefix}affine.mat \
-out ${FSLRegOutputPrefix}Lin.nii.gz

$FSLDIR/bin/fnirt \
--in=${InputImg}.nii.gz \
--ref=${MNIImg_FS}.nii.gz \
--fout=${FSLRegOutputPrefix}warp.nii.gz \
--jout=${FSLRegOutputPrefix}jac.nii.gz \
--iout=${FSLRegOutputPrefix}warped.nii.gz \
--logout=${FSLRegOutputPrefix}log.txt \
--cout=${FSLRegOutputPrefix}coeff.nii.gz \
--aff=${FSLRegOutputPrefix}affine.mat \
--refmask=$refmask \
--config=${CONFGFILE}

######################

# extract the brain of nonlinear template in MNI
${FSLDIR}/bin/fslmaths ${FSLRegOutputPrefix}warped.nii.gz -mas ${MaskInMNI_FS}.nii.gz ${FSLRegOutputPrefix}warped_brain.nii.gz # brain in MNI space

$FSLDIR/bin/invwarp --ref=${InputImg}.nii.gz \
-w ${FSLRegOutputPrefix}coeff.nii.gz \
-o ${FSLRegOutputPrefix}invwarp.nii.gz

InputImgBrainMask=${FSLRegOutputPrefix}_brainmask

$FSLDIR/bin/applywarp \
--interp=nn \
--in=${MaskInMNI_FS}.nii.gz \
--ref=${InputImg}.nii.gz \
-w ${FSLRegOutputPrefix}invwarp.nii.gz \
-o ${InputImgBrainMask}.nii.gz

$FSLDIR/bin/fslmaths ${InputImgBrainMask}.nii.gz -fillh ${InputImgBrainMask}.nii.gz

# use the brain mask in Nonlinear SST to mask the Nonlinear SST image
${FSLDIR}/bin/fslmaths ${InputImg}.nii.gz -mas ${InputImgBrainMask}.nii.gz ${InputImg}_brain.nii.gz
${FSLDIR}/bin/fslmaths ${NonLinSSTDirImg}.nii.gz -sub ${NonLinSSTDirImg}_brain.nii.gz ${NonLinSSTDirImg}_skull.nii.gz
