
StudyID=$1
ImgTyp_List=$2
#ImgTyp_List=(PD T12D T13D T12DCE T22D DWI BVAL BVEC)                                           │
#${ImgTyp_List[@]}

# FUNCTIONS ########################################
checkNget () {
## Get a wildcard, check whether it exists and return the number of files under that wildcard

DirExists=1
if ls $1 1> /dev/null 2>&1
then
        ls $1 | wc -l
else
	echo 0
	DirExists=0
fi
}

WhereIs () {
# Returns the index of an element
COUNTER=0
for ii in ${2[@]}
do
    if [ $ii == $1 ]; then
        IDX=$COUNTER
    fi
    COUNTER=$[$COUNTER +1]
done
}

########################################

echo ""
echo ""
echo "******** STUDY ID: ${StudyID} ******"

# Make a new directory
DataDir="${HOME}/NVROXBOX/Data"
StudyDir="${DataDir}/${StudyID}"
mkdir -p ${StudyDir}

# Text file for basic stats
BasicStudyInfoTxt=${StudyDir}/${StudyID}_BasicStudyInfoTxt.txt
rm -f $BasicStudyInfoTxt

##### Try for loops ####################


# This will be future ideal form:
#PD_WC="sub-*.*.*_ses-V*[0-9]_run-[0-9]_PD.nii.gz"
#T12D_WC="sub-*.*.*_ses-V*[0-9]_run-[0-9]_T1w.nii.gz"
#T13D_WC="sub-*.*.*_ses-V*[0-9]_acq-3d_run-[0-9]_T1w.nii.gz"
#T12DCE_WC="sub-*.*.*_ses-V*[0-9]_ce-Gd_run-[0-9]_T1w.nii.gz"
#T22D_WC="sub-*.*.*_ses-V*[0-9]_run-[0-9]_T2w.nii.gz"
#DWI_WC="sub-*.*.*_ses-V*[0-9]_run-[0-9]_dwi.nii.gz"
#BVEC_WC="sub-*.*.*_ses-V*[0-9]_run-[0-9]_dwi.bvec"
#BVAL_WC="sub-*.*.*_ses-V*[0-9]_run-[0-9]_dwi.bval"
#FLAIR_WC="sub-*.*.*_ses-V*[0-9]_run-[0-9]_FLAIR.nii.gz"
# There are two more types of data that I have not added yet: TMReference and FieldMaps!

#######################################################
#PD
PD_WC="sub-*_ses-V*[0-9]_run-[0-9]_PD.nii.gz"

#T1
T12D_WC="sub-*_ses-V*[0-9]_run-[0-9]_T1w.nii.gz"
T13D_WC="sub-*_ses-V*[0-9]_acq-3d_run-[0-9]_T1w.nii.gz"
T12DCE_WC="sub-*_ses-V*[0-9]_ce-Gd_run-[0-9]_T1w.nii.gz"

#T2
T22D_WC="sub-*_ses-V*[0-9]_run-[0-9]_T2w.nii.gz"

#FLAIR
FLAIR_WC="sub-*.*.*_ses-V*[0-9]_run-[0-9]_FLAIR.nii.gz"

#DWI
DWI_WC="sub-*_ses-V*[0-9]_run-[0-9]_dwi.nii.gz"
BVEC_WC="sub-*_ses-V*[0-9]_run-[0-9]_dwi.bvec"
BVAL_WC="sub-*_ses-V*[0-9]_run-[0-9]_dwi.bval"

######################################################

UnprocessedPath="/data/ms/unprocessed/mri"
BaseDir_WC="${UnprocessedPath}/${StudyID}.anon.*.*.*"
SubDir_WC="sub-*" # this should be "sub-${StudyID}.*.*"  but because we have shitty data structure which includes random SubIDs, that is not possible for now!!
SubSesDir_WC="*/*"

for ImgTyp in $ImgTyp_List
do

	echo "Made a new directory: ${StudyDir}/${ImgTyp}"
	ImgTypDir=${StudyDir}/${ImgTyp}
	mkdir -p ${ImgTypDir}

	# File name which consist *all* the paths of a given study for a given Image Type
	ImageFileTxt=${ImgTypDir}/${StudyID}_${ImgTyp}_ImageList.txt
	rm -f ${ImageFileTxt}

	eval TMP_WC='$'${ImgTyp}_WC
	TMP_Dir=${BaseDir_WC}/${SubDir_WC}/${SubSesDir_WC}/${TMP_WC}

	#echo $TMP_Dir
	NUMPD=`checkNget "$TMP_Dir"`
	echo "${ImgTyp} ${NUMPD}" >> $BasicStudyInfoTxt

	#Copy path to all available $ImgTyp images
	ls $TMP_Dir > $ImageFileTxt

	# Subject IDs of all images for a given image type
        ImageSubIDs=${ImgTypDir}/${StudyID}_${ImgTyp}_ImageSubIDs_tmp.txt
        rm -f ${ImageSubIDs}

	ImageUniqueSubIDs=${ImgTypDir}/${StudyID}_${ImgTyp}_ImageSubIDs.txt
	rm -f ${ImageUniqueSubIDs}

	echo "Subject IDs: ${ImageUniqueSubIDs}"

	# Save size of the images -- especially now that we have lots of 2D images
	ImageSizesTxtFile=${ImgTypDir}/${StudyID}_${ImgTyp}_ImageSizes.txt
	rm -f ${ImageSizesTxtFile}

	#Get Subject IDs of all images available for each wildcard
	# This should be changed in the near future as the subject IDs will no longer be the 
	# 7th entery in the data directory structures

	echo "Measuring the images sizes now..."
	while read Tmp_Img_Dir
        do
#		echo $Tmp_Img_Dir
		SubIDVar=$(echo $Tmp_Img_Dir | awk -F"/" '{print $7}')
         	echo ${SubIDVar} >> ${ImageSubIDs}
#		#Get the size of images as a array of 1x3
		echo "$SubIDVar $(fslinfo ${Tmp_Img_Dir} | sed -n 2p | awk '{ print $2 }') $(fslinfo ${Tmp_Img_Dir} | sed -n 3p | awk '{ print $2 }') $(fslinfo ${Tmp_Img_Dir} | sed -n 4p | awk '{ print $2 }')" >> $ImageSizesTxtFile
        done<$ImageFileTxt

#	cat ${ImageUniqueSubIDs} | wc -l 
	echo "Total number of $ImgTyp : `cat $ImageFileTxt | wc -l` "

	echo "Finding unique number subjects for image type: $ImgTyp"
        # Get the unique SubIDs whom has at least one ${ImgTyp} images
        cat ${ImageSubIDs} | sort -u > ${ImageUniqueSubIDs}
	rm -f ${ImageSubIDs} # now get rid of the tmp text file

	echo "Unique number of images with $ImgType : `cat $ImageUniqueSubIDs | wc -l` "

	echo "Get data longitudinal information..."

	#Logitudinal stuff------------
	SessionDir=${ImgTypDir}/Sessions
	mkdir -p ${SessionDir}

	echo "Made a new directory for longitudinal studies: ${SessionDir}"
#	SubSessionTxtFile=${SessionDir}/${StudyID}_${SubID}_${ImgTyp}.txt
#	rm -f $SubSessionTxtFile
#	cat $ImageUniqueSubIDs | wc -l


	FullSessionSubTxtFile=${SessionDir}/${StudyID}_FullSessionSubID_${ImgTyp}.txt
	rm -f $FullSessionSubTxtFile

	while read SubID
	do

		SubSessionTxtFile=${SessionDir}/${StudyID}_${SubID}_${ImgTyp}.txt
        	rm -f $SubSessionTxtFile

		LongSubDir=${BaseDir_WC}/${SubID}/*/*/$TMP_WC
		NumSes=$(ls $LongSubDir | wc -l)

		echo "${StudyID}, ${SubID}, ${ImgTyp}: ${NumSes}"

		if [ $NumSes -gt 1 ]; then
			ls $LongSubDir > $SubSessionTxtFile
			echo $SubID >> $FullSessionSubTxtFile
		else
			echo "There is only ${NumSes} sessions, so we skip."
		fi

	done<$ImageUniqueSubIDs

done

#########################################################################################
#########################################################################################
#########################################################################################
#########################################################################################

# Number of subjects -- this is not good, becuse if we add some non-subject directory to the study directory, it will be counted as subject!
#NUMSUB=`ls /data/output/habib/unprocessed/${StudyID}.anon.2019.07.15 | wc -l`
#echo "==Number of Subjects: ${NUMSUB}"
#echo SUB ${NUMSUB} >> $BasicStudyInfoTxt

#PD
#PD_Dir="/data/output/habib/unprocessed/${StudyID}.anon.2019.07.15/sub-${StudyID}.*.*/*/anat/sub-*.*.*_ses-V*[0-9]_run-[0-9]_PD.nii.gz"
#NUMPD=`checkNget "$PD_Dir"`
#echo PD2D ${NUMPD} >> $BasicStudyInfoTxt
#ls $PD_Dir > $PDImageFileTxt

#T1w - 2D
#T12D_Dir="/data/output/habib/unprocessed/${StudyID}.anon.2019.07.15/sub-${StudyID}.*.*/*/anat/sub-*.*.*_ses-V*[0-9]_run-[0-9]_T1w.nii.gz"
#NUMT12D=`checkNget "${T12D_Dir}"`
#echo T12D ${NUMT12D} >> $BasicStudyInfoTxt
#ls $T12D_Dir > $T12DImageFileTxt

#T1w - 3D
#T13D_Dir="/data/output/habib/unprocessed/${StudyID}.anon.2019.07.15/sub-${StudyID}.*.*/*/anat/sub-*.*.*_ses-V*[0-9]_acq-3d_run-[0-9]_T1w.nii.gz"
#NUMT13D=`checkNget "${T13D_Dir}"`
#echo T13D ${NUMT13D} >> $BasicStudyInfoTxt
#ls $T13D_Dir > $T13DImageFileTxt

#T1w - 2D - CE Gd
#T12DCE_Dir="/data/output/habib/unprocessed/${StudyID}.anon.2019.07.15/sub-${StudyID}.*.*/*/anat/sub-*.*.*_ses-V*[0-9]_ce-Gd_run-[0-9]_T1w.nii.gz"
#NUMT12DCE=`checkNget "${T12DCE_Dir}"`
#echo CEGd ${NUMT12DCE} >> $BasicStudyInfoTxt
#ls $T12DCE_Dir > $T12DCEImageFileTxt

#T2w
#T22D_Dir="/data/output/habib/unprocessed/${StudyID}.anon.2019.07.15/sub-${StudyID}.*.*/*/anat/sub-*.*.*_ses-V*[0-9]_run-[0-9]_T2w.nii.gz"
#NUMT22D=`checkNget "${T22D_Dir}"`
#echo T22D ${NUMT22D} >> $BasicStudyInfoTxt
#ls $T22D_Dir > $T22DImageFileTxt

#DWI # I should later check the bval and bvec images
#DWI_Dir="/data/output/habib/unprocessed/${StudyID}.anon.2019.07.15/sub-${StudyID}.*.*/*/dwi/sub-*.*.*_ses-V*[0-9]_run-[0-9]_dwi.nii.gz"
#NUMDWI=`checkNget "${DWI_Dir}"`
#echo DWI ${NUMDWI} >> $BasicStudyInfoTxt
#ls $DWI_Dir > $DWIImageFileTxt

#NUMBVEC=`checkNget "/data/output/habib/unprocessed/${StudyID}.anon.2019.07.15/sub-${StudyID}.*.*/*/dwi/sub-*.*.*_ses-V*[0-9]_run-[0-9]_dwi.bvec"`
#NUMBVAL=`checkNget "/data/output/habib/unprocessed/${StudyID}.anon.2019.07.15/sub-${StudyID}.*.*/*/dwi/sub-*.*.*_ses-V*[0-9]_run-[0-9]_dwi.bval"`
#echo "DWI: ${NUMDWI} ( Bvec: ${NUMBVEC} , Bvals: ${NUMBVAL})"

# PD T12D T13D T12DCE T22D DWI


#for ImgTyp in PD T12D T13D T12DCE T22D DWI
#do
#
#	PD_Dir="/data/output/habib/unprocessed/${StudyID}.anon.2019.07.15/sub-${StudyID}.*.*/*/anat/sub-*.*.*_ses-V*[0-9]_run-[0-9]_PD.nii.gz"
#	NUMPD=`checkNget "$PD_Dir"`
#	echo PD2D ${NUMPD} >> $BasicStudyInfoTxt
#	ls $PD_Dir > $PDImageFileTxt
#
#	ImageFileTxt=${StudyDir}/${ImgTyp}/${StudyID}_${ImgTyp}_ImageList.txt
#	ImageUniqueSubIDs=${StudyDir}/${ImgTyp}/${StudyID}_${ImgTyp}_ImageSubIDs.txt
#	rm -f ${ImageUniqueSubIDs}
#
#	while read Tmp_Img_Dir
#	do
# 		echo $Tmp_Img_Dir | awk -F"/" '{print $7}' >> ${PDImageSubIDs}
#	done<$ImageFileTxt
#
#	# Get the unique SubIDs whom has at least one ${ImgTyp} images
#	cat ${PDImageSubIDs} | sort -u > $ImageUniqueSubIDs
#done

# Find Subject ID of all PD images ######################################
#PDImageSubIDs=${StudyDir}/PD/PDImageSubIDs.txt
#rm -f $PDImageSubIDs
#while read Tmp_Img_Dir
#do
#	echo $Tmp_Img_Dir | awk -F"/" '{print $7}' >> ${PDImageSubIDs}
#done<$PDImageFileTxt

# Get the unique SubIDs whom has the PD images 
#cat ${PDImageSubIDs} | sort -u > PDImageSubIDs

# Find Subject ID of all T12D images #####################################
#PDImageSubIDs=${StudyDir}/T12D/T12DImageSubIDs.txt
#rm -f $PDImageSubIDs
#while read Tmp_Img_Dir
#do
#  	echo $Tmp_Img_Dir | awk -F"/" '{print $7}' >> ${T12DImageSubIDs}
#done<$T12DImageFileTxt

# Get the unique SubIDs whom has the T12D images 
#cat ${T12DImageSubIDs} | sort -u > T12DImageSubIDs

# Find Subject ID of all T13D images ####################################
#T13DImageSubIDs=${StudyDir}/T13D/T13DImageSubIDs.txt
#rm -f $T13DImageSubIDs
#while read Tmp_Img_Dir
#do
#  	echo $Tmp_Img_Dir | awk -F"/" '{print $7}' >> ${T13DImageSubIDs}
#done<$T13DImageFileTxt

# Get the unique SubIDs whom has the T13D images
#cat ${T13DImageSubIDs} | sort -u > $T13DImageSubIDs


# Find Subject ID of all T12DCE images ###################################
#T12DCEImageSubIDs=${StudyDir}/T12DCE/T12DCEImageSubIDs.txt
#rm -f $T12DCEImageSubIDs
#while read Tmp_Img_Dir
#do
#  	echo $Tmp_Img_Dir | awk -F"/" '{print $7}' >> ${PDImageSubIDs}
#done<$T12DCEImageFileTxt

# Get the unique SubIDs whom has the T12DCE images
#cat ${T12DCEImageSubIDs} | sort -u > $T12DCEImageSubIDs


# Find Subject ID of all T22D images ##################################
#T22DImageSubIDs=${StudyDir}/T22D/T22DImageSubIDs.txt
#rm -f $T22DImageSubIDs
#while read Tmp_Img_Dir
#do
#  	echo $Tmp_Img_Dir | awk -F"/" '{print $7}' >> ${T22DImageSubIDs}
#done<$T22DImageFileTxt

# Get the unique SubIDs whom has the T22D images
#cat ${T22DImageSubIDs} | sort -u > $T22DImageSubIDs

# Find Subject ID of all DWI images ##################################
#DWIImageSubIDs=${StudyDir}/DWI/DWIImageSubIDs.txt
#rm -f $DWIImageSubIDs
#while read Tmp_Img_Dir
#do
#  	echo $Tmp_Img_Dir | awk -F"/" '{print $7}' >> ${DWIImageSubIDs}
#done<$DWIImageFileTxt

# Get the unique SubIDs whom has the DWI images
#cat ${DWIImageSubIDs} | sort -u > $DWIImageSubIDs



# Parse SubjectIDs of specific image type?
# to parse the file path 
# SubID=$(echo $DirName | awk -F"/" '{print $7}')
# SesID=$(echo $DirName | awk -F"/" '{print $8}')
# TypeID=$(echo $DirName | awk -F"/" '{print $9}')
# ImageName=$(echo $DirName | awk -F"/" '{print $10}')
