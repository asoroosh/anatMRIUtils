# Use this after you have done the visual QC and saved the csv files in the Download folder.
# This will take the csv files in the Download directory and make a csv report out of them.
# Then saves them into the processed QC folder.
# NB! Order of the images/sessions are not sorted.

#FUNCTIONS
#####################################################################################
#####################################################################################
#####################################################################################

WriteMeDownAQCReport() {

StudyID=$1
DirSuffix=$2
ImageName=$3


echo "WRITE DOWN A REPORT FOR: $StudyID  $DirSuffix  $ImageName"

QCType_List=(PASSED TENTATIVE FAILED)

REPORTFILE=/data/ms/processed/mri/QC/${StudyID}/${DirSuffix}_${ImageName}/${StudyID}_${DirSuffix}_${ImageName}_Report.txt
echo "SubID_Session Quality" > $REPORTFILE #This will also clean the text file -- don't use rm!!
echo "Report will be on: ${REPORTFILE}"

SUMMARYFILE=/data/ms/processed/mri/QC/${StudyID}/${DirSuffix}_${ImageName}/${StudyID}_${DirSuffix}_${ImageName}_Summary.txt
echo "" > $SUMMARYFILE # clean up the file -- don't use rm!

COUNTER=1
for QCType in ${QCType_List[@]}
do
	QCFileName=${HOME}/Downloads/${StudyID}_${DirSuffix}_${ImageName}_0_$QCType.csv
#	echo "Read from: ${QCFileName}"


	if [ ! -f $QCFileName ]; then
		echo "ERROR: There is not such a file! You should do the visual QC first!"
		exit 1
	fi


	IFS=","
	read -ra QC <<< `cat $QCFileName`
	IFS=" "

	QCType_COUNTER=0
	for Sub in ${QC[@]}; do
#		echo "$Sub $COUNTER"
		echo "$Sub $COUNTER" >> $REPORTFILE
		QCType_COUNTER=$[$QCType_COUNTER +1]
	done

	echo "$QCType: $QCType_COUNTER"
	echo "$QCType: $QCType_COUNTER" >> $SUMMARYFILE

	COUNTER=$[$COUNTER +1]
done

NUMFILE=$(cat $REPORTFILE | wc -l )
echo "Total: $(($NUMFILE-1))"
echo "Total: $(($NUMFILE-1))" >> $SUMMARYFILE

unset IFS
}

#####################################################################################
#####################################################################################
#####################################################################################


#MAIN

DirSuffixList=(ants fslanat autorecon12)
ImageNameList=(BrainExtractionBrain T1_biascorr_brain norm_RAS)

while read StudyIDClean
do
	echo "== $StudyIDClean ====================================="
	for FileName_cnt in $(seq 0 2)
	do
		DirSuffixVar=${DirSuffixList[FileName_cnt]}
		ImageNameVar=${ImageNameList[FileName_cnt]}

		echo "$FileName_cnt -- DOING $StudyIDClean $DirSuffixVar $ImageNameVar"
		WriteMeDownAQCReport $StudyIDClean $DirSuffixVar $ImageNameVar
	#	unset IFS
	done

done</home/bdivdi.local/dfgtyk/NVROXBOX/EXE/getinfo/StudyIDs_Clean.txt
