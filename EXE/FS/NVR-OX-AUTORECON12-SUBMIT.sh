StudyID=CFTY720D2201E2

DirSuffix="AUTORECON12"

# T13D T12D T22D PD2D 
ImgType=$1

SLURMPaths="/home/bdivdi.local/dfgtyk/NVROXBOX/Data/$StudyID/SLUMR_${DirSuffix}_Submitters_${StudyID}_${ImgType}.txt"
#SLUMR_Submitters_CFTY720D2201E2_PD2D.txt

echo "=========================="
echo "The submitted file for study $StudyID are availble via:"
echo $SLURMPaths
echo "=========================="

CNT=0
while read SubmitterFileName
do
	echo "Submitting: ${SubmitterFileName}"
	sbatch $SubmitterFileName
	let CNT=CNT+1
done < $SLURMPaths

echo "==== TOTAL JOB SUBMITTED: $CNT"

