#This should later be in a loop around StudyIDs
#StudyID=CFTY720D2309
#ImgTyp=T12D # Here we only use T13D and T12D

StudyID=$1
ImgTyp=$2

# NUMJB sets the number of images that will be run for this specific operation
# If you want to run the operation on all available images, leave NUMJB empty
NUMJB=$3

# Later for the submitter file:
Mem=8G
Time="23:59:00"
DirSuffix="cat12"

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
DataDir="${HOME}/NVROXBOX/Data"
StudyDir="${DataDir}/${StudyID}"
ImgTypDir=${StudyDir}/${ImgTyp}
ImageFileTxt=${ImgTypDir}/${StudyID}_${ImgTyp}_ImageList.txt

if [ ! -f $ImageFileTxt ]; then
	error_exit "***** ERROR $LINENO: The file list for study ${StudyID}, Image type: ${ImgTyp} does not exists."
fi

if [ -z $NUMJB ]
then
	NUMJB=$(cat $ImageFileTxt | wc -l)
else
	NUMJB_tmp=$(cat $ImageFileTxt | wc -l)
	NUMJBList_tmp=($NUMJB $NUMJB_tmp)
	IFS=$'\n'
	NUMJB=$(echo "${NUMJBList_tmp[*]}" | sort -n | head -n1)
fi

echo "We will shortly submit $NUMJB jobs..."


#========================================
# Depending on the image type, we can parse args down to the operation
# Just FYI
#PD_WC="sub-*.*.*_ses-V*[0-9]_run-[0-9]_PD.nii.gz"
#T12D_WC="sub-*.*.*_ses-V*[0-9]_run-[0-9]_T1w.nii.gz"
#T13D_WC="sub-*.*.*_ses-V*[0-9]_acq-3d_run-[0-9]_T1w.nii.gz"
#T12DCE_WC="sub-*.*.*_ses-V*[0-9]_ce-Gd_run-[0-9]_T1w.nii.gz"
#T22D_WC="sub-*.*.*_ses-V*[0-9]_run-[0-9]_T2w.nii.gz"
#DWI_WC="sub-*.*.*_ses-V*[0-9]_run-[0-9]_dwi.nii.gz"
#BVEC_WC="sub-*.*.*_ses-V*[0-9]_run-[0-9]_dwi.bvec"
#BVAL_WC="sub-*.*.*_ses-V*[0-9]_run-[0-9]_dwi.bval"

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
ImgTypOpLog=${ImgTypOp}/Logs_${DATE}
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
InputImagePath=\$(cat $ImageFileTxt | sed -n \${ImgIDX}p)

# INPUT & OUTPUT functions =================================================
StudyIDVar=\$(echo \$InputImagePath | awk -F"/" '{print \$6}') # Study ID
SubIDVar=\$(echo \$InputImagePath | awk -F"/" '{print \$7}') # Sub ID
SesIDVar=\$(echo \$InputImagePath | awk -F"/" '{print \$8}') # Session ID
ModIDVar=\$(echo \$InputImagePath | awk -F"/" '{print \$9}') #Modality type: anat, dwi etc
ImgNameEx=\$(echo \$InputImagePath | awk -F"/" '{print \$10}') #ImageName with extension
ImgName=\$(basename \$ImgNameEx .nii.gz) # ImageName without extension

# Set the job status to zero here. If the operation reaches the bottom without error, then the status will be changed to 1
echo "\${InputImagePath}: 0" > ${ImgTypOpLog}/${JobName}_\${SLURM_ARRAY_JOB_ID}_\${SLURM_ARRAY_TASK_ID}.stat

# Reconstruct the output directory name
ProcessedDir="/data/ms/processed/mri"
OutputDir=\${ProcessedDir}/\${StudyIDVar}/\${SubIDVar}/\${SesIDVar}/\${ModIDVar}/\${ImgName}.${DirSuffix}

rm -rf \${OutputDir}
mkdir -p \${OutputDir}

###### Write me down a report:
echo "Input Image: \${InputImagePath}"
echo "==="
echo "Subject: \$SubIDVar"
echo "Session: \$SesIDVar"
echo "ImageName: \$ImgNameEx"
echo "Image Type: ${ImgTyp}"
echo "==="
echo "Output Directory: \${OutputDir}"

echo "==========================================="
echo "STARTS @" \`date\`
echo "==========================================="

#############################################################################
#############################################################################

# Load packages and software here
ml MATLAB

# a bit of preprocessing
cp \${InputImagePath} \${OutputDir}/\${ImgName}.nii.gz
gunzip -d \${OutputDir}/\${ImgName}.nii.gz
cd \${OutputDir}

# run cat 12
${HOME}/AUX/spm12/toolbox/cat12/cat_batch_cat.sh \${ImgName}.nii

#############################################################################
#############################################################################

echo "\${InputImagePath}: 1" > ${ImgTypOpLog}/${JobName}_\${SLURM_ARRAY_JOB_ID}_\${SLURM_ARRAY_TASK_ID}.stat

### ### ### ### ### ###

echo "==========================================="
echo "ENDS @" \`date\`
echo "==========================================="

EOF


