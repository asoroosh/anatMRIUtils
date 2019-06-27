StudyID=CFTY720D2201E2

# T13D T12D T22D PD2D 
ImgType=$1

SLURMPaths="${HOME}/NVROXBOX/Data/$StudyID/SLUMR_FIRSTSEGVOL_Submitters_${StudyID}_${ImgType}.txt"
#SLUMR_SIENA_Submitters_CFTY720D2201E2_T13D.txt

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
