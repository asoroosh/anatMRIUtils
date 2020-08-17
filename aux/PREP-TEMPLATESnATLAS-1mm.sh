#!/bin/bash
#

# Soroosh Afyouni, University of Oxford, 2020

set -e

ml FreeSurfer
ml Perl
source /apps/eb/software/FreeSurfer/6.0.1-centos6_x86_64/FreeSurferEnv.sh

fromOr=LAS
toOr=LIA
VoxRes=1

MNITMP_DIR=${HOME}/NVROXBOX/AUX/MNItemplates/${toOr}
ATLAS_DIR=${HOME}/NVROXBOX/AUX/atlas/GMatlas/${toOr}
TISS_DIR=${HOME}/NVROXBOX/AUX/tissuepriors/${toOr}

mkdir -p ${MNITMP_DIR}
mkdir -p ${ATLAS_DIR}
mkdir -p ${TISS_DIR}

# head --
echo "${toOr} the head"
MNIImg=${FSLDIR}/data/standard/MNI152_T1_${VoxRes}mm
MNIImg_RAS=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_${toOr}

mri_convert --in_orientation $fromOr --out_orientation ${toOr} ${MNIImg}.nii.gz ${MNIImg_RAS}.nii.gz

${FSLDIR}/bin/fslmaths ${MNIImg_RAS}.nii.gz -bin ${MNIImg_RAS}_mask.nii.gz

# brain --
echo "LIA the brain"
MNIImg_brain=${FSLDIR}/data/standard/MNI152_T1_${VoxRes}mm_brain
MNIImgBrain_RAS=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_brain_${toOr}

mri_convert --in_orientation $fromOr --out_orientation ${toOr} ${MNIImg_brain}.nii.gz ${MNIImgBrain_RAS}.nii.gz

# skull --
echo "LIA the skull"
MNIImg_skull=${FSLDIR}/data/standard/MNI152_T1_2mm_skull
MNIImg_skullSampled=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_skull
MNIImgSkull_RAS=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_skull_${toOr}

${FSLDIR}/bin/flirt -interp nearestneighbour \
-in ${MNIImg_skull} \
-ref ${MNIImg_skull} \
-out ${MNIImg_skullSampled} \
-applyisoxfm ${VoxRes}

mri_convert --in_orientation $fromOr --out_orientation ${toOr} ${MNIImg_skullSampled}.nii.gz ${MNIImgSkull_RAS}.nii.gz

# brain mask --
#echo "LIA the brain mask"
#MaskInMNI=${FSLDIR}/data/standard/MNI152_T1_${VoxRes}mm_brain_mask
#MaskInMNI_RAS=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_brain_mask_${toOr}
#mri_convert --in_orientation $fromOr --out_orientation ${toOr} ${MaskInMNI}.nii.gz ${MaskInMNI_RAS}.nii.gz

# Get the Cort, Cereb, Subcort & Vent masks (For SIENAX)----------------------------------------------------------------------

echo "STRUCTURE SEG::::"

MNI152strucseg=${FSLDIR}/data/standard/MNI152_T1_2mm_strucseg
MNI152strucsegSampled=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_strucseg
MNI152strucseg_RAS=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_strucseg_${toOr}

${FSLDIR}/bin/flirt -interp nearestneighbour \
-in ${MNI152strucseg} \
-ref ${MNI152strucseg} \
-out ${MNI152strucsegSampled} \
-applyisoxfm ${VoxRes}

mri_convert --in_orientation $fromOr --out_orientation ${toOr} ${MNI152strucsegSampled}.nii.gz ${MNI152strucseg_RAS}.nii.gz

# Chop out the cereb
fslmaths ${MNI152strucseg_RAS}.nii.gz -thr 2.5 -uthr 3.5 ${MNI152strucseg_RAS}_Cereb.nii.gz
fslmaths ${MNI152strucseg_RAS}.nii.gz -sub ${MNI152strucseg_RAS}_Cereb.nii.gz ${MNI152strucseg_RAS}_NoCereb.nii.gz
fslmaths ${MNI152strucseg_RAS}_NoCereb.nii.gz -bin ${MNI152strucseg_RAS}_NoCereb_bin.nii.gz

# Chop out the Ventricals ----------------------------------------------------------------------------------------------------
${FSLDIR}/bin/fslmaths ${MNI152strucseg_RAS}.nii.gz -thr 4.5 -bin ${MNI152strucseg_RAS}_Vent.nii.gz

# Prepare Seg Periph [sic] -- this is the brain without the cereb and subcot -------------------------------------------------
MNI152structsepriph=${FSLDIR}/data/standard/MNI152_T1_2mm_strucseg_periph
MNI152structsepriphSampled=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_strucseg_periph
MNI152structsepriph_RAS=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_strucseg_periph_${toOr}

${FSLDIR}/bin/flirt \
-in ${MNI152structsepriph} \
-ref ${MNI152structsepriph} \
-interp nearestneighbour \
-out ${MNI152structsepriphSampled} \
-applyisoxfm ${VoxRes}

mri_convert --in_orientation $fromOr --out_orientation ${toOr} ${MNI152structsepriphSampled}.nii.gz ${MNI152structsepriph_RAS}.nii.gz

# Prepare the AtfromOres --------------------------------------------------------------------------------------------------------
ATLASMNI=${ATLAS_DIR}/GMatlas_2mm
ATLASMNI_SAMPLED=${ATLAS_DIR}/GMatlas_${VoxRes}mm
ATLASMNI_RAS=${ATLAS_DIR}/GMatlas_${VoxRes}mm_${toOr}

${FSLDIR}/bin/flirt \
-in ${ATLASMNI} \
-ref ${ATLASMNI} \
-interp nearestneighbour \
-out ${ATLASMNI_SAMPLED} \
-applyisoxfm ${VoxRes}

mri_convert --in_orientation $fromOr --out_orientation ${toOr} ${ATLASMNI_SAMPLED}.nii.gz ${ATLASMNI_RAS}.nii.gz

# Prepare the priors ---------------------------------------------------------------------------------------------------------
for TissueType in gray white csf brain
do
	${FSLDIR}/bin/flirt \
	-in ${TISS_DIR}/avg152T1_${TissueType}.nii.gz \
	-ref ${TISS_DIR}/avg152T1_${TissueType}.nii.gz \
	-out ${TISS_DIR}/avg152T1_${TissueType}_${VoxRes}mm.nii.gz \
	-applyisoxfm ${VoxRes}

	echo "PRIORS: ${TissueType}"
	mri_convert --in_orientation $fromOr --out_orientation ${toOr} \
	${TISS_DIR}/avg152T1_${TissueType}_${VoxRes}mm.nii.gz ${TISS_DIR}/avg152T1_${TissueType}_${VoxRes}mm_${toOr}.nii.gz
done
