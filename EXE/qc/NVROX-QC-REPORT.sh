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

QCType_List=(PASSED TENTATIVE FAILED)

REPORTFILE=/data/ms/processed/mri/QC/${StudyID}/${DirSuffix}_${ImageName}/${StudyID}_${DirSuffix}_${ImageName}_Report.txt
echo "SubID_Session Quality" > $REPORTFILE #This will also clean the text file -- don't use rm!!
echo "Report will be on: ${REPORTFILE}"

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

	COUNTER=$[$COUNTER +1]
done

NUMFILE=$(cat $REPORTFILE | wc -l )
echo "Total: $(($NUMFILE-1))"

}


#####################################################################################
#####################################################################################
#####################################################################################


#MAIN

while read StudyIDClean
do
	#FS -- AUTOCRECONN
	echo "DOING $StudyIDClean autorecon12 norm_RAS"
	WriteMeDownAQCReport $StudyIDClean autorecon12 norm_RAS

done</home/bdivdi.local/dfgtyk/NVROXBOX/EXE/getinfo/StudyIDs_Clean.txt
