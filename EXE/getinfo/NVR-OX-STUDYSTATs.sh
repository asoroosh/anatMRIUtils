
# FUNCTIONS

checkNget () {
## Get a wildcard, check whether it exists and return the number of files under that wildcard
if ls $1 1> /dev/null 2>&1
then
        ls $1 | wc -l
else
	echo 0
fi
}

##########

StudyID=CFTY720D2309

echo ""
echo ""
echo "******** STUDY ID: ${StudyID} ******"

# Make a new directory
DataDir="${HOME}/NVROXBOX/Data"
StudyDir="${DataDir}/${StudyID}"
mkdir -p ${StudyDir}

BasicStudyInfoTxt=${StudyDir}/${StudyID}_BasicStudyInfoTxt.txt
rm -f $BasicStudyInfoTxt

# Number of subjects:
NUMSUB=`ls /data/output/habib/unprocessed/${StudyID}.anon.2019.07.15 | wc -l`
echo "==Number of Subjects: ${NUMSUB}"
echo SUB ${NUMSUB} >> $BasicStudyInfoTxt

#PD
PD_Dir="/data/output/habib/unprocessed/${StudyID}.anon.2019.07.15/sub-${StudyID}.*.*/*/anat/sub-*.*.*_ses-V*[0-9]_run-[0-9]_PD.nii.gz"
NUMPD=`checkNget ${PD_Dir}"`
echo PD2D ${NUMPD} >> $BasicStudyInfoTxt

#T1w - 2D
T12D_Dir="/data/output/habib/unprocessed/${StudyID}.anon.2019.07.15/sub-${StudyID}.*.*/*/anat/sub-*.*.*_ses-V*[0-9]_run-[0-9]_T1w.nii.gz"
NUMT12D=`checkNget ${T12D_Dir}"`
echo T12D ${NUMT12D} >> $BasicStudyInfoTxt

#T1w - 3D
NUMT13D=`checkNget "/data/output/habib/unprocessed/${StudyID}.anon.2019.07.15/sub-${StudyID}.*.*/*/anat/sub-*.*.*_ses-V*[0-9]_acq-3d_run-[0-9]_T1w.nii.gz"`
echo T13D ${NUMT13D} >> $BasicStudyInfoTxt

#T1w - 2D - CE Gd
NUMT12DCE=`checkNget "/data/output/habib/unprocessed/${StudyID}.anon.2019.07.15/sub-${StudyID}.*.*/*/anat/sub-*.*.*_ses-V*[0-9]_ce-Gd_run-[0-9]_T1w.nii.gz"`
echo CEGd ${NUMT12DCE} >> $BasicStudyInfoTxt

#T2w
NUMT22D=`checkNget "/data/output/habib/unprocessed/${StudyID}.anon.2019.07.15/sub-${StudyID}.*.*/*/anat/sub-*.*.*_ses-V*[0-9]_run-[0-9]_T2w.nii.gz"`
echo T22D ${NUMT22D} >> $BasicStudyInfoTxt

#DWI # I should later check the bval and bvec images
NUMDWI=`checkNget "/data/output/habib/unprocessed/${StudyID}.anon.2019.07.15/sub-${StudyID}.*.*/*/dwi/sub-*.*.*_ses-V*[0-9]_run-[0-9]_dwi.nii.gz"`
NUMBVEC=`checkNget "/data/output/habib/unprocessed/${StudyID}.anon.2019.07.15/sub-${StudyID}.*.*/*/dwi/sub-*.*.*_ses-V*[0-9]_run-[0-9]_dwi.bvec"`
NUMBVAL=`checkNget "/data/output/habib/unprocessed/${StudyID}.anon.2019.07.15/sub-${StudyID}.*.*/*/dwi/sub-*.*.*_ses-V*[0-9]_run-[0-9]_dwi.bval"`

echo DWI ${NUMDWI} >> $BasicStudyInfoTxt
echo "DWI: ${NUMDWI} ( Bvec: ${NUMBVEC} , Bvals: ${NUMBVAL})"

#fmap
############## FIELD MAPS ##############
############## TMReferences ##############

###########


