
StudyID=$1
SubID=$2
SesID=$3

BEOP=antsbe

#processed dir
PRSD_DIR=/data/XXXX

#unprocessed dir
UPRSD_DIR=/data/XXXX

InputImg=${UPRSD_DIR}/${StudyID}/sub-${SubID}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_run-1_T1w
OuputBrainMaskDir=${PRSD_DIR}/${StudyID}/sub-${SubID}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_run-1_T1w.$BEOP

mkdir -p $OuputBrainMaskDir

OuputBrainMaskImg=$OuputBrainMaskDir/sub-${SubID}_ses-${SesID}_run-1_T1w_${BEOP}

ml ANTs

OasisTemplates=${HOME}/NVROXBOX/AUX/Oasis

antsBrainExtraction.sh \
-d 3 \
-a ${InputImg}.nii.gz \
-e ${OasisTemplates}/T_template0.nii.gz \
-m ${OasisTemplates}/T_template0_BrainCerebellumProbabilityMask.nii.gz \
-o ${OuputBrainMaskImg}_


mv ${OuputBrainMaskImg}_BrainExtractionMask.nii.gz ${OuputBrainMaskImg}_BrainMask.nii.gz

echo "BrainMask: $OuputBrainMaskImg"
