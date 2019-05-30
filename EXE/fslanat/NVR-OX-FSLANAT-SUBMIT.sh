StudyID=CFTY720D2201E2

SLURMPaths="/home/bdivdi.local/dfgtyk/NVROXBOX/Data/$StudyID/SLUMR_Submitters_$StudyID.txt"

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

