ml ANTs

OasisTemplates=${HOME}/NVROXBOX/AUX/Oasis

StudyID_Date=$1
SubID=$2

StudyID=$(echo ${StudyID_Date} | awk -F"." '{print $1}')
NonLinTempImgName=sub-${SubID}_ants_temp_med_nutemplate0

echo "=======================================" 
echo "STARTED @" $(date)
echo "=======================================" 

echo "=======================================" 
echo "** StudyID: ${StudyID}, SubID: ${SubID}" 
echo "=======================================" 

ImgTyp=T12D
XSectionalDirSuffix=autorecon12ws
LogitudinalDirSuffix=nuws_mrirobusttemplate
PRSD_DIR="/data/ms/processed/mri"
PRSD_SUBDIR=${PRSD_DIR}/${StudyID_Date}/sub-${SubID}
SST_Dir=${PRSD_SUBDIR}/${ImgTyp}.${XSectionalDirSuffix}.${LogitudinalDirSuffix}

NonLinSSTDirImg=${SST_Dir}/${NonLinTempImgName}

antsBrainExtraction.sh \
-d 3 \
-a ${NonLinSSTDirImg}.nii.gz \
-e ${OasisTemplates}/T_template0.nii.gz \
-k 1 \
-m ${OasisTemplates}/T_template0_BrainCerebellumProbabilityMask.nii.gz \
-o ${NonLinSSTDirImg}_Brain_ABE

echo "======================================="
echo "ENDED @" $(date)
echo "======================================="
