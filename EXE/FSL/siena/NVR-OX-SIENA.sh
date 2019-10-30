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
DirSuffix="siena"

SRC_DIR="${HOME}/NVROXBOX/SOURCE"
SRC_SIENA=${SRC_DIR}/siena

#============================== FUNCTIONS ============
PROGNAME=$(basename $0)
error_exit()
{
	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	exit 1
}
#=====================================================

# Path to the source files (i.e. editted functions for each operation ~/NVROXBOX/SOURCE/*)
SOURCEPATH=${HOME}/NVROXBOX/SOURCE/

# Set the paths and read number of jobs to be submitted
DataDir="${HOME}/NVROXBOX/Data/RELAB"
StudyDir="${DataDir}/${StudyID}"
ImgTypDir=${StudyDir}/${ImgTyp}
SubIDTxtFile=${ImgTypDir}/Sessions/${StudyID}_FullSessionSubID_${ImgTyp}.txt

if [ ! -f $SubIDTxtFile ]; then
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

#
if [ $ImgTyp == T13D ] ; then
	Arg_ImageType=T1
	Arg_command=""
elif [ $ImgTyp == T12D ] ; then
	Arg_ImageType=T1
elif [ $ImgTyp == PD2D ] ; then
	Arg_ImageType=PD
	Arg_command=""
elif [ $ImgTyp == T22D ] ; then
	Arg_ImageType=T2
	Arg_command=""
elif [ $ImgTyp == T12DCE ]; then
        Arg_ImageType=
        Arg_command=""
else
	# throw an error and halt here
	error_exit "***** ERROR $LINENO: Unknown image type..."
fi
#========================================

DATE=$(date +"%d-%m-%y")

ImgTypOp=${ImgTypDir}/${DirSuffix}
ImgTypOpLog=${ImgTypOp}/Logs.${DirSuffix}
mkdir -p ${ImgTypOpLog}

#############################################################################
#############################################################################

JobName=${StudyID}_${DirSuffix}_${NUMJB}
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

# INPUT & OUTPUT functions =================================================
###### Write me down a report:
echo ""
echo ""
echo "==========================================="
echo "STARTS @" \`date\`
echo "==========================================="
echo ""
echo ""
#############################################################################
#############################################################################

# Load packages and software here
ml ANTs

SubIDVar=\$(echo \$SubID | awk -F"-" '{print \$2}')

echo "==========================================="
echo "==== RUNING SIENA - TARGET 2 BASELINE "
echo "On Study ${StudyID}, Subject: \${SubIDVar}"
echo "==========================================="
echo "==========================================="

${SRC_SIENA}/siena_tobaseline.sh ${StudyID} \${SubIDVar}

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
