StudyID=$1
ImgTyp=$2 # Here we only use T13D and T12D

BEOP="antsXbe"

NUMJB=$3
SLURMSUBMIT=$4

# Later for the submitter file:
Mem=8G
Time="8-23:59:00"
DirSuffix="qc"
LT_DirSuffix="antsXbe"

#============================== FUNCTIONS ============
PROGNAME=$(basename $0)
error_exit()
{
        echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
        exit 1
}
#=====================================================

# Set the paths and read number of jobs to be submitted
#DataDir="/well/nvs-mri-temp/data/ms/processed/MetaData"

DataDir0="/rescompdata/ms/unprocessed/RESCOMP/MetaData"
DataDir=/home/bdivdi.local/dfgtyk/NVROXBOX/Data/RELAB
StudyDir="${DataDir}/${StudyID}"
ImgTypDir=${StudyDir}/${ImgTyp}
SubIDTxtFile=${DataDir0}/${StudyID}/${ImgTyp}/Sessions/${StudyID}_FullSessionSubID_${ImgTyp}.txt

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


ImgTypOp=${ImgTypDir}/${DirSuffix}
ImgTypOpLog=${ImgTypOp}/Logs.${DirSuffix}.${LT_DirSuffix}${BEOP}

rm -rf ${ImgTypOpLog}
mkdir -p ${ImgTypOpLog}

echo "The file is here: $ImgTypOpLog"

#############################################################################
#############################################################################

JobName=${StudyID}_${LT_DirSuffix}_${DirSuffix}${BEOP}_${NUMJB}
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
SubIDVar=\$(cat $SubIDTxtFile | sed -n \${ImgIDX}p)
SubID=\$(echo \$SubIDVar | awk -F"-" '{print \$2}')

sh /home/bdivdi.local/dfgtyk/NVROXBOX/SOURCE/qc/NVROX-QC-BE.sh ${StudyID} \${SubID} ${BEOP}

EOF
