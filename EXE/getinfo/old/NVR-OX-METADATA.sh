#####################URGENT TO DOs######################################################
# This is not super efficient to crawl each time -- write an indepent crawler
# parse the inputs
# 
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

PathUnProcParent="/data/output/habib/unprocessed/$StudyID"
PathProcParent="/data/output/habib/processed/$StudyID"

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
			FA_command="--nononlinreg --nosubcortseg"
			#sub-2okKlAKGz7_ses-V1_M2_run-1_PDT2_1.nii.gz
			ImageName=${SubID}_${Ses}_run-${RunID}_PDT2_1
		elif [ $ImgType == T22D ] ; then
			FA_ImageType=T2
			FA_command="--nononlinreg --nosubcortseg"
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
			echo "Missing: $Path_UnpImg" >> ${GitHubDataDir}/${StudyID}_${ImgType}_Missing.txt
		else
			GitHubDataDirSubSes=${GitHubDataDirSub}/${Ses}/anat
                	mkdir -p ${GitHubDataDirSubSes}
			echo "Exists: $Path_UnpImg" >> ${GitHubDataDir}/${StudyID}_${ImgType}_SubSes.txt
		fi
	
	done<$StudSubSesIDFile

done<$StudySubIDFile





##########################################################################################
##########################################################################################
##########################################################################################
