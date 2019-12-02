# Use this after you have done the visual QC and saved the csv files in the Download folder.
# This will take the csv files in the Download directory and make a csv report out of them.
# Then saves them into the processed QC folder.
# NB! Order of the images/sessions are not sorted.

#FUNCTIONS
#####################################################################################
#####################################################################################
#####################################################################################
TransposeMe () {

awk '
{
    for (i=1; i<=NF; i++)  {
        a[NR,i] = $i
    }
}
NF>p { p = NF }
END {
    for(j=1; j<=p; j++) {
        str=a[1,j]
        for(i=2; i<=NR; i++){
            str=str" "a[i,j];
        }
        print str
    }
}' $1
}


WriteMeDownAQCReport() {

StudyID=$1
DirSuffix=$2
NSUB=$3

echo "WRITE DOWN A REPORT FOR: $StudyID  $DirSuffix  $ImageName"

QCType_List=(FAILED-SST FAILED-RAW PASSED CHECK)

mkdir -p /rescompdata/ms/unprocessed/RESCOMP/QC/REPORTS/${StudyID}/${DirSuffix}

REPORTFILE=/rescompdata/ms/unprocessed/RESCOMP/QC/REPORTS/${StudyID}/${DirSuffix}/${StudyID}_${DirSuffix}_Report.txt
echo "SubID_Session Quality" > $REPORTFILE #This will also clean the text file -- don't use rm!!
echo "Report will be on: ${REPORTFILE}"

SUMMARYFILE=/rescompdata/ms/unprocessed/RESCOMP/QC/REPORTS/${StudyID}/${DirSuffix}/${StudyID}_${DirSuffix}_Summary.txt
echo "" > $SUMMARYFILE # clean up the file -- don't use rm!

COUNTER=1
for QCType in ${QCType_List[@]}
do
	for BreakPoint in $(seq 0 200 $NSUB); do
#		echo ${QCType} ${BreakPoint}
		QCFileName=${HOME}/Downloads/${StudyID}-${DirSuffix}_${BreakPoint}_${QCType}.csv
#		echo "Read from: ${QCFileName}"

		if [ ! -f $QCFileName ]; then
			echo "ERROR: There is not such a file! You should do the visual QC first!"
			exit 1
		fi

		IFS=","
		read -ra QC <<< `cat $QCFileName`
		#IFS=" "
		unset IFS

		QCType_COUNTER=0
		for Sub in ${QC[@]}; do
#			echo "$Sub $COUNTER"
			echo "$Sub $COUNTER" >> $REPORTFILE
			QCType_COUNTER=$[$QCType_COUNTER +1]
		done
		#echo $QC #>> $REPORTFILE

	done

	echo "$QCType: $(cat $REPORTFILE | grep " $COUNTER" | wc -l)"
	echo "$QCType: $(cat $REPORTFILE | grep " $COUNTER" | wc -l)" >> $SUMMARYFILE

	COUNTER=$[$COUNTER +1]
done

NUMFILE=$(cat $REPORTFILE | wc -l )
echo "Total: $(($NUMFILE-1))"
echo "Total: $(($NUMFILE-1))" >> $SUMMARYFILE

unset IFS

echo "REPORT FILE: $SUMMARYFILE"
echo "SUMMARY FILE: $REPORTFILE"

}

#####################################################################################
#####################################################################################
#####################################################################################


#MAIN

StudyIDD=CFTY720D2309

echo "== $StudyID ====================================="

WriteMeDownAQCReport $StudyIDD _BETsREG 999
