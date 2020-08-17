
StudyID=$1
SubID=$2
SesID=$3

BEOP=antsXbe

BExtPath=${HOME}/NVROXBOX/SOURCE/be/BrainExtraction

#processed dir
PRSD_DIR=/data/XXXXXX

#unprocessed dir
UPRSD_DIR=/data/XXXXX

InputImg=${UPRSD_DIR}/${StudyID}/sub-${SubID}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_run-1_T1w
OuputBrainMaskDir=${PRSD_DIR}/${StudyID}/sub-${SubID}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_run-1_T1w.$BEOP

mkdir -p $OuputBrainMaskDir

OuputBrainMaskImgProb=$OuputBrainMaskDir/sub-${SubID}_ses-${SesID}_run-1_T1w_${BEOP}_BrainMaskProb
OuputBrainMaskImg=$OuputBrainMaskDir/sub-${SubID}_ses-${SesID}_run-1_T1w_${BEOP}_BrainMask

ml Python
ml ANTs

singularity run \
-B ${PRSD_DIR}/${StudyID},${UPRSD_DIR}/${StudyID},${HOME}/NVROXBOX/SOURCE/be \
/apps/software/containers/antspynet-0.0.3.sif \
${BExtPath}/Scripts/doBrainExtraction.py ${InputImg}.nii.gz ${OuputBrainMaskImg}.nii.gz \
${BExtPath}/Data/Template/S_template3_resampled.nii.gz

${FSLDIR}/bin/fslmaths ${OuputBrainMaskImgProb}.nii.gz -thr 0.01 -bin ${OuputBrainMaskImg}.nii.gz


echo "BrainMask: $OuputBrainMaskImg"
