#This should later be in a loop around StudyIDs
StudyID=$1
ImgTyp=$2 # Here we only use T13D and T12D

# NUMJB sets the number of **SUBJECTS** that will be run for this specific operation
# If you want to run the operation on all available SUBJECTS, leave NUMJB empty
NUMJB=$3
SLURMSUBMIT=$4

# Later for the submitter file:
Mem=8G
Time="2-23:59:00"
DirSuffix="betsreg"
LT_DirSuffix="fast-fixed"

#NVSHOME=/well/nvs-mri-temp/users/scf915
#NVSHOME=${HOME}/NVROXBOX/SOURCE/

SRC_DIR="${HOME}/NVROXBOX/SOURCE"
SRC_REG_DIR="${SRC_DIR}/reg"
SRC_SEG_DIR="${SRC_DIR}/seg"

#ProcessedDir="/well/nvs-mri-temp/data/ms/processed"
ProcessedDir="/rescompdata/ms/unprocessed/RESCOMP"

#============================== FUNCTIONS ============
PROGNAME=$(basename $0)
error_exit()
{
	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	exit 1
}
#=====================================================
# Set the paths and read number of jobs to be submitted
DataDir0="$HOME/NVROXBOX/Data/RELAB"
DataDir="/rescompdata/ms/unprocessed/RESCOMP/MetaData"
StudyDir="${DataDir}/${StudyID}"
ImgTypDir=${StudyDir}/${ImgTyp}

SubIDTxtFile=${ImgTypDir}/Sessions/${StudyID}_FullSessionSubID_${ImgTyp}.txt

if [ ! -f $SubIDTxtFile ]; then
	echo $SubIDTxtFile
	error_exit "***** ERROR $LINENO: The file list for study ${StudyID}, Image type: ${ImgTyp} does not exists."
fi

if [ -z $NUMJB ]
then
        NUMJB=$(cat $SubIDTxtFile | wc -l)
else
        NUMJB_tmp=$(cat $SubIDTxtFile | wc -l)
        NUMJBList_tmp=($NUMJB $NUMJB_tmp)
        IFS=$'\n'
        NUMJB=$(echo "${NUMJBList_tmp[*]}" | sort -n | head -n1)
fi

echo "We will shortly submit $NUMJB jobs..."

#========================================

DATE=$(date +"%d-%m-%y")

ImgTypOp=${ImgTypDir}/${DirSuffix}
ImgTypOpLog=${ImgTypOp}/Logs_${DirSuffix}.${LT_DirSuffix}
mkdir -p ${ImgTypOpLog}

echo "Check this: ${ImgTypOpLog}"

#############################################################################
#############################################################################

JobName=${StudyID}_${LT_DirSuffix}_${DirSuffix}_${NUMJB}
SubmitterFileName="${ImgTypOp}/SubmitMe_${JobName}.sh"

cat > $SubmitterFileName << EOF
#!/bin/bash
#SBATCH --partition=main
#SBATCH --job-name=${JobName}
#SBATCH --mem=${Mem}
#SBATCH --time=${Time}
#SBATCH --output=${ImgTypOpLog}/${JobName}_%A_%a.out
#SBATCH --error=${ImgTypOpLog}/${JobName}_%A_%a.err
#SBATCH --array=1-${NUMJB}

set -e

# Read the input path
ImgIDX=\$SLURM_ARRAY_TASK_ID
SubID=\$(cat $SubIDTxtFile | sed -n \${ImgIDX}p)

# Set the job status to zero here. If the operation reaches the bottom without error, then the status will be changed to 1
echo "${StudyID}_\${SubID}: 0" > ${ImgTypOpLog}/${JobName}_\${SLURM_ARRAY_JOB_ID}_\${SLURM_ARRAY_TASK_ID}.stat

# ========================================================================
SessionsDir=${DataDir}/${StudyID}/${ImgTyp}/Sessions
SessionTxtFile=\${SessionsDir}/${StudyID}_\${SubID}_${ImgTyp}.txt

if [ ! -f \$SessionTxtFile ]; then
	echo "***** ERROR $LINENO: The session file \${SessionTxtFile} does not exists for this subject: \${SubID}, ${ImgTyp}"
	exit 1
fi

#--form the session image lists -----
SesIDList=""
SesIDVarList=""

while read SessionFileName
do
	# Where do you want to get your data from? e.g. ANTs?
	StudyIDVar=\$(echo \$SessionFileName | awk -F"/" '{print \$7}') # Study ID

	SubIDVar=\$(echo \$SessionFileName | awk -F"/" '{print \$8}') # Sub ID
	SubID=\$(echo \$SubIDVar | awk -F"-" '{print \$2}') # Sub ID

	SesIDVar=\$(echo \$SessionFileName | awk -F"/" '{print \$9}') # Session ID
	SesID=\$(echo \$SesIDVar | awk -F"-" '{print \$2}') # Get the Session IDs with out the prepend

	ModIDVar=\$(echo \$SessionFileName | awk -F"/" '{print \$10}') #Modality type: anat, dwi etc

	ImgNameEx=\$(echo \$SessionFileName | awk -F"/" '{print \$11}') #ImageName with extension
	ImgName=\$(basename \$ImgNameEx .nii.gz) # ImageName without extension

	echo "==== On session: \${StudyIDVar}, \${SubIDVar}, \${SesIDVar}, \${SesID}"

	SesIDList="\${SesIDList} \${SesID}"
	SesIDVarList="\${SesIDVarList} \${SesIDVar}"

done<\${SessionTxtFile}

SesIDVarList_arr=(\$SesIDVarList)
SesIDList=(\$SesIDList)

NumSes=\$(cat \${SessionTxtFile} | wc -l)

echo "\$NumSes"

# INPUT & OUTPUT functions =================================================
###### Write me down a report:
echo "==="
echo "Subject: \$SubIDVar"
echo "Image Type: ${ImgTyp}"
echo "Number of available sessions: \$NumSes"
echo "==="
echo ""
echo ""
echo "==========================================="
echo "STARTS @" \`date\`
echo "==========================================="
echo ""
echo ""
#############################################################################
#############################################################################

#--------------------------------------------------
#--------------------------------------------------
# Run the Segmentation on rawavg #-----------------
#--------------------------------------------------
#--------------------------------------------------
echo ""

for Ses_cnt in \$(seq 0 \$((\$NumSes-1)))
do

	SesID=\${SesIDList[\$Ses_cnt]}

	echo "Running segmentation -- FAST and ATROPOS -- on the each sessions:"
	echo "We are on session ${StudyID} \${SubID} \${SesID} "

	sh ${SRC_SEG_DIR}/brainseg_fast_rawavg.sh ${StudyID} \${SubID} \${SesID}
done


#--------------------------------------------------
#--------------------------------------------------
# Run Segmentation on NonLinear SST----------------
#--------------------------------------------------
#--------------------------------------------------

#echo "SEGMENTATION ON NONLIN SST: ${StudyID} \${SubID}"
#sh ${SRC_SEG_DIR}/brainseg_atropos_nonlinsst.sh ${StudyID} \${SubID}

#############################################################################
#############################################################################
echo ""
echo "${StudyID}_\${SubID}: 1" > ${ImgTypOpLog}/${JobName}_\${SLURM_ARRAY_JOB_ID}_\${SLURM_ARRAY_TASK_ID}.stat

### ### ### ### ### ###

echo ""
echo ""
echo "==========================================="
echo "ENDS @" \`date\`
echo "==========================================="
echo ""
echo ""

EOF

if [ ! -z $SLURMSUBMIT ]; then
	echo "I am actually gonna submit them to the queue now!"
	sbatch ${SubmitterFileName}
fi
