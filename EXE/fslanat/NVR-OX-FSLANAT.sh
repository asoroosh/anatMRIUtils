#This should later be in a loop around StudyIDs
StudyID=CFTY720D2201E2

Mem=5G
Time="30:00"

# One of the following: T13D T12D T22D PD2D
#ImgType=PD2D

ImgType=$1

echo "Image type::: $ImgType"

#For later use...###########################
#if [ X$ImgType== X ] ; then
#	ImgType=T13D
#fi
###########################

# It is always 1 for all subjects?!
RunID=1

#This is pending until the copy dilemma is resolved
PathUnProcParent="/data/output/habib/unprocessed/$StudyID"
PathProcParent="/data/output/habib/processed/$StudyID"

##########################################################################################
##########################################################################################
##########################################################################################


GitHubDataDir="/home/bdivdi.local/dfgtyk/NVROXBOX/Data/${StudyID}"

mkdir -p ${GitHubDataDir}
mkdir -p ${GitHubDataDir}/Sessions

StudySubIDFile="${GitHubDataDir}/SubDirID_$StudyID.txt"
# Make sure there aren't another version of this file
rm -f $StudySubIDFile
ls -d $PathUnProcParent/sub-*/ >> $StudySubIDFile

# Just to record the SubIDs & their sessions availab:
StudySubSesIDFile="${GitHubDataDir}/SubID_$StudyID.txt"
# Make sure there aren't another version of this file
rm -f ${StudySubSesIDFile}

#Submitter files, just save the path to them for future mass re-producing
SubmitterPath="${GitHubDataDir}/SLUMR_Submitters_$StudyID_$ImgType.txt"
rm -f ${SubmitterPath}

while read SubID
do
	# Get the SubID from the directory path
	SubID=`basename $SubID`
	echo "For Subject: $SubID ========================================"

	echo "S: $SubID" >> $StudySubSesIDFile

	# crawl into the subject directory and find how many sessions are available
	StudSubSesIDFile="${GitHubDataDir}/Sessions/${StudyID}_${SubID}_Sessions.txt"
	# Make sure there aren't another version of this file
	rm -f $StudSubSesIDFile
	ls -d $PathUnProcParent/$SubID/*/ >> $StudSubSesIDFile 
	
        GitHubDataDirSub=$GitHubDataDir/$SubID
        mkdir -p $GitHubDataDirSub

	#Loop around the available sessions of $SubID
	while read Ses
	do
		# Get the session ID from the path directory
		Ses=`basename $Ses`

		echo "R: $Ses" >> $StudySubSesIDFile

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


		#Remove this later, just for sanity check
		echo ${ImageName}

		# Reconstruct the directory name
		Path_UnpImg=$PathUnProcParent/$SubID/$Ses/anat/${ImageName}.nii.gz
		
		# Check whether the file actually exists
		if [ ! -f $Path_UnpImg ]; 
		then 
			echo "**** File Does Not Exist ***** "; 
			echo "Missing: $Path_UnpImg" >> ${GitHubDataDir}/EmptyDir_${StudyID}.txt
		else

			#============================================
			# Just for now until the permission is sorted
			#if [ ! -r $PathUnProcParent/$SubID/ ]
			#then 		
			#	echo "!!"
			#	echo `ls -lsh ${PathUnProcParent}/${SubID}` >> ${GitHubDataDir}/${StudyID}_NoReadPermit.txt
			#	continue
			#fi
			#===========================================

			GitHubDataDirSubSes=${GitHubDataDirSub}/${Ses}/anat
                	mkdir -p ${GitHubDataDirSubSes}

			#If it does, make an $FILENAME.anat directory
			Path_ProImg=$PathProcParent/$SubID/$Ses/anat/${ImageName}

			echo $Path_UnpImg
                	echo $Path_ProImg

			JobName=${StudyID}_${ImageName}
			SubmitterFileName="${GitHubDataDirSubSes}/SubmitMe_${JobName}.sh"
			echo "${SubmitterFileName}" >> $SubmitterPath

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

# Prior to this point we do *not* have a directory for this sub/ses in the processed directory:
mkdir -p ${PathProcParent}/${SubID}/${Ses}/anat/

## fsl_anat code goes here ## ## ## 

$FSLDIR/bin/fsl_anat -i $Path_UnpImg -o $Path_ProImg

## ## ## ## ## ## ## ## ## ## ## ##

EOF

		fi
	
	done<$StudSubSesIDFile

done<$StudySubIDFile

##########################################################################################
##########################################################################################
##########################################################################################
