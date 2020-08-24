#!/bin/bash

#
# Soroosh Afyouni, University of Oxford, 2020
#
#Copyright (c) 2020
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

#This should later be in a loop around StudyIDs
StudyID=$1
ImgTyp=$2 # T13D T12D
LASTRUNJOBID=$3 # LEAVE THIS EMPTY FOR A FRESH RUN!
NUMJB=$4
SLURMSUBMIT=$5

MyOX_AUX_CONFIGFILE_PATH=${HOME}/NVROXBOX/AUX/Config/nvr-ox-path-setup-fromrescomp.Myoxconfig

source ${MyOX_AUX_CONFIGFILE_PATH}

NUMCORE=2

antsSSTFlag=1
FSSSTFlag=1

SSTregFLAG=1
RENAMEFALG=1

# Later for the submitter file:
Mem=7500M
Time="8-23:59:00"
DirSuffix="autorecon12ws"
LT_DirSuffix="nuws_mrirobusttemplate"

#============================== FUNCTIONS ============
PROGNAME=$(basename $0)
error_exit()
{
	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	exit 1
}
#=====================================================

StudyDir="${DataDir}/${StudyID}"

ImgTypDir=${StudyDir}/${ImgTyp}
#SubIDTxtFile=${ImgTypDir}/Sessions/${StudyID}_FullSessionSubID_${ImgTyp}.txt
SubIDTxtFile=${ImgTypDir}/${StudyID}_${ImgTyp}_ImageSubIDs_50RND.txt

if [ ! -f $SubIDTxtFile ]; then
	error_exit "***** ERROR $LINENO: The file list for study ${StudyID}, Image type: ${ImgTyp} does not exists: ${SubIDTxtFile}"
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

#echo "We will shortly submit $NUMJB jobs..."


#========================================

DATE=$(date +"%d-%m-%y")

ImgTypOp=${ImgTypDir}/${DirSuffix}
ImgTypOpLog=${ImgTypOp}/Logs.${DirSuffix}.${LT_DirSuffix}
mkdir -p ${ImgTypOpLog}

#echo "CHECK: ${ImgTypOp}"

#############################################################################
#############################################################################

JobName=${StudyID}_${LT_DirSuffix}_${DirSuffix}_${NUMJB}
SubmitterFileName="${ImgTypOp}/SubmitMe_${JobName}.sh"

echo ${SubmitterFileName}

cat > $SubmitterFileName << EOF
#!/bin/bash
#SBATCH --partition=main
#SBATCH --job-name=${JobName}
#SBATCH --mem-per-cpu=${Mem}
#SBATCH --time=${Time}
#SBATCH --cpus-per-task=${NUMCORE}
#SBATCH --output=${ImgTypOpLog}/${JobName}_%A_%a.out
#SBATCH --error=${ImgTypOpLog}/${JobName}_%A_%a.err
#SBATCH --array=1-${NUMJB}

MYTASKID=\$SLURM_ARRAY_TASK_ID
MYJOBID=\$SLURM_ARRAY_JOB_ID

set -e

source ${MyOX_AUX_CONFIGFILE_PATH}

# Load packages and software here
#ml ANTs
#ml FreeSurfer
#ml Perl
#source /apps/eb/software/FreeSurfer/6.0.1-centos6_x86_64/FreeSurferEnv.sh
#ml Python/3.6.6-foss-2018b

# Read the input path
ImgIDX=\$MYTASKID
SubID=\$(cat $SubIDTxtFile | sed -n \${ImgIDX}p)

STATFILE=${ImgTypOpLog}/${JobName}_\${MYJOBID}_\${MYTASKID}.stat

############################## RE RUNs ON FAILED SUBJECTS #################################
if [ ! -z $LASTRUNJOBID ]; then

	PREVIOUSRUN=${ImgTypOpLog}/${JobName}_${LASTRUNJOBID}_\${MYTASKID}.stat
	if [ ! -f \${PREVIOUSRUN} ]; then
		echo "XXXERROR: THE STAT FILE: \${PREVIOUSRUN} DOES NOT EXISTS."
		exit 1
	fi

	STAT=\$(cat \${PREVIOUSRUN} | awk '{print \$2}' )
	if [ \$STAT == 1 ]; then
	        echo ""
	        echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
	        echo "THIS JOB WAS COMPLETED, JOB STAT: \${STAT}. WE WILL STOP."
	        echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
	        exit 1
	else
	        echo ""
	        echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
	        echo "THIS JOB WAS FAILED... STAT: \${STAT} WE CONTINUE. "
	        echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
	fi
else

	echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
	echo "FRESH RUN, STATFILE: \${STATFILE}"
	echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

fi
###########################################################################################

# Set the job status to zero here. If the operation reaches the bottom without error, then the status will be changed to 1
echo "${StudyID}_\${SubID}: 0" > \${STATFILE}

# ========================================================================
SessionsDir=${StudyDir}/${ImgTyp}/Sessions
SessionTxtFile=\${SessionsDir}/${StudyID}_\${SubID}_${ImgTyp}.txt
NumSesSANITYCHECK=\$(cat \${SessionTxtFile} | wc -l)

if [ ! -f \$SessionTxtFile ]; then
	echo "***** ERROR $LINENO: The session file does not exists for this subject: \${SubID}, ${ImgTyp}"
	exit 1
fi

LT_OUTPUT_DIR=${ProcessedDir}/${StudyID}/\${SubID}/${ImgTyp}.${DirSuffix}.${LT_DirSuffix}
mkdir -p \${LT_OUTPUT_DIR}

#--form the session image lists -----
mov_list=""
nu_mov_list=""
lta_list=""
mapmov_list=""
SesID_List=""

SUBSESTABLE=${DataDir}/${StudyID}/${ImgTyp}/${StudyID}_${ImgTyp}_ImageSubSesID.table
SesID_List_arr=(\$(sh ${SOURCEPATH}/mis/getmesesids.sh ${StudyID} \${SubID} \${SUBSESTABLE} | sed -n '1p'))
ImageNameVar_List=(\$(sh ${SOURCEPATH}/mis/getmesesids.sh ${StudyID} \${SubID} \${SUBSESTABLE} | sed -n '3p'))
ModIDList=(\$(sh ${SOURCEPATH}/mis/getmesesids.sh ${StudyID} \${SubID} \${SUBSESTABLE} | sed -n '4p'))
NumSes=\$(sh ${SOURCEPATH}/mis/getmesesids.sh ${StudyID} \${SubID} \${SUBSESTABLE} | sed -n '5p')

SesID4SST=\$(python $SOURCEPATH/mis/datepace.py \${SesID_List_arr[@]} | sed -n 1p)
SesID2SST=\$(python $SOURCEPATH/mis/datepace.py \${SesID_List_arr[@]} | sed -n 2p)

## SANITY CHECK
if [ \$NumSesSANITYCHECK == \$NumSes ]; then
	echo "Sanity check: Number of sessions in table matches the number of sessions in /Session: \${NumSes}"
else
	echo ""
	echo "XXXERROR: The number of sessions are not identical between the /Session and the table. TABLE: \${NumSes}, /Session: \${NumSesSANITYCHECK}"
fi

echo ""
echo "Number of Sessions: \${NumSes}"
echo "***The full list of sessions: \${SesID_List_arr[@]}"

if [[ -z \$SesID2SST ]]; then
	echo "XXX WARNING: The number of sessions is \${NumSes} and therefore, we will not use 2SST registration."
else
	echo "***Session which will be sent to SST: \$SesID4SST"
fi

echo ""
echo "***Sessions whih will be registered later to the sst: \$SesID2SST"

for SesI in \$(seq 0 \$((NumSes-1)))
do
        # Where do you want to get your data from? e.g. ANTs?
        StudyIDVar=${StudyID} # Study ID
        SubIDVar=\${SubID} # Sub ID
        SesIDVar=\${SesID_List_arr[\$SesI]} # Session ID
        ModIDVar=\${ModIDList[\$SesI]} #Modality type: anat, dwi etc
        ImgNameEx= #ImageName with extension
        ImgName=\${ImageNameVar_List[\$SesI]} # without extension

        echo "==== On session: \${StudyIDVar}, \${SubIDVar}, \${SesIDVar}, \${SesI}"

        #CROSS SECTIONAL RESULTS -------------------------------------------------------

        #FS
        CS_INPUT_DIR=${ProcessedDir}/\${StudyIDVar}/\${SubIDVar}/ses-\${SesIDVar}/\${ModIDVar}/\${ImgName}.${DirSuffix}
        CS_IMAGE_BASE=norm
        CS_IMAGE_NAME=\${CS_INPUT_DIR}/\${ImgName}/mri/\${CS_IMAGE_BASE}.mgz
        CS_NU_IMAGE_NAME=\${CS_INPUT_DIR}/\${ImgName}/mri/nu.mgz

        #-------------------------------------------------------------------------------

        LTA_IMAGE_NAME=\${LT_OUTPUT_DIR}/\${SubIDVar}_ses-\${SesIDVar}_\${CS_IMAGE_BASE}_xforms.lta
        MPMV_IMAGE_NAME=\${LT_OUTPUT_DIR}/\${SubIDVar}_ses-\${SesIDVar}_\${CS_IMAGE_BASE}_mapmov.nii.gz

        # Now form the arrays for the robust_mri_template
        mov_list="\${mov_list} \${CS_IMAGE_NAME}"
        nu_mov_list="\${nu_mov_list} \${CS_NU_IMAGE_NAME}"
        lta_list="\${lta_list} \${LTA_IMAGE_NAME}"
        mapmov_list="\${mapmov_list} \${MPMV_IMAGE_NAME}"
done


mov_list_arr=(\$mov_list)
nu_mov_list_arr=(\$nu_mov_list)
lta_list_arr=(\$lta_list)
mapmov_list_arr=(\$mapmov_list)

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

if [ $FSSSTFlag == 1 ]
then

	LogTxtFile_FS=\${LT_OUTPUT_DIR}/\${SubID}_mri_robust_template.log

	echo "Log file will be on: \${LogTxtFile_FS}"

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
--average 0 > \$LogTxtFile_FS

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

		mrivol2volOutput=\${LT_OUTPUT_DIR}/\${SubID}_ses-\${SesID_List_arr[ses_cnt]}_nu_2_median_nu.nii.gz

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

else
	echo "********* WE WILL NOT RUN FS SST. ********* "

fi

echo "+++++++++++++++++++++++++++++++++++++++++"
echo "+++++++++++++++++++++++++++++++++++++++++"
echo "+++ SPLIT THE SESSIONS: +++++++++++++++++"

SesMedNu4SST=""
#### Make images to be sent to SST
for ses_id in \${SesID4SST[@]}
do
        A=\${LT_OUTPUT_DIR}/\${SubID}_ses-\${ses_id}_nu_2_median_nu.nii.gz
	SesMedNu4SST="\$SesMedNu4SST \$A"
done
SesMedNu4SST=(\$SesMedNu4SST)

echo "=== WE WILL SEND THESE INTO THE SST CONSTRUCTION:"
echo \${SesMedNu4SST[@]}
echo "=="

if [ $antsSSTFlag == 1 ]
then

	echo "+++++++ antsMultivariateTemplateConstruction2.sh ++++++++"
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Template: \${nu_template_pathname}"
	echo "median nu inputs:"
	echo "Input: \${LT_OUTPUT_DIR}/\${SubID}_*_nu_2_median_nu.nii.gz"

	SessionOrderTxtFile=\${LT_OUTPUT_DIR}/\${SubID}_SessionOrdersFedtoAnts.txt
	ls \${LT_OUTPUT_DIR}/\${SubID}_*_nu_2_median_nu.nii.gz > \$SessionOrderTxtFile

	LogTxtFile=\${LT_OUTPUT_DIR}/\${SubID}_antsMultivariateTemplateConstruction2.log

	echo "Log will be saved here: \${LogTxtFile}"

\${ANTSPATH}/antsMultivariateTemplateConstruction2.sh \\
-d 3 \\
-k 1 \\
-f 8x4x2x1 \\
-s 3x2x1x0vox \\
-q 100x70x30x3 \\
-i 4 \\
-l 1  \\
-t SyN  \\
-m CC[4] \\
-c 0 \\
-a 2 \\
-c 2 \\
-j ${NUMCORE} \\
-z \${nu_template_pathname} \\
-o \${LT_OUTPUT_DIR}/\${SubID}_ants_temp_med_nu \\
\${SesMedNu4SST[@]} > \$LogTxtFile
#\${LT_OUTPUT_DIR}/\${SubID}_*_nu_2_median_nu.nii.gz > \$LogTxtFile

	#############################################################################
	#############################################################################
	# Now start to register the remaining to the SST

else
        echo "********* WE WILL NOT RUN ants SST. *********"

fi


if [[ ! -z \$SesID2SST ]] && [ $SSTregFLAG == 1 ]; then

	echo ""
	echo " ########################## "
	echo " PARALLEL REGISTRATIONS:    "
	echo " ########################## "
	echo " "

	#### Make images to be registered later to the SST
	SesMedNu2SST=""
	for ses_id in \${SesID2SST[@]}
	do
	        B=\${LT_OUTPUT_DIR}/\${SubID}_ses-\${ses_id}_nu_2_median_nu.nii.gz
		SesMedNu2SST="\$SesMedNu2SST \$B"
	done
	SesMedNu2SST=(\$SesMedNu2SST)
	echo "=== WE WILL SEND THESE INTO THE REG 2 SST:"
	echo \${SesMedNu2SST[@]}
	echo "=="

	SSTTEMPLATES=\${LT_OUTPUT_DIR}/\${SubID}_ants_temp_med_nu

	#NumSes2SST=${#SesMedNu2SST[@]}
	#NumSesperSST=$((NumSes2SST/NUMCORE))

	COREJOBSIDR=${ImgTypOp}/COREJOBS/COREJOBS_\${MYJOBID}
	mkdir -p \${COREJOBSIDR}

	for icore in \$(seq 1 ${NUMCORE})
	do
		SES2SSTCORES=\$(python $SOURCEPATH/mis/break2cores.py \${SesMedNu2SST[@]} ${NUMCORE} | sed -n \${icore}p)
		COREFILE2RUN="\${COREJOBSIDR}/Submit2core_${JobName}_\${SubID}_\${icore}.sh"

		echo "This will be sent to job number: \${icore}"
		echo \${SES2SSTCORES[@]}

		corexe="for CORESesID2SST in \${SES2SSTCORES[@]}; do echo \"On Session: \\\${CORESesID2SST} \"; ${SOURCEPATH}/reg/reg2sst/reg2sst.sh \\\${CORESesID2SST} \${SSTTEMPLATES}template0.nii.gz; echo \"DONE WITH: \\\${CORESesID2SST} \"; done"
		echo "#!/bin/bash" > \$COREFILE2RUN
		echo \$corexe >> \$COREFILE2RUN
	done


	\${ANTSPATH}/ANTSpexec.sh -j 2 "sh" \${COREJOBSIDR}/Submit2core_${JobName}_\${SubID}_*.sh

else

	echo "No Sessions submitted to parallel registation:"
	echo "LIST OF SESSIONS::: \${SesID2SST[@]} :::"
fi



if [ $RENAMEFALG == 1 ]; then

	echo ""
	echo "####################################################"
	echo "RENAMING FROM ANTS STANDARD TO OUR CONVENTION."
	echo "####################################################"

	COPYLOG=\${LT_OUTPUT_DIR}/RENAMING.log

	for SesID in \${SesID4SST[@]}
	do

		echo "Copying session: \${SesID}"
		BASEIMG=\${SubID}_ants_temp_med_nutemplate0\${SubID}_ses-\${SesID}_nu_2_median_nu
		BASEWARP=\${SubID}_ants_temp_med_nu\${SubID}_ses-\${SesID}_nu_2_median_nu

		#-Transformations
		WARP=\${LT_OUTPUT_DIR}/\${BASEWARP}[0-9]1Warp.nii.gz
		INVERSEWARP=\${LT_OUTPUT_DIR}/\${BASEWARP}[0-9]1InverseWarp.nii.gz
		AFFINE=\${LT_OUTPUT_DIR}/\${BASEWARP}[0-9]0GenericAffine.mat
		#- Image(s)
		WARPEDIMG=\${LT_OUTPUT_DIR}/\${BASEIMG}[0-9]WarpedToTemplate.nii.gz
		#- List
		FILE_LIST0=(\${WARP} \${INVERSEWARP} \${AFFINE} \${WARPEDIMG})

		#- Transformations
		NEW_WARP=\${LT_OUTPUT_DIR}/\${BASEWARP}_1Warp.nii.gz
		NEW_INVERSEWARP=\${LT_OUTPUT_DIR}/\${BASEWARP}_1InverseWarp.nii.gz
		NEW_AFFINE=\${LT_OUTPUT_DIR}/\${BASEWARP}_0GenericAffine.mat
		#- Image(s)
		NEW_WARPEDIMG=\${LT_OUTPUT_DIR}/\${BASEIMG}_WarpedToTemplate.nii.gz
		#- List
		FILE_LIST1=(\${NEW_WARP} \${NEW_INVERSEWARP} \${NEW_AFFINE} \${NEW_WARPEDIMG})

		cnt=0
		for FILENAME_WC in \${FILE_LIST0[@]}
		do
	       		FILENAME=\$(ls \$FILENAME_WC)
			echo "++++COPY:"
	       		echo "\${FILENAME} >>>>> \${FILE_LIST1[\$cnt]}"
			echo "\${FILENAME} >>>>> \${FILE_LIST1[\$cnt]}" >> \${COPYLOG}
			cp \${FILENAME} \${FILE_LIST1[\$cnt]}
	       		cnt=\$((cnt+1))
		done
	done

fi


echo "${StudyID}_\${SubID}: 1" > \${STATFILE}

### ### ### ### ### ###


echo "==========================================="
echo "ENDS @" \`date\`
echo "==========================================="

EOF

if [ ! -z $SLURMSUBMIT ]; then
	echo "I am actually gonna submit them to the queue now!"
	sbatch ${SubmitterFileName}
fi
