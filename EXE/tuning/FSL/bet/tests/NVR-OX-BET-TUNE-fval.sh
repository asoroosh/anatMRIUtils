for SubIDX in $(seq 1 17)
do
	echo $SubIDX

	SubSesID=$(sed "${SubIDX}q;d" failed_bet.txt)
	SubID=$(echo $SubSesID | awk -F"_" '{print $1}')
	SesID=$(echo $SubSesID | awk -F"_" '{print $2}')
	StudyID=$(echo $SubID | awk -F"-" '{print $2}' | awk -F"." '{print $1}')

	StudyID_Date=$(ls /data/ms/unprocessed/mri/ | grep "${StudyID}.anon") #because the damn Study names has inconsistant dates in them!

	echo $SubID
	echo $SesID
	echo $StudyID
	echo $StudyID_Date

	InputImage=/data/ms/unprocessed/mri/${StudyID_Date}/${SubID}/${SesID}/anat/${SubID}_${SesID}_run-1_T1w.nii.gz
	echo $InputImage

	InputImageName=$(basename ${InputImage} .nii.gz)
	OutputDir=/home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FSL/bet/tests/out_bet/${InputImageName}

	mkdir -p ${OutputDir}

	cp ${InputImage} ${OutputDir}  

	for fval in 1 2 4 5 6 8
	do
		OutputImage=${OutputDir}/${InputImageName}_bet_${fval}.nii.gz

		echo "Inputimage: $InputImage"
		echo "Outputimage: $OutputImage "

		bet ${InputImage} ${OutputImage} -m -f $(($fval/10))
	done
done
