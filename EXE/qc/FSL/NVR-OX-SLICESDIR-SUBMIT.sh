StudyID=CFTY720D2201E2
QCLocalDir="${HOME}/NVROXBOX/EXE/qc"

Mem=5G
Time="20:00"

for QCType in raw fov linreg reg
do 
	for ImgTyp in T13D T12D
	do

	JobName="QC_${QCType}_${ImgTyp}"
	SubmitterFileName="Submit_QC_${QCType}_${ImgTyp}.sh"
cat > ${SubmitterFileName} << EOF
#!/bin/bash
#SBATCH --partition=main
#SBATCH --job-name=${JobName}
#SBATCH --mem=${Mem}
#SBATCH --time=${Time}
#SBATCH --output=${QCLocalDir}/logs/${JobName}.out
#SBATCH --error=${QCLocalDir}/logs/${JobName}.err

## Code goes here ## ## ##

sh ${QCLocalDir}/NVR-OX-SLICESDIR-QC.sh ${StudyID} ${ImgTyp} ${QCType}

## ## ## ## ## ## ## ## ## ## ## ##

EOF

	sbatch ${SubmitterFileName}
              
        done
done
