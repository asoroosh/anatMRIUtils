#This should later be in a loop around StudyIDs
StudyID=CFTY720D2201E2

ImgType=$1

RunID=1

set -e

Mem=5G
Time="30:00"

PathProcParent="/data/output/habib/processed/$StudyID"

GitHubDataDir="/home/bdivdi.local/dfgtyk/NVROXBOX/Data/${StudyID}"
StudySubIDFile="${GitHubDataDir}/SubDirID_${StudyID}.txt"

#Submitter files, just save the path to them for future mass re-producing
SubmitterPath="${GitHubDataDir}/SLUMR_SIENAX_Submitters_${StudyID}_${ImgType}.txt"
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
		
		elif [ $ImgType == PD2D ] ; then
                	#sub-2okKlAKGz7_ses-V1_M2_run-1_PDT2_1.nii.gz
                	ImageName=${SubID}_${Ses}_run-${RunID}_PDT2_1

        	elif [ $ImgType == T22D ] ; then
                	#sub-2okKlAKGz7_ses-V1_M2_run-1_PDT2_2.nii.gz
        		ImageName=${SubID}_${Ses}_run-${RunID}_PDT2_2
        	else
                	# throw an error and halt here
                	echo "$ImgType is unrecognised"
        	fi

		ImageDirName=${PathProcParent}/${SubID}/${Ses}/anat/${ImageName}.anat/T1_to_MNI_nonlin.nii.gz

                # Check whether the file actually exists
                if [ ! -f $ImageDirName ];
                then
                    	echo "**** File Does Not Exist ***** ";
                        echo "Missing: $ImageDirName" >> ${GitHubDataDir}/EmptyDir_SIENAX_${StudyID}_${ImgType}.txt		
			continue
		else
		

			SienaXOutputDir=${PathProcParent}/${SubID}/${Ses}/anat/${ImageName}.sienax

			GitHubDataDirSubSiena=${GitHubDataDirSub}/${Ses}/anat/sienax
			mkdir -p ${GitHubDataDirSubSiena}	

			JobName=${StudyID}_${ImageName}_SienaX
        		SubmitterFileName="${GitHubDataDirSubSiena}/SubmitMe_${JobName}.sh"
        		echo "${SubmitterFileName}" >> $SubmitterPath

cat > $SubmitterFileName << EOF
#!/bin/bash
#SBATCH --partition=main
#SBATCH --job-name=${JobName}
#SBATCH --mem=${Mem}
#SBATCH --time=${Time}
#SBATCH --output=${GitHubDataDirSubSiena}/${JobName}.out
#SBATCH --error=${GitHubDataDirSubSiena}/${JobName}.err

mkdir -p ${SienaXOutputDir}

### ### ### ### ### ###
${FSLDIR}/bin/sienax ${ImageDirName} -o ${SienaXOutputDir}
### ### ### ### ### ###

EOF
		fi
		done<${SessionFileName}

done<${StudySubIDFile}
