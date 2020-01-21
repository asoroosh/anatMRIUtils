
set -e

SesMedNu2SSTIMG=$1
SSTTEMPLATES=$2
k=0

#SSSSTDIR=/rescompdata/ms/unprocessed/RESCOMP/CFTY720D2201/sub-CFTY720D2201x0004x00010/T12D.autorecon12ws.nuws_mrirobusttemplate
#SSTTEMPLATES=$SSSSTDIR/sub-CFTY720D2201x0004x00010_ants_temp_med_nutemplate0.nii.gz
#SesMedNu2SSTIMG=$SSSSTDIR/sub-CFTY720D2201x0004x00010_ses-V2x20040213_nu_2_median_nu.nii.gz

LT_OUTPUT_DIR=$(dirname $SSTTEMPLATES)

SSTIMGBASE=$(basename $SSTTEMPLATES template0.nii.gz)
MedIMAGEBASE=$(basename $SesMedNu2SSTIMG .nii.gz)

OUTWARPFN=${SSTIMGBASE}${MedIMAGEBASE}_reg2sst
OUTFN=${SSTIMGBASE}template0${MedIMAGEBASE}_reg2sst

echo $OUTWARPFN
echo $OUTFN

DEFORMED="${LT_OUTPUT_DIR}/${OUTFN}WarpedToTemplate.nii.gz"
OUTPUTTRANSFORMS="-t ${LT_OUTPUT_DIR}/${OUTWARPFN}1Warp.nii.gz -t ${LT_OUTPUT_DIR}/${OUTWARPFN}0GenericAffine.mat"
REPAIRED="${LT_OUTPUT_DIR}/${OUTFN}Repaired.nii.gz"

##
DIM=3
MAXITERATIONS=100x100x70x20
SMOOTHINGFACTORS=3x2x1x0
SHRINKFACTORS=6x4x2x1
TRANSFORMATION="SyN[ 0.1,3,0 ]"

IMAGEMETRICSET=" -m CC[ ${SSTTEMPLATES},${REPAIRED},1,4 ]"
IMAGEMETRICLINEARSET=" -m MI[ ${SSTTEMPLATES},${REPAIRED},1,32,Regular,0.25 ]"

basecall="antsRegistration -d ${DIM} --float 1 --verbose 1 -u 1 -w [ 0.01,0.99 ] -z 1 "
stage0="-r [ ${SSTTEMPLATES},${REPAIRED},1 ] "
stage1="-t Rigid[ 0.1 ] ${IMAGEMETRICLINEARSET} -c [ 1000x500x250x0,1e-6,10 ] -f 6x4x2x1 -s 4x2x1x0 "
stage2="-t Affine[ 0.1 ] ${IMAGEMETRICLINEARSET} -c [ 1000x500x250x0,1e-6,10 ] -f 6x4x2x1 -s 4x2x1x0 "
stage3="-t ${TRANSFORMATION} ${IMAGEMETRICSET} -c [ ${MAXITERATIONS},1e-9,10 ] -f ${SHRINKFACTORS} -s ${SMOOTHINGFACTORS} -o ${LT_OUTPUT_DIR}/${OUTWARPFN} "

### N4 BIAS CORRECTION ###
echo "--BIAS CORRECTION:"
echo "INPUT: ${SesMedNu2SSTIMG}"
echo "OUTPUT: ${REPAIRED}"
N4BiasFieldCorrection -d ${DIM} -b [ 200 ] -c [ 50x50x40x30,0.00000001 ] -i ${SesMedNu2SSTIMG} -o ${REPAIRED} -r 0 -s 2 --verbose 0

#echo "BIAS CORR == DONE =="

### REGISTRATION ###
echo "--REGISTRATION:"
echo "REFERENCE: ${SSTTEMPLATES}"
echo "MOVING: ${REPAIRED}"
echo "WARP FILES: ${LT_OUTPUT_DIR}/${OUTWARPFN}"
${basecall} ${stage0} ${stage1} ${stage2} ${stage3} >> reg2sst.log
#${basecall} ${stage0} ${stage2} ${stage3}
echo "REGISTRATION == DONE =="

### APPLY WARP ###
echo "--APPLY WARP: "
echo "REFERENCE: "
echo "MOVING: "
echo "TRANSFORMATION FILES: ${OUTPUTTRANSFORMS}"
echo "FINAL DEFORMED OUTPUT: ${DEFORMED}"
antsApplyTransforms -d ${DIM} --float 1 --verbose 1 -i ${REPAIRED} -o ${DEFORMED} -r ${SSTTEMPLATES} ${OUTPUTTRANSFORMS}

echo "APPLY WARP == DONE =="
