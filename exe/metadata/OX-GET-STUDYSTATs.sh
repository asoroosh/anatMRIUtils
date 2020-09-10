#!/bin/bash
#
#
# Soroosh Afyouni, University of Oxford, 2020
#
#Copyright (c) 2020
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

StudyID=$1
ImgTyp_List=$2
#ImgTyp_List=(PD T12D T13D T12DCE T22D DWI BVAL BVEC)
#${ImgTyp_List[@]}

# FUNCTIONS ########################################
#checkNget () {
## Get a wildcard, check whether it exists and return the number of files under that wildcard
#
#DirExists=1
#if ls $1 1> /dev/null 2>&1
#then
#        ls $1 | wc -l
#else
#	echo 0
#	DirExists=0
#fi
#}
#
#WhereIs () {
# Returns the index of an element
#COUNTER=0
#for ii in ${2[@]}
#do
#    if [ $ii == $1 ]; then
#        IDX=$COUNTER
#    fi
#    COUNTER=$[$COUNTER +1]
#done
#}

########################################

echo ""
echo ""
echo "******** STUDY ID: ${StudyID} ******"

#NVSHOME=$HOME
#source ${NVSHOME}/NVROXBOX/AUX/Config/nvr-ox-path-setup-fromrescomp.nvsoxconfig
source ${NVSOX_AUX_CONFIGFILE_PATH}

StudyDir="${DataDir}/${StudyID}"
mkdir -p ${StudyDir}

# Text file for basic stats
BasicStudyInfoTxt=${StudyDir}/${StudyID}_BasicStudyInfoTxt.txt
rm -f $BasicStudyInfoTxt

##### Try for loops ####################

#######################################################
#T1
#T12D_WC="sub-*_ses-V*[0-9]_run-[0-9]_T1w.nii.gz"
#T12D_WC="sub-${StudyID}x*x*_ses-V*x*[0-9]_run-[0-9]_T1w.nii.gz"
T12D_WC="sub-${StudyID}x*_ses-*x*[0-9]_run-[0-9]_T1w.nii.gz"
######################################################

BaseDir_WC="${GetInfoUnprocessedPath}/${StudyID}"
SubDir_WC="sub-*"
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

	ImageSubIDSesIDsModIDImgName=${ImgTypDir}/${StudyID}_${ImgTyp}_ImageSubSesID.txt
	rm -f ${ImageSubIDSesIDsModIDImgName}

	#The main table we later use to query
	ImageSubIDSesIDsModIDImgNameSesNum=${ImgTypDir}/${StudyID}_${ImgTyp}_ImageSubSesID.table
	rm -f ${ImageSubIDSesIDsModIDImgNameSesNum}

	ImageUniqueSubIDs=${ImgTypDir}/${StudyID}_${ImgTyp}_ImageSubIDs.txt
	rm -f ${ImageUniqueSubIDs}

	echo "Subject IDs: ${ImageUniqueSubIDs}"

	# Save size of the images -- especially now that we have lots of 2D images
	ImageSizesTxtFile=${ImgTypDir}/${StudyID}_${ImgTyp}_ImageSizes.txt
	rm -f ${ImageSizesTxtFile}

	#Get Subject IDs of all images available for each wildcard
	# This should be changed in the near future as the subject IDs will no longer be the 
	# 7th entery in the data directory structures


	AA=$(echo "${UnprocessedPath}" | awk -F"/" '{print NF-1}'); AA=$((AA+1))

	echo "Measuring the images sizes now..."
	while read Tmp_Img_Dir
        do
#		echo $Tmp_Img_Dir
		SubIDVar=$(echo $Tmp_Img_Dir | awk -F"/" -v xx=$((AA+2)) '{print $xx}')
         	echo ${SubIDVar} >> ${ImageSubIDs}
#		#Get the size of images as a array of 1x3
#		echo "$SubIDVar $(fslinfo ${Tmp_Img_Dir} | sed -n 2p | awk '{ print $2 }') $(fslinfo ${Tmp_Img_Dir} | sed -n 3p | awk '{ print $2 }') $(fslinfo ${Tmp_Img_Dir} | sed -n 4p | awk '{ print $2 }')" >> $ImageSizesTxtFile

		#StudyIDVar=$(echo $Tmp_Img_Dir | awk -F"/" -v xx=$((AA+1)) '{print $xx}') # Study ID
		#SubIDVar=$(echo $Tmp_Img_Dir | awk -F"/" -v xx=$((AA+2)) '{print $xx}') # Sub ID
		SesIDVar=$(echo $Tmp_Img_Dir | awk -F"/" -v xx=$((AA+3)) '{print $xx}') # Session ID
		SesDate=$(echo $SesIDVar | awk -F"x" '{print $2}')
		ModIDVar=$(echo $Tmp_Img_Dir | awk -F"/" -v xx=$((AA+4)) '{print $xx}') #Modality type: anat, dwi etc
		ImgNameEx=$(echo $Tmp_Img_Dir | awk -F"/" -v xx=$((AA+5)) '{print $xx}') #ImageName with extension

		ImgName=$(basename ${ImgNameEx} .nii.gz)
		RunID=$(echo $ImgName | awk -F"_" '{print $3}')
		IMAGETTYPE=$(echo $ImgName | awk -F"_" '{print $4}')

		echo "${SubIDVar} ${SesIDVar} ${SesDate} ${ModIDVar} ${RunID} ${IMAGETTYPE} ${ImgTyp} ${ImgName}" >> ${ImageSubIDSesIDsModIDImgName}

        done<$ImageFileTxt

#	cat ${ImageUniqueSubIDs} | wc -l 
	echo "Total number of $ImgTyp : `cat $ImageFileTxt | wc -l` "

	echo "Finding unique number subjects for image type: $ImgTyp"
        # Get the unique SubIDs whom has at least one ${ImgTyp} images
        cat ${ImageSubIDs} | sort -u > ${ImageUniqueSubIDs}
	rm -f ${ImageSubIDs} # now get rid of the tmp text file

	echo "Unique number of subjects with $ImgTyp : `cat $ImageUniqueSubIDs | wc -l` "

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

			cat ${ImageSubIDSesIDsModIDImgName} | grep ${SubID} | while read SubIDSesIDVAR
			do
				echo "${SubIDSesIDVAR} ${NumSes}" >> ${ImageSubIDSesIDsModIDImgNameSesNum}
			done


		else
			echo "There is only ${NumSes} sessions, so we skip."
		fi

	done<$ImageUniqueSubIDs


#	MAXSES=$(cat $(wc -l ${SessionDir}/${StudyID}_sub-${StudyID}x* | grep _sub- | awk -v max=0 '{if($1>max){want=$2; max=$1}}END{print want} ') | wc -l)
#	AVGSES=${SessionDir}/${StudyID}_sub-${StudyID}x* | grep _sub- | awk '{ total += $2 } END { print total/NR }'
#	echo "TRIAL: ${StudyID}"
#	echo ""
#	echo "===========================REPORT "
#	echo "Average T1w sessions per subject: "
#	echo "Maximum number of session for a subject: "
#	echo "Total Number of subjects: "
#	echo "Total Number of sessions: "
done

#########################################################################################
#########################################################################################
#########################################################################################
#########################################################################################



