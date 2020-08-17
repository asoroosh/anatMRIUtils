#!/bin/bash
#
#

ml ANTs

set -e

dothejob="yes"

STUDYTEMPLATES=$1

ORTAG=LIA
VOXRES=1
MyHOME=$HOME
AUXTEMPLATEDIR=${MyHOME}/NVROXBOX/AUX/MNItemplates
MNITEMPLATE=${AUXTEMPLATEDIR}/${ORTAG}/MNI152_T1_${VOXRES}mm_${ORTAG}.nii.gz

#LT_OUTPUT_DIR=$(dirname $STUDYTEMPLATES)
LT_OUTPUT_DIR=$(dirname $STUDYTEMPLATES)
LT_OUTPUT_DIR=${LT_OUTPUT_DIR}/reg2mni

SSTIMGBASE=$(basename $STUDYTEMPLATES template.nii.gz)
MedIMAGEBASE=$(basename $STUDYTEMPLATES .nii.gz)

OUTWARPFN=${MedIMAGEBASE}_reg2mni_
OUTFN=${MedIMAGEBASE}_reg2mni_

#echo $LT_OUTPUT_DIR
#echo $OUTWARPFN
#echo $OUTFN

DEFORMED="${LT_OUTPUT_DIR}/${OUTFN}WarpedToTemplate.nii.gz"
OUTPUTTRANSFORMS="-t ${LT_OUTPUT_DIR}/${OUTWARPFN}1Warp.nii.gz -t ${LT_OUTPUT_DIR}/${OUTWARPFN}0GenericAffine.mat"
REPAIRED="${LT_OUTPUT_DIR}/${OUTFN}Repaired.nii.gz"

echo "DEFORMED OUTPUT: $DEFORMED"
echo "TRANSFORMS: $OUTPUTTRANSFORMS"
echo "BIAS CORRECTION FILE NAME: $REPAIRED"

if [ $dothejob == "yes" ]; then

mkdir -p ${LT_OUTPUT_DIR}

##
DIM=3
MAXITERATIONS=100x100x70x20
SMOOTHINGFACTORS=3x2x1x0
SHRINKFACTORS=6x4x2x1
TRANSFORMATION="SyN[ 0.1,3,0 ]"

IMAGEMETRICSET=" -m CC[ ${MNITEMPLATE},${REPAIRED},1,4 ]"
IMAGEMETRICLINEARSET=" -m MI[ ${MNITEMPLATE},${REPAIRED},1,32,Regular,0.25 ]"

basecall="antsRegistration -d ${DIM} --float 1 --verbose 1 -u 1 -w [ 0.01,0.99 ] -z 1 "
stage0="-r [ ${MNITEMPLATE},${REPAIRED},1 ] "
stage1="-t Rigid[ 0.1 ] ${IMAGEMETRICLINEARSET} -c [ 1000x500x250x0,1e-6,10 ] -f 6x4x2x1 -s 4x2x1x0 "
stage2="-t Affine[ 0.1 ] ${IMAGEMETRICLINEARSET} -c [ 1000x500x250x0,1e-6,10 ] -f 6x4x2x1 -s 4x2x1x0 "
stage3="-t ${TRANSFORMATION} ${IMAGEMETRICSET} -c [ ${MAXITERATIONS},1e-9,10 ] -f ${SHRINKFACTORS} -s ${SMOOTHINGFACTORS} -o ${LT_OUTPUT_DIR}/${OUTWARPFN} "

### N4 BIAS CORRECTION ###
echo "--BIAS CORRECTION:"
echo "INPUT: ${STUDYTEMPLATES}"
echo "OUTPUT: ${REPAIRED}"
N4BiasFieldCorrection -d ${DIM} -b [ 200 ] -c [ 50x50x40x30,0.00000001 ] -i ${STUDYTEMPLATES} -o ${REPAIRED} -r 0 -s 2 --verbose 1 >> ${LT_OUTPUT_DIR}/reg2mni.log

echo "BIAS CORR == DONE ==" >> ${LT_OUTPUT_DIR}/reg2mni.log

### REGISTRATION ###
echo "--REGISTRATION:"
echo "REFERENCE: ${MNITEMPLATE}"
echo "MOVING: ${REPAIRED}"
echo "WARP FILES: ${LT_OUTPUT_DIR}/${OUTWARPFN}"
${basecall} ${stage0} ${stage1} ${stage2} ${stage3} >> ${LT_OUTPUT_DIR}/reg2mni.log
#${basecall} ${stage0} ${stage2} ${stage3}
echo "REGISTRATION == DONE ==" >> ${LT_OUTPUT_DIR}/reg2mni.log

### APPLY WARP ###
echo "--APPLY WARP: "
echo "TRANSFORMATION FILES: ${OUTPUTTRANSFORMS}"
echo "FINAL DEFORMED OUTPUT: ${DEFORMED}"
antsApplyTransforms -d ${DIM} --float 1 --verbose 1 -i ${REPAIRED} -o ${DEFORMED} -r ${MNITEMPLATE} ${OUTPUTTRANSFORMS}

echo "APPLY WARP == DONE ==" >> ${LT_OUTPUT_DIR}/reg2mni.log

fi
