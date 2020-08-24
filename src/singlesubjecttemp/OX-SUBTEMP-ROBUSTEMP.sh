# /bin/bash
# Soroosh Afyouni, University of Oxford, 2020

#This should later be in a loop around StudyIDs
StudyID=$1
ImgTyp=$2 # Here we only use T13D and T12D

#StudyID=$1
#ImgTyp=$2

# NUMJB sets the number of **SUBJECTS** that will be run for this specific operation
# If you want to run the operation on all available SUBJECTS, leave NUMJB empty
NUMJB=$3
SLURMSUBMIT=$4

# Later for the submitter file:
Mem=8G
Time="2-23:59:00"
DirSuffix="autorecon12ws"
LT_DirSuffix="nuws_mrirobusttemplate"

ProcessedDir="/XXXX/XXXX/XXX/XXX"
#============================== FUNCTIONS ============
PROGNAME=$(basename $0)
error_exit()
{
	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	exit 1
}
#=====================================================

# Path to the source files (i.e. editted functions for each operation ~/NVROXBOX/SOURCE/*)
SOURCEPATH=${HOME}/NVROXBOX/src/

# Set the paths and read number of jobs to be submitted
DataDir="${HOME}/NVROXBOX/Data"
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

#========================================
# Depending on the image type, we can parse args down to the operation
# Just FYI
# PD_WC="sub-*.*.*_ses-V*[0-9]_run-[0-9]_PD.nii.gz"
# T12D_WC="sub-*.*.*_ses-V*[0-9]_run-[0-9]_T1w.nii.gz"
# T13D_WC="sub-*.*.*_ses-V*[0-9]_acq-3d_run-[0-9]_T1w.nii.gz"
# T12DCE_WC="sub-*.*.*_ses-V*[0-9]_ce-Gd_run-[0-9]_T1w.nii.gz"
# T22D_WC="sub-*.*.*_ses-V*[0-9]_run-[0-9]_T2w.nii.gz"
# DWI_WC="sub-*.*.*_ses-V*[0-9]_run-[0-9]_dwi.nii.gz"
# BVEC_WC="sub-*.*.*_ses-V*[0-9]_run-[0-9]_dwi.bvec"
# BVAL_WC="sub-*.*.*_ses-V*[0-9]_run-[0-9]_dwi.bval"

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
ImgTypOpLog=${ImgTypOp}/Logs_${DirSuffix}.${LT_DirSuffix}
mkdir -p ${ImgTypOpLog}

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
SessionsDir=\${HOME}/NVROXBOX/Data/${StudyID}/${ImgTyp}/Sessions
SessionTxtFile=\${SessionsDir}/${StudyID}_\${SubID}_${ImgTyp}.txt

if [ ! -f \$SessionTxtFile ]; then
	echo "***** ERROR $LINENO: The session file does not exists for this subject: \${SubID}, ${ImgTyp}"
	exit 1
fi

StudyID_Date=\$(ls ${ProcessedDir} | grep "${StudyID}.anon")
LT_OUTPUT_DIR=${ProcessedDir}/\${StudyID_Date}/\${SubID}/${ImgTyp}.${DirSuffix}.${LT_DirSuffix}
mkdir -p \${LT_OUTPUT_DIR}

#--form the session image lists -----
mov_list=""
nu_mov_list=""

lta_list=""
mapmov_list=""

SesID_List=""

while read SessionFileName
do
	# Where do you want to get your data from? e.g. ANTs?
	StudyIDVar=\$(echo \$SessionFileName | awk -F"/" '{print \$6}') # Study ID
	SubIDVar=\$(echo \$SessionFileName | awk -F"/" '{print \$7}') # Sub ID
	SesIDVar=\$(echo \$SessionFileName | awk -F"/" '{print \$8}') # Session ID
	ModIDVar=\$(echo \$SessionFileName | awk -F"/" '{print \$9}') #Modality type: anat, dwi etc
	ImgNameEx=\$(echo \$SessionFileName | awk -F"/" '{print \$10}') #ImageName with extension
	ImgName=\$(basename \$ImgNameEx .nii.gz) # ImageName without extension

	echo "==== On session: \${StudyIDVar}, \${SubIDVar}, \${SesIDVar}"

	#CROSS SECTIONAL RESULTS -------------------------------------------------------

	#FS
	CS_INPUT_DIR=${ProcessedDir}/\${StudyIDVar}/\${SubIDVar}/\${SesIDVar}/\${ModIDVar}/\${ImgName}.${DirSuffix}
	CS_IMAGE_BASE=norm
	CS_IMAGE_NAME=\${CS_INPUT_DIR}/\${ImgName}/mri/\${CS_IMAGE_BASE}.mgz
	CS_NU_IMAGE_NAME=\${CS_INPUT_DIR}/\${ImgName}/mri/nu.mgz

	#ANTS
	#CS_INPUT_DIR=${ProcessedDir}/\${StudyIDVar}/\${SubIDVar}/\${SesIDVar}/\${ModIDVar}/\${ImgName}.${DirSuffix}
	#CS_IMAGE_BASE=BrainExtractionBrain
	#CS_IMAGE_NAME=\${CS_INPUT_DIR}/antsCorticalThickness/\${CS_IMAGE_BASE}.nii.gz
	#-------------------------------------------------------------------------------

	LTA_IMAGE_NAME=\${LT_OUTPUT_DIR}/\${SubIDVar}_\${SesIDVar}_\${CS_IMAGE_BASE}_xforms.lta
	MPMV_IMAGE_NAME=\${LT_OUTPUT_DIR}/\${SubIDVar}_\${SesIDVar}_\${CS_IMAGE_BASE}_mapmov.nii.gz

	# Now form the arrays for the robust_mri_template
	mov_list="\${mov_list} \${CS_IMAGE_NAME}"
	nu_mov_list="\${nu_mov_list} \${CS_NU_IMAGE_NAME}"
	lta_list="\${lta_list} \${LTA_IMAGE_NAME}"
	mapmov_list="\${mapmov_list} \${MPMV_IMAGE_NAME}"
	SesID_List="\${SesID_List} \${SesIDVar}"

done<\${SessionTxtFile}

mov_list_arr=(\$mov_list)
nu_mov_list_arr=(\$nu_mov_list)
lta_list_arr=(\$lta_list)
mapmov_list_arr=(\$mapmov_list)
SesID_List_arr=(\$SesID_List)

NumSes=\$(cat \${SessionTxtFile} | wc -l)

# Just keep a copy of the sessions for the record...
cp \${SessionTxtFile} \${LT_OUTPUT_DIR}

template_pathname=\${LT_OUTPUT_DIR}/\${SubID}_\${CS_IMAGE_BASE}_median.nii.gz
nu_template_pathname=\${LT_OUTPUT_DIR}/\${SubID}_\${CS_IMAGE_BASE}_nu_median.nii.gz

# INPUT & OUTPUT functions =================================================
###### Write me down a report:
echo "==="
echo "Subject: \$SubIDVar"
echo "Image Type: ${ImgTyp}"
echo "Number of available sessions: \$NumSes"
echo "==="
echo "Output Directory: \${LT_OUTPUT_DIR}"
echo ""
echo ""
echo "-------------// Sessions Images \\----------"
echo "INPUT IMAGES: \${mov_list}"
echo ""
echo "-------------// TEMPLATE: \\----------------"
echo "TEMPLATE WILL BE SAVED: \${template_pathname}"
echo ""
echo "------------// MAPMOV list \\--------------------"
echo "MAPMOV IAMGES: \${mapmov_list}"
echo ""
echo "------------// XFORMS list \\--------------------"
echo "LTA FILES: \${lta_list}"
echo "==========================================="
echo "STARTS @" \`date\`
echo "==========================================="

#############################################################################
#############################################################################

# Load packages and software here
#Freesurfer
ml FreeSurfer
ml Perl
source /apps/eb/software/FreeSurfer/6.0.1-centos6_x86_64/FreeSurferEnv.sh
#ANTs
ml ANTs

# And now the operations
echo "++++++++++ Running mri_robust_template ++"
echo "+++++++++++++++++++++++++++++++++++++++++"
echo "MRI ROBUST TEMPLATE:"
echo "MOV: \${nu_mov_list}"
echo "MAPMOV: \${mapmov_list}"
echo "TEMPLATE: \${nu_template_pathname}"
echo "LAT: \${lta_list}"

mri_robust_template \\
--mov \${mov_list} \\
--lta \${lta_list} \\
--template \${template_pathname} \\
--mapmov \${mapmov_list} \\
--average 1 \\
--satit \\
--iscale \\
--average 0

echo "Adding back the neck +++++++++++++++++++++"
echo "++++++++++++++++++++++++++++++++++++++++++"
echo "++++++++++++++++++++++++++++++++++++++++++"
echo "MRI ROBUST TEMPLATE:"
echo "MOV: \${nu_mov_list}"
echo "TEMPLATE: \${nu_template_pathname}"
echo "LAT: \${lta_list}"

mri_robust_template \\
--mov \${nu_mov_list} \\
--template \${nu_template_pathname}  \\
--noit \\
--ixforms \${lta_list}  \\
--average 1


echo "mri_vol2vol +++++++++++++++++++++++++++++"
echo "+++++++++++++++++++++++++++++++++++++++++"
echo "+++++++++++++++++++++++++++++++++++++++++"
echo "Numbe of sessions available: \$NumSes"

for ses_cnt in \$(seq 0 \$((\${NumSes}-1)))
do

	mrivol2volOutput=\${LT_OUTPUT_DIR}/\${SubID}_\${SesID_List_arr[ses_cnt]}_nu_2_median_nu.nii.gz

	echo "======= Now use mri_vol2vol ============"
	echo "MOV: \${nu_mov_list_arr[ses_cnt]}"
	echo "LTA: \${lta_list_arr[ses_cnt]}"
	echo "Target: \${nu_template_pathname}"
	echo "Output: \${mrivol2volOutput}"

mri_vol2vol \\
--lta \${lta_list_arr[ses_cnt]} \\
--mov \${nu_mov_list_arr[ses_cnt]} \\
--targ \${nu_template_pathname} \\
--no-resample  \\
--o  \${mrivol2volOutput}

done

#echo "+++++++ antsMultivariateTemplateConstruction2.sh ++++++++"
#echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
#echo "Template: \${nu_template_pathname}"
#echo "median nu inputs:"
#echo "Input: \${LT_OUTPUT_DIR}/\${SubID}_*_nu_2_median_nu.nii.gz"

#antsMultivariateTemplateConstruction2.sh \\
#-d 3 \\
#-k 1 \\
#-f 8x4x2x1 \\
#-s 3x2x1x0vox \\
#-q 100x70x30x3 \\
#-l 1  \\
#-t SyN  \\
#-m CC[4] \\
#-c 0 \\
#-a 2 \\
#-z \${nu_template_pathname} \\
#-o \${LT_OUTPUT_DIR}/\${SubID}_ants_temp_med_nu \\
#\${LT_OUTPUT_DIR}/\${SubID}_*_nu_2_median_nu.nii.gz


#############################################################################
#############################################################################

echo "${StudyID}_\${SubID}: 1" > ${ImgTypOpLog}/${JobName}_\${SLURM_ARRAY_JOB_ID}_\${SLURM_ARRAY_TASK_ID}.stat

### ### ### ### ### ###

echo "==========================================="
echo "ENDS @" \`date\`
echo "==========================================="

EOF

if [ ! -z $SLURMSUBMIT ]; then
	echo "I am actually gonna submit them to the queue now!"
	sbatch ${SubmitterFileName}
fi
