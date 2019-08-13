ml Python

InputDir=${1}
OutputDir=${2}
AnalysisName=${3}

python3 img_htm_mri.py \
-i $InputDir \
-o $OutputDir \
-sn ${AnalysisName} \
-nc 2 \
-nf $(ls ${InputDir} | wc -l)
