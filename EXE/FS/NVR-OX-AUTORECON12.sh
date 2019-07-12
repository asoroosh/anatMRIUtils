#This should later be in a loop around StudyIDs
StudyID=CFTY720D2201E2

ImgType=$1 # Here we only use T13D and T12D

RunID=1

set -e

Mem=5G
Time="30:00"

PathProcParent="/data/output/habib/processed/$StudyID"

SRC_DIR="${HOME}/NVROXBOX/SOURCE"
GMATLAS_DIR="${HOME}/NVROXBOX/SOURCE/atlas/GMatlas"

GitHubDataDir="${HOME}/NVROXBOX/Data/${StudyID}"
StudySubIDFile="${GitHubDataDir}/SubDirID_${StudyID}.txt"

#Submitter files, just save the path to them for future mass re-producing
SubmitterPath="${GitHubDataDir}/SLUMR_GMP_Submitters_${StudyID}_${ImgType}.txt"
rm -f ${SubmitterPath}

while read SubID
do
	# Get the SubID from the directory path
        SubID=`basename $SubID`
	echo "For Subject: $SubID ========================================"

	GitHubDataDirSub=$GitHubDataDir/$SubID
        mkdir -p $GitHubDataDirSub

	SessionFileName="${GitHubDataDir}/Sessions/${StudyID}_${SubID}_Sessions.txt"

	echo "=== Available sessions:"
        cat ${SessionFileName}

	while read Ses
	do

		Ses=`basename $Ses`
        	#Image Name
        	if [ $ImgType == T13D ] ; then
                	#sub-2okKlAKGz7_ses-V1_M2_acq-3d_run-1_T1w.nii.gz
			ImageName=${SubID}_${Ses}_acq-3d_run-${RunID}_T1w

			elif [ $ImgType == T12D ] ; then
                	#sub-2okKlAKGz7_ses-V1_M2_run-1_T1w.nii.gz
                	ImageName=${SubID}_${Ses}_run-${RunID}_T1w
        	else
                	# throw an error and halt here
                	echo "$ImgType is unrecognised"
        	fi

		FSLANAT_dir=${PathProcParent}/${SubID}/${Ses}/anat/${ImageName}.anat

    		# Check whether the file actually exists
    		if [ ! -d $FSLANAT_dir ];
    		then
    			echo "**** File Does Not Exist ***** ";
        		echo "Missing: $GMSEGIMG" >> ${GitHubDataDir}/EmptyDir_GMP_${StudyID}_${ImgType}.txt
			continue
		else

			GMPOutputDir=${PathProcParent}/${SubID}/${Ses}/anat/${ImageName}.gmp

			GitHubDataDirSubGMP=${GitHubDataDirSub}/${Ses}/anat/gmp
			mkdir -p ${GitHubDataDirSubGMP}

			JobName=${StudyID}_${ImageName}_GMP
        		SubmitterFileName="${GitHubDataDirSubGMP}/SubmitMe_${JobName}.sh"
        		echo "${SubmitterFileName}" >> $SubmitterPath

cat > $SubmitterFileName << EOF
#!/bin/bash
#SBATCH --partition=main
#SBATCH --job-name=${JobName}
#SBATCH --mem=${Mem}
#SBATCH --time=${Time}
#SBATCH --output=${GitHubDataDirSubGMP}/${JobName}.out
#SBATCH --error=${GitHubDataDirSubGMP}/${JobName}.err

mkdir -p ${GMPOutputDir}

### ### ### ### ### ###

# FSLANAT_dir=$1 Atlas_dir=$2 GMP_dir=$3
sh ${SRC_DIR}/NVROX-GMPARCELS ${FSLANAT_dir} ${GMATLAS_DIR} ${GMPOutputDir}

### ### ### ### ### ###

EOF
		fi
		done<${SessionFileName}

done<${StudySubIDFile}
