set -e


StudyID=$1
ImgTyp_List=$2

# FUNCTIONS ########################################
function checkNget () {
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

#---------------

function WhereIs () {
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

#---------------

function ami_there() {
arrgs=("$@")
mmmval=${arrgs[-1]}
NUMSES0=${#arrgs[@]}
check=0
for i in $(seq 0 $((NUMSES0-2)) )
do
        if [[ ${arrgs[i]} =~ $mmmval ]]; then
                check=1;
        fi
done
echo ${check}
}

########################################

echo ""
echo ""
echo "******** STUDY ID: ${StudyID} ******"

# Make a new directory
DataDir="/home/bdivdi.local/dfgtyk/NVROXBOX/Data/RELAB"
StudyDir="${DataDir}/${StudyID}"
mkdir -p ${StudyDir}

# Text file for basic stats
BasicStudyInfoTxt=${StudyDir}/${StudyID}_BasicStudyInfoTxt.txt
rm -f $BasicStudyInfoTxt

##### Exclude lists ####################
# CFTY720D2201  CFTY720D2301  CFTY720D2309
case $StudyID in
"CFTY720D2201")
  echo "CASE ON CFTY720D2201"
	IncludeList=(V2 V10 V15 V17)
#	ExcludeList=(V5 V6 V7 V8 V9 V12 V16 V999)
#	IncludeList=(V2 V10 V15 V17) #V19 V23 V27 V31 V35 V779)
  ;;
"CFTY720D2301")
  echo "CASE ON CFTY720D2301"
	IncludeList=(V1 V7 V9 V778)
  ;;
"CFTY720D2309")
  echo "CASE ON CFTY720D2309"
	IncludeList=(V1 V8 V10 V777)
  ;;
*)
  echo "ERROR: Unknown StudyID"
	exit 1
  ;;
esac

echo "=== INCLUDED SESSIONS:"
echo ${IncludeList[@]}

#######################################################

#T1
T12D_WC="sub-${StudyID}x*x*_ses-V*x*[0-9]_run-[0-9]_T1w.nii.gz"
T13D_WC="sub-*_ses-V*_acq-3d_run-[0-9]_T1w.nii.gz"
T12DCE_WC="sub-*_ses-V*_ce-Gd_run-[0-9]_T1w.nii.gz"

######################################################

UnprocessedPath="/data/ms/unprocessed/mri/relabelled/sesVISITYYYYMMDD"
BaseDir_WC="${UnprocessedPath}/${StudyID}"
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
		SubIDVar=$(echo $Tmp_Img_Dir | awk -F"/" '{print $9}')
         	echo ${SubIDVar} >> ${ImageSubIDs}
		#Get the size of images as a array of 1x3
#		echo "$SubIDVar $(fslinfo ${Tmp_Img_Dir} | sed -n 2p | awk '{ print $2 }') $(fslinfo ${Tmp_Img_Dir} | sed -n 3p | awk '{ print $2 }') $(fslinfo ${Tmp_Img_Dir} | sed -n 4p | awk '{ print $2 }')" >> $ImageSizesTxtFile
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

	SingletonSubjectsDir=${SessionDir}/Singletons
	rm -rf ${SingletonSubjectsDir}
	mkdir -p ${SingletonSubjectsDir}

	while read SubID
	do
		SubSessionTxtFile=${SessionDir}/${StudyID}_${SubID}_${ImgTyp}.txt
        	rm -f $SubSessionTxtFile
		touch $SubSessionTxtFile

		LongSubDir=${BaseDir_WC}/${SubID}/*/*/$TMP_WC
		NumSes=$(ls $LongSubDir | wc -l)

		echo "${StudyID}, ${SubID}, ${ImgTyp}: ${NumSes}"

		SessionPaths=$(ls $LongSubDir)
		#SessionPaths0=$SessionPaths

		#echo ${#SessionPaths[@]}
		echo "Number of sessions before exclusion: ${NumSes}"

		i=0
		for SessionP in ${SessionPaths}; do
			SesID=$(echo $SessionP | awk -F"/" '{print $10}')
			SesID0=$(echo $SesID | awk -F"-" '{print $2}')
			SesID0=$(echo $SesID0 | awk -F"x" '{print $1}')
			SesFlag=$(ami_there "${IncludeList[@]}" "${SesID0}")

			if [ $SesFlag == 1 ] ; then
				echo $SessionP >> $SubSessionTxtFile
				i=$((i+1))
			fi
		done

#		echo "DONE"

		NumSessFinal=$(cat $SubSessionTxtFile | wc -l)

		if [ ${i} -gt 1 ]; then
			echo "Number of sessions after exclusion: ${i}"
			echo "Number of sessions after exclusion: ${NumSessFinal}"
			echo $SubID >> $FullSessionSubTxtFile
		else
			echo "ONLY ONE SESSION AVAILABLE -- WILL REMOVE!"
			rm $SubSessionTxtFile
		fi

	done<$ImageUniqueSubIDs
done

#########################################################################################
#########################################################################################
#########################################################################################
#########################################################################################

