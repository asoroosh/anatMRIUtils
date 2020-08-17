#!/bin/bash
#
# Soroosh Afyouni, University of Oxford, 2020
# soroosh.afyouni@bdi.ox.ac.uk
#ml ANTs

set -e

dothejob="yes"

SSTTEMPLATE=$1
STUDYTEMPLATES=$2

LT_OUTPUT_DIR=$(dirname $STUDYTEMPLATES)
LT_OUTPUT_DIR=$(dirname $SSTTEMPLATE)
LT_OUTPUT_DIR=${LT_OUTPUT_DIR}/reg2temp

#LT_OUTPUT_DIR=${SSTDir}/reg2temp

SSTIMGBASE=$(basename $STUDYTEMPLATES template.nii.gz)
MedIMAGEBASE=$(basename $SSTTEMPLATE .nii.gz)

OUTWARPFN=${MedIMAGEBASE}_reg2temp_
OUTFN=${MedIMAGEBASE}_reg2temp_

DEFORMED="${LT_OUTPUT_DIR}/${OUTFN}WarpedToTemplate.nii.gz"
OUTPUTTRANSFORMS="-t ${LT_OUTPUT_DIR}/${OUTWARPFN}1Warp.nii.gz -t ${LT_OUTPUT_DIR}/${OUTWARPFN}0GenericAffine.mat"
REPAIRED="${LT_OUTPUT_DIR}/${OUTFN}Repaired.nii.gz"

#echo "N4 Output: ${REPAIRED}"
#echo "DEFORMED OUTPUT: $DEFORMED"
#echo "TRANSFORMS: $OUTPUTTRANSFORMS"
#echo "BIAS CORRECTION FILE NAME: $REPAIRED"

if [ $dothejob == "yes" ]; then

mkdir -p ${LT_OUTPUT_DIR}

echo "-------REGISTRATION -- $(date):"
echo "REFERENCE: ${STUDYTEMPLATES}"
echo "MOVING: ${REPAIRED}"
echo "WARP FILES: ${LT_OUTPUT_DIR}/${OUTWARPFN}"

##
DIM=3
MAXITERATIONS=100x100x70x20
SMOOTHINGFACTORS=3x2x1x0
SHRINKFACTORS=6x4x2x1
TRANSFORMATION="SyN[ 0.1,3,0 ]"

IMAGEMETRICSET=" -m CC[ ${STUDYTEMPLATES},${REPAIRED},1,4 ]"
IMAGEMETRICLINEARSET=" -m MI[ ${STUDYTEMPLATES},${REPAIRED},1,32,Regular,0.25 ]"

basecall="antsRegistration -d ${DIM} --float 1 --verbose 1 -u 1 -w [ 0.01,0.99 ] -z 1 "
stage0="-r [ ${STUDYTEMPLATES},${REPAIRED},1 ] "
stage1="-t Rigid[ 0.1 ] ${IMAGEMETRICLINEARSET} -c [ 1000x500x250x0,1e-6,10 ] -f 6x4x2x1 -s 4x2x1x0 "
stage2="-t Affine[ 0.1 ] ${IMAGEMETRICLINEARSET} -c [ 1000x500x250x0,1e-6,10 ] -f 6x4x2x1 -s 4x2x1x0 "
stage3="-t ${TRANSFORMATION} ${IMAGEMETRICSET} -c [ ${MAXITERATIONS},1e-9,10 ] -f ${SHRINKFACTORS} -s ${SMOOTHINGFACTORS} -o ${LT_OUTPUT_DIR}/${OUTWARPFN} "

### N4 BIAS CORRECTION ###
N4BiasFieldCorrection -d ${DIM} -b [ 200 ] -c [ 50x50x40x30,0.00000001 ] -i ${SSTTEMPLATE} -o ${REPAIRED} -r 0 -s 2 --verbose 1 >> ${LT_OUTPUT_DIR}/reg2temp.log

echo "BIAS CORR == DONE ==" >> ${LT_OUTPUT_DIR}/reg2temp.log

### REGISTRATION ###
${basecall} ${stage0} ${stage1} ${stage2} ${stage3} >> ${LT_OUTPUT_DIR}/reg2temp.log
#${basecall} ${stage0} ${stage2} ${stage3}
echo "REGISTRATION == DONE ==" >> ${LT_OUTPUT_DIR}/reg2temp.log

### APPLY WARP ###
antsApplyTransforms -d ${DIM} --float 1 --verbose 1 -i ${REPAIRED} -o ${DEFORMED} -r ${STUDYTEMPLATES} ${OUTPUTTRANSFORMS}

echo "APPLY WARP == DONE ==" >> ${LT_OUTPUT_DIR}/reg2temp.log

fi
