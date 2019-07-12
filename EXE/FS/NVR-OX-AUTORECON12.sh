#This should later be in a loop around StudyIDs
StudyID=CFTY720D2201E2

ImgType=$1 # Here we only use T13D and T12D

RunID=1

set -e

Mem=5G
Time="30:00"

DirSuffix="AUTORECON12"

PathProcParent="/data/output/habib/processed/${StudyID}"

#SRC_DIR="${HOME}/NVROXBOX/SOURCE"
#GMATLAS_DIR="${HOME}/NVROXBOX/SOURCE/atlas/GMatlas"

# These info should be already available via getinfo scripts
GitHubDataDir="${HOME}/NVROXBOX/Data/${StudyID}"
StudySubIDFile="${GitHubDataDir}/SubDirID_${StudyID}.txt"

#Submitter files, just save the path to them for future mass re-producing
SubmitterPath="${GitHubDataDir}/SLUMR_${DirSuffix}_Submitters_${StudyID}_${ImgType}.txt"
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

		# Reconstruct the directory name
                InputDir=$PathUnProcParent/$SubID/$Ses/anat/${ImageName}.nii.gz

#===================================================================
# This section is suitable for when you wanna check whether a dependency is available or not
		#FSAUTORECON_dir=${PathProcParent}/${SubID}/${Ses}/anat/${ImageName}.${DirSuffix}
    		# Check whether the file actually exists
    		#if [ ! -d $FSAUTORECON_dir ];
    		#then
    		#	echo "**** File Does Not Exist ***** ";
        	#	echo "" >> 
		#	continue
		#else
#===================================================================

			OutputDir=${PathProcParent}/${SubID}/${Ses}/anat/${ImageName}.${DirSuffix}

			GitHubDataDirSubGMP=${GitHubDataDirSub}/${Ses}/anat/${DirSuffix}
			mkdir -p ${GitHubDataDirSubGMP}

			JobName=${StudyID}_${ImageName}_${DirSuffix}
        		SubmitterFileName="${GitHubDataDirSub}/SubmitMe_${JobName}.sh"
        		echo "${SubmitterFileName}" >> $SubmitterPath

cat > $SubmitterFileName << EOF
#!/bin/bash
#SBATCH --partition=main
#SBATCH --job-name=${JobName}
#SBATCH --mem=${Mem}
#SBATCH --time=${Time}
#SBATCH --output=${GitHubDataDirSub}/${JobName}.out
#SBATCH --error=${GitHubDataDirSub}/${JobName}.err

mkdir -p ${OutputDir} 

### ### ### ### ### ###

ml FreeSurfer

recon-all  ${OutputDir} ${InputDir}

### ### ### ### ### ###

EOF
		fi
		done<${SessionFileName}

done<${StudySubIDFile}
