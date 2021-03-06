#!/bin/bash
#
# Soroosh Afyouni, University of Oxford, 2020

set -e

ml FreeSurfer
ml Perl
source /apps/eb/software/FreeSurfer/6.0.1-centos6_x86_64/FreeSurferEnv.sh

VoxRes=2

MNITMP_DIR=${HOME}/NVROXBOX/AUX/MNItemplates
ATLAS_DIR=${HOME}/NVROXBOX/AUX/atlas/GMatlas
TISS_DIR=${HOME}/NVROXBOX/AUX/tissuepriors

# head --
echo "RAS the head"
MNIImg=${FSLDIR}/data/standard/MNI152_T1_${VoxRes}mm
MNIImg_RAS=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_RAS

mri_convert --in_orientation LAS --out_orientation RAS ${MNIImg}.nii.gz ${MNIImg_RAS}.nii.gz

fslmaths ${MNIImg_RAS}.nii.gz -bin ${MNIImg_RAS}_mask.nii.gz

# brain --
echo "RAS the brain"
MNIImg_brain=${FSLDIR}/data/standard/MNI152_T1_${VoxRes}mm_brain
MNIImgBrain_RAS=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_brain_RAS

mri_convert --in_orientation LAS --out_orientation RAS ${MNIImg_brain}.nii.gz ${MNIImgBrain_RAS}.nii.gz

# skull --
echo "RAS the skull"
MNIImg_skull=${FSLDIR}/data/standard/MNI152_T1_${VoxRes}mm_skull
MNIImgSkull_RAS=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_skull_RAS

mri_convert --in_orientation LAS --out_orientation RAS ${MNIImg_skull}.nii.gz ${MNIImgSkull_RAS}.nii.gz

# brain mask --
echo "RAS the brain mask"
MaskInMNI=${FSLDIR}/data/standard/MNI152_T1_${VoxRes}mm_brain_mask
MaskInMNI_RAS=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_brain_mask_RAS

mri_convert --in_orientation LAS --out_orientation RAS ${MaskInMNI}.nii.gz ${MaskInMNI_RAS}.nii.gz

# Get the Cort, Cereb, Subcort & Vent masks (For SIENAX)

MNI152strucseg=${FSLDIR}/data/standard/MNI152_T1_${VoxRes}mm_strucseg
MNI152strucseg_RAS=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_strucseg_RAS

mri_convert --in_orientation LAS --out_orientation RAS ${MNI152strucseg}.nii.gz ${MNI152strucseg_RAS}.nii.gz

# Chop out the cereb
fslmaths ${MNI152strucseg_RAS}.nii.gz -thr 2.5 -uthr 3.5 ${MNI152strucseg_RAS}_Cereb.nii.gz
fslmaths ${MNI152strucseg_RAS}.nii.gz -sub ${MNI152strucseg_RAS}_Cereb.nii.gz ${MNI152strucseg_RAS}_NoCereb.nii.gz
fslmaths ${MNI152strucseg_RAS}_NoCereb.nii.gz -bin ${MNI152strucseg_RAS}_NoCereb_bin.nii.gz

# Chop out the Ventricals
${FSLDIR}/bin/fslmaths ${MNI152strucseg_RAS}.nii.gz -thr 4.5 -bin ${MNI152strucseg_RAS}_Vent.nii.gz

# Prepare Seg Periph [sic] -- this is the brain without the cereb and subcot
MNI152structsepriph=${FSLDIR}/data/standard/MNI152_T1_${VoxRes}mm_strucseg_periph
MNI152structsepriph_RAS=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_strucseg_periph_RAS
mri_convert --in_orientation LAS --out_orientation RAS ${MNI152structsepriph}.nii.gz ${MNI152structsepriph_RAS}.nii.gz

# Prepare the Atlases
ATLASMNI=${ATLAS_DIR}/GMatlas_${VoxRes}mm
ATLASMNI_RAS=${ATLAS_DIR}/GMatlas_${VoxRes}mm_RAS
mri_convert --in_orientation LAS --out_orientation RAS ${ATLASMNI}.nii.gz ${ATLASMNI_RAS}.nii.gz

# Prepare the priors

for TissueType in gray white csf brain
do

	echo "PRIORS: ${TissueType}"
	mri_convert --in_orientation LAS --out_orientation RAS \
	${TISS_DIR}/avg152T1_${TissueType}.nii.gz ${TISS_DIR}/avg152T1_${TissueType}_RAS.nii.gz
done
