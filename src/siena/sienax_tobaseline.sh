set -e

#+++++++= What are we going to use, here?
ml ANTs
ml FreeSurfer
ml Perl
source /apps/eb/software/FreeSurfer/6.0.1-centos6_x86_64/FreeSurferEnv.sh

OpDirSuffix=sienax
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
PRSD_DIR="/XX/XX/XX/XX"
PRSD_SUBDIR=${PRSD_DIR}/${StudyID}/sub-${SubID}

#--------------= Unprocessed paths
UPRSD_DIR="/XX/XX/XX/XX/XX/sesVISITYYYYMMDD"

#+++++++++= SIENA RESULTS

for SesID in ${SesIDList[@]};
do
	UnprocessedDir=${UPRSD_DIR}/${StudyID}
	TarImg=${UnprocessedDir}/sub-${SubID}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_run-1_T1w

	SIENAX_Suboutdir=${PRSD_SUBDIR}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_run-1_T1w.${OpDirSuffix}

	mkdir -p ${SIENAX_Suboutdir}

	echo "Target: ${TarImg}"
	echo "Output Dir: ${SIENAX_Suboutdir}"

	${FSLDIR}/bin/sienax ${TarImg}.nii.gz -2 -o ${SIENAX_Suboutdir}
done

echo "===================================="
echo "===================================="
echo "DONE: $(date)"
echo "===================================="
echo "===================================="
