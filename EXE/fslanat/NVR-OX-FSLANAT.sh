#####################URGENT TO DOs######################################################
# This is not super efficient to crawl each time -- write an indepent crawler
# parse the inputs 
#######################################################################################

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

SOURCEPATH="${HOME}/NVROXBOX/SOURCE"

GitHubDataDir="${HOME}/NVROXBOX/Data/${StudyID}"

StudySubIDFile="${GitHubDataDir}/SubDirID_$StudyID.txt"

#Submitter files, just save the path to them for future mass re-producing
SubmitterPath="${GitHubDataDir}/SLUMR_FSLANAT_Submitters_${StudyID}_${ImgType}.txt"
rm -f ${SubmitterPath}

while read SubID
do
	# Get the SubID from the directory path
	SubID=`basename $SubID`
	echo "For Subject: $SubID ========================================"

	StudSubSesIDFile="${GitHubDataDir}/Sessions/${StudyID}_${SubID}_Sessions.txt"
		
        GitHubDataDirSub=$GitHubDataDir/$SubID
        mkdir -p $GitHubDataDirSub

	#Loop around the available sessions of $SubID
	while read Ses
	do
		# Get the session ID from the path directory
		Ses=`basename $Ses`

		#Image Name
		if [ $ImgType == T13D ] ; then
			FA_ImageType=T1
			FA_command=''
			#sub-2okKlAKGz7_ses-V1_M2_acq-3d_run-1_T1w.nii.gz
                	ImageName=${SubID}_${Ses}_acq-3d_run-${RunID}_T1w
		elif [ $ImgType == T12D ] ; then
			FA_ImageType=T1 
			#sub-2okKlAKGz7_ses-V1_M2_run-1_T1w.nii.gz
			ImageName=${SubID}_${Ses}_run-${RunID}_T1w
		elif [ $ImgType == PD2D ] ; then
			FA_ImageType=PD
			FA_command="--nononlinreg --nosubcortseg --noseg"
			#sub-2okKlAKGz7_ses-V1_M2_run-1_PDT2_1.nii.gz
			ImageName=${SubID}_${Ses}_run-${RunID}_PDT2_1
		elif [ $ImgType == T22D ] ; then
			FA_ImageType=T2
			FA_command="--nononlinreg --nosubcortseg --noseg"
		        #sub-2okKlAKGz7_ses-V1_M2_run-1_PDT2_2.nii.gz
                        ImageName=${SubID}_${Ses}_run-${RunID}_PDT2_2
		else
			# throw an error and halt here
			echo "$ImgType is unrecognised"
		fi

# SANITY CHECK ###################################
#============================================#============================================#================================
		#Remove this later, just for sanity check
		echo ${ImageName}

		# Reconstruct the directory name
		Path_UnpImg=$PathUnProcParent/$SubID/$Ses/anat/${ImageName}.nii.gz
		
		# Check whether the file actually exists
		if [ ! -f $Path_UnpImg ]; 
		then 
			echo "**** File Does Not Exist ***** "; 
		#
		#	
		#	echo "Missing: $Path_UnpImg" >> ${GitHubDataDir}/EmptyDir_${StudyID}_${ImgType}.txt
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
#============================================#============================================#================================

			GitHubDataDirSubSes=${GitHubDataDirSub}/${Ses}/anat
                	mkdir -p ${GitHubDataDirSubSes}

			#If it does, make an $FILENAME.anat directory
			Path_ProImg=${PathProcParent}/${SubID}/${Ses}/anat/${ImageName}

	                if [ ! -d ${Path_ProImg}.anat ];
	                then
				echo "${Path_ProImg} == does not exists, the script will make one."	
			else
				echo "${Path_ProImg} already exists, we use --clobber to remove and remake it."
				FA_command="${FA_command} --clobber"
			fi

			echo $Path_UnpImg
                	echo $Path_ProImg

			JobName=${StudyID}_${ImageName}
			SubmitterFileName="${GitHubDataDirSubSes}/SubmitMe_${JobName}.sh"
			echo "${SubmitterFileName}"
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

# $FSLDIR/bin/fsl_anat 

sh ${SOURCEPATH}/NVR-OX-FSLANAT.sh -i $Path_UnpImg -t ${FA_ImageType} ${FA_command} -o ${Path_ProImg}

## ## ## ## ## ## ## ## ## ## ## ##

EOF

		fi
	
	done<$StudSubSesIDFile

done<$StudySubIDFile

##########################################################################################
##########################################################################################
##########################################################################################
