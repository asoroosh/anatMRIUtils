set -e

#+++++++= What are we going to use, here?
ml ANTs
ml FreeSurfer
ml Perl
source /apps/eb/software/FreeSurfer/6.0.1-centos6_x86_64/FreeSurferEnv.sh

do_seg=1

OpDirSuffix=siena
ImgTyp=T12D
#++++++++= Subject/Session Information


#FUNCTIONS-------------------------------------
function get_index() {
# fine me element(s) in the input array which contains the second input
# SA, Ox, 2019
arrgs=("$@")
mmmval=${arrgs[-1]}
NUMSES0=${#arrgs[@]}
for i in $(seq 0 $((NUMSES0-2)) )
do
        if [[ ${arrgs[i]} =~ $mmmval ]]; then
                echo "${i}";
        fi
done
}
#----------------------------------------------


StudyID=$1
SubID=$2
SesBLTag=$3

SubTag=sub-${StudyID}

#---------------------------------

VoxRes=2

echo "======================================="
echo "STARTED @" $(date)
echo "======================================="
echo ""
echo "============================================================"
echo "============================================================"
echo "** StudyID: ${StudyID}, SubID: ${SubID} "
echo "============================================================"
echo "============================================================"


DataDir=${HOME}/NVROXBOX/Data/RELAB
SessionsFileName=${DataDir}/${StudyID}/T12D/Sessions/${StudyID}_sub-${SubID}_${ImgTyp}.txt
while read SessionPathsFiles
do
	echo ${SessionPathsFiles}

        ses_SesID_tmp=$(echo $SessionPathsFiles | awk -F"/" '{print $10}')
        SesID_tmp=$(echo $ses_SesID_tmp | awk -F"-" '{print $2}')
        SesIDList="${SesIDList} $SesID_tmp"
done<${SessionsFileName}
SesIDList=(${SesIDList})

echo "sessions:"
echo ${SesIDList[@]}

#------------= Main paths
PRSD_DIR="/data/ms/processed/mri"
PRSD_SUBDIR=${PRSD_DIR}/${StudyID}/sub-${SubID}

#--------------= Unprocessed paths
UPRSD_DIR="/XXX/XX/XX/XX/XX/XX"
UnprocessedDir=${UPRSD_DIR}/${StudyID}

#+++++++++= SIENA RESULTS
SIENA_Suboutdir=${PRSD_SUBDIR}/sub-${SubID}.${OpDirSuffix}

#if [ $do_seg == 1 ]; then
#        rm -rf ${SIENA_Suboutdir}
#fi

BaselineIndex=$(get_index "${SesIDList[@]}" "$SesBLTag")
Ses_BL=${SesIDList[BaselineIndex]}

echo "Baseline: ${Ses_BL}"

BaselineImg=${UnprocessedDir}/sub-${SubID}/ses-${Ses_BL}/anat/sub-${SubID}_ses-${Ses_BL}_run-1_T1w

if [ ! -f ${BaselineImg}.nii.gz ]
then
	echo "No baseline available...."
	exit 1
fi

echo "Baseline: ${BaselineImg}"

SesIDList_woBL=${SesIDList[@]/$Ses_BL}

for SesID in ${SesIDList_woBL[@]};
do
	TarImg=${UnprocessedDir}/sub-${SubID}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_run-1_T1w
	sienaxout=${SIENA_Suboutdir}/${Ses_BL}v${SesID}

	mkdir -p ${sienaxout}

	echo "Target to be compare against the baseline: ${TarImg}"
	echo "Output Dir: ${sienaxout}"

	${FSLDIR}/bin/siena ${BaselineImg}.nii.gz ${TarImg}.nii.gz -2 -o ${sienaxout}
done

echo "===================================="
echo "===================================="
echo "DONE: $(date)"
echo "===================================="
echo "===================================="
