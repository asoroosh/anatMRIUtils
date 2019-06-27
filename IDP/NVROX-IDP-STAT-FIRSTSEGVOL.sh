StudyID=CFTY720D2201E2
RunID=1
ImgType=$1

########################################

GitHubDataDir="${HOME}/NVROXBOX/Data/${StudyID}"
SubIDFILE="${GitHubDataDir}/SubDirID_${StudyID}.txt"

echo ${SubIDFILE}

PathProcParent="/data/output/habib/processed/${StudyID}"
IDP_FIRSTSEGVOL="${PathProcParent}/anat/IDP_${StudyID}_${ImgType}_FIRSTSEGVOL.txt"

NROI=15

rm -f ${IDP_FIRSTSEGVOL}

while read SubID
do
	SubID=`basename $SubID`

	echo ${SubID}

	SesIDFILE="${GitHubDataDir}/Sessions/${StudyID}_${SubID}_Sessions.txt"

	while read SesID
	do
		SesID=`basename $SesID`

		echo ${SesID}

		#Check whether the file is there, if not put a NaN and continue

			if [ $ImgType == T13D ] ; then
				#sub-2okKlAKGz7_ses-V1_M2_acq-3d_run-1_T1w.nii.gz
				ImageName=${SubID}_${SesID}_acq-3d_run-${RunID}_T1w
			elif [ $ImgType == T12D ] ; then
				#sub-2okKlAKGz7_ses-V1_M2_run-1_T1w.nii.gz
				ImageName=${SubID}_${SesID}_run-${RunID}_T1w
			elif [ $ImgType == PD2D ] ; then
				#sub-2okKlAKGz7_ses-V1_M2_run-1_PDT2_1.nii.gz
				ImageName=${SubID}_${SesID}_run-${RunID}_PDT2_1
			elif [ $ImgType == T22D ] ; then
				#sub-2okKlAKGz7_ses-V1_M2_run-1_PDT2_2.nii.gz
				ImageName=${SubID}_${SesID}_run-${RunID}_PDT2_2
			else
				# throw an error and halt here
				echo "$ImgType is unrecognised"
			fi

		#FIRSTSEGVOL
		FIRST_DIR=${PathProcParent}/${SubID}/${SesID}/anat/${ImageName}.anat/first_results

		#echo ${FIRST_DIR}
		if [ ! -d ${FIRST_DIR} ] ; then
			echo "**DOES NOT EXISTS: ${FIRST_DIR} "
			
			NaNResults=""
			for i in $(seq 1 $NROI) ; do 
    				NaNResults="NaN $NaNResults"; 
			done 

			echo "${SubID} ${SesID} ${StudyID} $NaNResults" >> $IDP_FIRSTSEGVOL

			continue
		fi

		echo "${SubID} ${SesID} ${StudyID} `cat ${FIRST_DIR}/FIRST-SUBCORTVOL.txt`"  >> $IDP_FIRSTSEGVOL

	done<$SesIDFILE
        
done<${SubIDFILE}
