BEOP=

StudyID=$1
BEOP=$2

NF=$(ls /rescompdata/ms/unprocessed/RESCOMP/QC/SST-BE${BEOP}/${StudyID}/SST-AVG | wc -l )

if [ $NF -gt 200 ]; then
	echo "THE QC is split to chunks of 200 images."
	pNF=200
else
	pNF=$NF
fi

echo "Number of images: $NF"

InputDir=/rescompdata/ms/unprocessed/RESCOMP/QC/SST-BE${BEOP}/${StudyID}/SST-AVG
OutputDir=/rescompdata/ms/unprocessed/RESCOMP/QC/SST-BE${BEOP}/${StudyID}/SST-AVG

mkdir -p $InputDir

PATH2SOURCE=/home/bdivdi.local/dfgtyk/NVROXBOX/SOURCE/qc
python3 ${PATH2SOURCE}/img_htm_mri_sst.py -i ${InputDir} -o ${OutputDir} -sn ${StudyID}-${BEOP} -nc 1 -nf $pNF

echo "Check: ${OutputDir}"
