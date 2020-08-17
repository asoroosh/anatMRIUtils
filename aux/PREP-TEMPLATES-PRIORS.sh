#!/bin/bash

# Given the warp files, take the prior into study template
#
# Soroosh Afyouni, University of Oxford, 2020

set -e

ml ANTs

StudyID=$1

VoxRes=1

AUXDIR=${HOME}/NVROXBOX/AUX
ATLASDIR=${AUXDIR}/atlas/GMatlas/LIA
MASKDIR=${AUXDIR}/MNItemplates/LIA
TISSUEPDIR=${AUXDIR}/tissuepriors/LIA

TEMPLATEDIR=${AUXDIR}/STUDTEMP/${StudyID}_50_RNDSST

TEMPLATEPRIORDIR=${TEMPLATEDIR}/tissuepriors
TEMPLATEATLAS=${TEMPLATEDIR}/atlas
TEMPLATEMASK=${TEMPLATEDIR}/masks

mkdir -p ${TEMPLATEATLAS}
mkdir -p ${TEMPLATEPRIORDIR}
mkdir -p ${TEMPLATEATLAS}
mkdir -p ${TEMPLATEMASK}

TEMPLATEIMAG=${TEMPLATEDIR}/${StudyID}template.nii.gz

MNI2TEMPWARP=${TEMPLATEDIR}/antscorticalthickness/reg2mni/ExtractedBrain0N4_reg2mni_${VoxRes}mm_brain_1Warp.nii.gz
MNI2TEMPINVWARP=${TEMPLATEDIR}/antscorticalthickness/reg2mni/ExtractedBrain0N4_reg2mni_${VoxRes}mm_brain_1InverseWarp.nii.gz
MNI2TEMPAFFINE=${TEMPLATEDIR}/antscorticalthickness/reg2mni/ExtractedBrain0N4_reg2mni_${VoxRes}mm_brain_0GenericAffine.mat

# DO THE PRIORS ----------------------------------------------
for tt in gray csf white brain; do

echo "doing ${tt}..."

antsApplyTransforms -d 3 \
	-i ${TISSUEPDIR}/avg152T1_${tt}_${VoxRes}mm_LIA.nii.gz \
	-r ${TEMPLATEIMAG} \
	-t [${MNI2TEMPAFFINE}, 1] \
	-t ${MNI2TEMPINVWARP} \
	-o ${TEMPLATEPRIORDIR}/${StudyID}_avg152T1_${tt}_${VoxRes}mm_LIA.nii.gz
done


# DO THE MASKS ----------------------------------------------
echo "Doing the masks now..."

MNI152strucseg=${MASKDIR}/MNI152_T1_${VoxRes}mm_strucseg_LIA.nii.gz
STUDYstrucseg=${TEMPLATEMASK}/${StudyID}_T1_${VoxRes}mm_strucseg_LIA

antsApplyTransforms -d 3 \
        -i ${MNI152strucseg} \
        -r ${TEMPLATEIMAG} \
        -n NearestNeighbor \
        -t [${MNI2TEMPAFFINE}, 1] \
        -t ${MNI2TEMPINVWARP} \
        -o ${STUDYstrucseg}.nii.gz

fslmaths ${STUDYstrucseg}.nii.gz -thr 2.5 -uthr 3.5 ${STUDYstrucseg}_Cereb.nii.gz
fslmaths ${STUDYstrucseg}.nii.gz -sub ${STUDYstrucseg}_Cereb.nii.gz ${STUDYstrucseg}_NoCereb.nii.gz
fslmaths ${STUDYstrucseg}_NoCereb.nii.gz -bin ${STUDYstrucseg}_NoCereb_bin.nii.gz

# Chop out the Ventricals ----------------------------------------------------------------------------------------------------
${FSLDIR}/bin/fslmaths ${STUDYstrucseg}.nii.gz -thr 4.5 -bin ${STUDYstrucseg}_Vent.nii.gz

# Prepare Seg Periph [sic] -- this is the brain without the cereb and subcot -------------------------------------------------
MNI152structsepriph=${MASKDIR}/MNI152_T1_${VoxRes}mm_strucseg_periph_LIA.nii.gz
STUDYstrucsegpriph=${TEMPLATEMASK}/${StudyID}_T1_${VoxRes}mm_strucseg_periph_LIA

antsApplyTransforms -d 3 \
	-i ${MNI152structsepriph} \
	-r ${TEMPLATEIMAG} \
	-n NearestNeighbor \
	-t [${MNI2TEMPAFFINE}, 1] \
	-t ${MNI2TEMPINVWARP} \
	-o ${STUDYstrucsegpriph}.nii.gz

# DO THE ATLAS ----------------------------------------------
echo "Doing the atlas now..."
antsApplyTransforms -d 3 \
	-i ${ATLASDIR}/GMatlas_${VoxRes}mm_LIA.nii.gz \
	-r ${TEMPLATEIMAG} \
	-n NearestNeighbor \
	-t [${MNI2TEMPAFFINE}, 1] \
	-t ${MNI2TEMPINVWARP} \
	-o ${TEMPLATEATLAS}/${StudyID}_GMatlas_${VoxRes}mm_LIA.nii.gz
