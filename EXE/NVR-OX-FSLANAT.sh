StudyID=CFTY720D2201E2

Mem=5G
Time="30:00"
ImgType=acq-3d
RunID=1

PathUnProcParent="/data/output/habib/unprocessed/$StudyID"
PathProcParent="/data/output/habib/processed/$StudyID"

GitHubDataDir="/home/bdivdi.local/dfgtyk/NVROXBOX/Data/${StudyID}"

mkdir -p ${GitHubDataDir}
mkdir -p ${GitHubDataDir}/Sessions

StudySubIDFile="${GitHubDataDir}/SubID_$StudyID.txt"
# Make sure there aren't another version of this file
rm -f $StudySubIDFile
ls -d /data/output/habib/unprocessed/$StudyID/sub-*/ >> $StudySubIDFile

while read SubID
do
	# Get the SubID from the directory path
	SubID=`basename $SubID`
	echo "For Subject: $SubID ========================================"

	# crawl into the subject directory and find how many sessions are available
	StudSubSesIDFile="${GitHubDataDir}/Sessions/${StudyID}_${SubID}_${ImgType}_Sessions.txt"
	# Make sure there aren't another version of this file
	rm -f $StudSubSesIDFile
	ls -d /data/output/habib/unprocessed/$StudyID/$SubID/*/ >> $StudSubSesIDFile 
	
        GitHubDataDirSub=$GitHubDataDir/$SubID
        mkdir -p $GitHubDataDirSub

	#Loop around the available sessions of $SubID
	while read Ses
	do
		# Get the session ID from the path directory
		Ses=`basename $Ses`

		# Reconstruct the directory name
		Path_UnpImg=$PathUnProcParent/$SubID/$Ses/anat/${SubID}_${Ses}_${ImgType}_run-${RunID}_T1w.nii.gz
		
		# Check whether the file actually exists
		if [ ! -f $Path_UnpImg ]; 
		then 
			echo "**** File Does Not Exist ***** "; 
		else

		GitHubDataDirSubSes=${GitHubDataDirSub}/${Ses}/anat
                mkdir -p ${GitHubDataDirSubSes}

		#If it does, make an $FILENAME.anat directory
		Path_ProImg=$PathProcParent/$SubID/$Ses/anat/${SubID}_${Ses}_${ImgType}_run-${RunID}_T1w

		echo $Path_UnpImg
                echo $Path_ProImg

		JobName=${StudyID}_${SubID}_${Ses}_${ImgType}_run-${RunID}_T1w
		SubmitterFileName="${GitHubDataDirSubSes}/SubmitMe_${JobName}.sh"

cat > $SubmitterFileName << EOF
#!/bin/bash
#SBATCH --partition=main
#SBATCH --job-name=${JobName}
#SBATCH --mem=${Mem}
#SBATCH --time=${Time}
#SBATCH --output=${GitHubDataDirSubSes}/${JobName}.out
#SBATCH --error=${GitHubDataDirSubSes}/${JobName}.err

echo "==== RUNING FSLANA ===="
echo "logs and error will be saved in: ${GitHubDataDirSubSes}/${JobName}"
echo "FSL is available from: $FSLDIR"
echo "fsl_anat log files will be in: $Path_ProImg"
echo "======================="
echo "Unprocessed images will be: $Path_UnpImg"
echo "Processed images will be:   $Path_ProImg"


mkdir -p $Path_ProImg

## fsl_anat code goes here ## ## ## 

$FSLDIR/bin/fsl_anat -i $Path_UnpImg -o $Path_ProImg

## ## ## ## ## ## ## ## ## ## ## ##

EOF

		fi
	
	done<$StudSubSesIDFile

done<$StudySubIDFile
