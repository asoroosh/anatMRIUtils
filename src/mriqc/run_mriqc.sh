#============== Get info from users ======================


export SINGULARITYENV_TEMPLATEFLOW_HOME=${HOME}/templateflow

StudyID=$1
SubID=$2
ImgTyp=T1w

echo "=============="
echo "${StudyID}"
echo "${SubID}"
echo "${ImgTyp}"
echo "=============="

#============= Set up the paths ==========================
UnprocessedDir=/XX/XX/XX/XX/XX/sesVISITYYYYMMDD/
ProcessedDir=/XX/XX/XX/XX/

InputDir=${UnprocessedDir}/${StudyID}
OutputDir=${ProcessedDir}/${StudyID}/sub-${SubID}/sub-${SubID}_${ImgTyp}.mriqc
CALLLOG=${OutputDir}/sub-${SubID}_${ImgTyp}_mriqc.log

mkdir -p ${OutputDir}

echo "Unprocessed directory of the data: ${InputDir}"
echo "Output directory: ${OutputDir}"
#============= run mriqc =================================
singularity run \
-B /data/ms/unprocessed/mri/relabelled/sesVISITYYYYMMDD,/data/ms/processed \
/apps/software/containers/mriqc-0.15.2rc1.sif \
${InputDir} \
${OutputDir} \
-w ${OutputDir} \
participant --participant-label ${SubID} \
--modalities ${ImgTyp} \
--no-sub #> $CALLLOG
