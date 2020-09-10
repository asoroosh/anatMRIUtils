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

StudyID=$1
ImgTyp=$2
LASTRUNJOBID=$3
NUMJB=$4
SLURMSUBMIT=$5

#CONFIGFILE=${HOME}/NVROXBOX/AUX/Config/nvr-ox-path-setup-fromrescomp.Myoxconfig
#source ${CONFIGFILE}

source ${MyOX_AUX_CONFIGFILE_PATH}

# Later for the submitter file:
Mem=7500M
Time="24:59:00"
DirSuffix="autorecon12ws"

#============================== FUNCTIONS ============
PROGNAME=$(basename $0)
error_exit()
{
	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	exit 1
}
#=====================================================

# Path to the source files (i.e. editted functions for each operation ~/NVROXBOX/SOURCE/*)
#SOURCEPATH=${HOME}/NVROXBOX/SOURCE/
# Set the paths and read number of jobs to be submitted
# DataDir="${HOME}/NVROXBOX/Data"
#ProcessedDir="/XXXX/XXXX/XXXX/XXX"

StudyDir="${DataDir}/${StudyID}"
ImgTypDir=${StudyDir}/${ImgTyp}
ImageFileTxt=${ImgTypDir}/${StudyID}_${ImgTyp}_ImageList_50RND.txt

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

#echo "We will shortly submit $NUMJB jobs..."

#========================================

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
ImgTypOpLog=${ImgTypOp}/Logs
mkdir -p ${ImgTypOpLog}

#############################################################################
#############################################################################

JobName=${StudyID}_${DirSuffix}_${NUMJB}
SubmitterFileName="${ImgTypOp}/SubmitMe_${JobName}.sh"

echo $SubmitterFileName

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

MYTASKID=\$SLURM_ARRAY_TASK_ID
MYJOBID=\$SLURM_ARRAY_JOB_ID

# Read the input path
ImgIDX=\$MYTASKID
InputImagePath=\$(cat $ImageFileTxt | sed -n \${ImgIDX}p)

echo "\$InputImagePath"

AA=\$(echo "${UnprocessedPath}" | awk -F"/" '{print NF-1}'); AA=\$((AA+1))
echo \$AA
# INPUT & OUTPUT functions =================================================
StudyIDVar=\$(echo \$InputImagePath | awk -F"/" -v xx=\$((AA+1)) '{print \$xx}') # Study ID
SubIDVar=\$(echo \$InputImagePath | awk -F"/" -v xx=\$((AA+2)) '{print \$xx}') # Sub ID
SesIDVar=\$(echo \$InputImagePath | awk -F"/" -v xx=\$((AA+3)) '{print \$xx}') # Session ID
ModIDVar=\$(echo \$InputImagePath | awk -F"/" -v xx=\$((AA+4)) '{print \$xx}') #Modality type: anat, dwi etc
ImgNameEx=\$(echo \$InputImagePath | awk -F"/" -v xx=\$((AA+5)) '{print \$xx}') #ImageName with extension
ImgName=\$(basename \$ImgNameEx .nii.gz) # ImageName without extension

echo "DOING THIS NOW:"
echo "\${StudyIDVar} -- \${SubIDVar} -- \${SesIDVar} -- \${ModIDVar} -- \${ImgNameEx}"
echo ""

#StudyIDVar=\${StudyID}
#SubIDVar=\${SubID}
#SesID_List_arr=(\$(sh ${SOURCEPATH}/mis/getmesesids.sh ${StudyID} \${SubID} | sed -n '1p'))
#ImageNameVar_List=(\$(sh ${SOURCEPATH}/mis/getmesesids.sh ${StudyID} \${SubID} | sed -n '3p'))
#ModIDList=(\$(sh ${SOURCEPATH}/mis/getmesesids.sh ${StudyID} \${SubID} | sed -n '4p'))
#NumSes=\$(sh ${SOURCEPATH}/mis/getmesesids.sh ${StudyID} \${SubID} | sed -n '5p')

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
echo "\${InputImagePath}: 0" > \${STATFILE}

# Reconstruct the output directory name
OutputDir=${ProcessedDir}/\${StudyIDVar}/\${SubIDVar}/\${SesIDVar}/\${ModIDVar}/\${ImgName}.${DirSuffix}

echo \${OutputDir}

if [ -d \$OutputDir ]; then
	echo "Already exists, we delete and remake it: \$OutputDir "
	rm -rf \${OutputDir}
else
	echo "Make: \${OutputDir}"
fi
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
#ml FreeSurfer
#ml Perl
#source /apps/eb/software/FreeSurfer/6.0.1-centos6_x86_64/FreeSurferEnv.sh

source ${CONFIGFILE}

# And now the operations

echo "++++++++++ Running recon-all..."

recon-all \\
-subjid \${ImgName} \\
-i \${InputImagePath} \
-sd \${OutputDir} \\
-autorecon1 \\
-no-wsgcaatlas \\
-subcortseg \\
-gcareg \\
-canorm

# From rescomp runs
#recon-all \\
#-subjid \${ImgName} \\
#-i \${InputImagePath} \
#-sd \${OutputDir} \\
#-autorecon1 \\
#-no-wsgcaatlas \\
#-gcareg \\
#-canorm \\
#-careg


#############################################################################
#############################################################################

echo "\${InputImagePath}: 1" > \${STATFILE}

### ### ### ### ### ###

echo "==========================================="
echo "ENDS @" \`date\`
echo "==========================================="

EOF

if [ ! -z $SLURMSUBMIT ]; then
	echo "I am actually gonna submit them to the queue now!"
	sbatch ${SubmitterFileName}
fi
