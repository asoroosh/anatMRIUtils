
StudyID=CFTY720D2201E2
RunID=1
ImgType=$1

GitHubDataDir="${HOME}/NVROXBOX/Data/${StudyID}"
SubIDFILE="${GitHubDataDir}/SubDirID_${StudyID}.txt"

echo ${SubIDFILE}

PathProcParent="/data/output/habib/processed/${StudyID}"

IDP_SIENAX_WM="${PathProcParent}/anat/IDP_${StudyID}_${ImgType}_SIENAX_WM.txt"
IDP_SIENAX_GM="${PathProcParent}/anat/IDP_${StudyID}_${ImgType}_SIENAX_GM.txt"
IDP_SIENAX_BRN="${PathProcParent}/anat/IDP_${StudyID}_${ImgType}_SIENAX_BRN.txt"
IDP_SIENAX_VSCALING="${PathProcParent}/anat/IDP_${StudyID}_${ImgType}_SIENAX_VSCALING.txt"

IDP_SIENA_FINALPBVC="${PathProcParent}/anat/IDP_${StudyID}_${ImgType}_SIENA_FINALPBVC.txt"

IDP_SIENA_A2B_PBVC="${PathProcParent}/anat/IDP_${StudyID}_${ImgType}_SIENA_A2B_PBVC.txt"
IDP_SIENA_A2B_RATIO="${PathProcParent}/anat/IDP_${StudyID}_${ImgType}_SIENA_A2B_RATIO.txt"
IDP_SIENA_A2B_VOLC="${PathProcParent}/anat/IDP_${StudyID}_${ImgType}_SIENA_A2B_VOLC.txt"
IDP_SIENA_A2B_AREA="${PathProcParent}/anat/IDP_${StudyID}_${ImgType}_SIENA_A2B_AREA.txt"

IDP_SIENA_B2A_PBVC="${PathProcParent}/anat/IDP_${StudyID}_${ImgType}_SIENA_B2A_PBVC.txt"
IDP_SIENA_B2A_RATIO="${PathProcParent}/anat/IDP_${StudyID}_${ImgType}_SIENA_B2A_RATIO.txt"
IDP_SIENA_B2A_VOLC="${PathProcParent}/anat/IDP_${StudyID}_${ImgType}_SIENA_B2A_VOLC.txt"
IDP_SIENA_B2A_AREA="${PathProcParent}/anat/IDP_${StudyID}_${ImgType}_SIENA_B2A_AREA.txt"

rm -f ${IDP_SIENAX_WM} ${IDP_SIENAX_GM} ${IDP_SIENAX_BRN} ${IDP_SIENAX_VSCALING}

rm -f ${IDP_SIENA_FINALPBVC}\
	${IDP_SIENA_A2B_PBVC} ${IDP_SIENA_A2B_RATIO} ${IDP_SIENA_A2B_VOLC} ${IDP_SIENA_A2B_AREA} \
	${IDP_SIENA_B2A_PBVC} ${IDP_SIENA_B2A_RATIO} ${IDP_SIENA_B2A_VOLC} ${IDP_SIENA_B2A_AREA}

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

		#SIENAX
		SienaXOutputDir=${PathProcParent}/${SubID}/${SesID}/anat/${ImageName}.sienax
		AnatOutputDir=${PathProcParent}/${SubID}/${SesID}/anat/${ImageName}.anat

		echo ${SienaXOutputDir}
		if [ ! -d ${SienaXOutputDir} ] || [ ! -d ${AnatOutputDir} ]; then
			echo "**DOES NOT EXISTS: ${SienaXOutputDir} "
			
			echo "${SubID} ${SesID} ${StudyID} NaN" >> $IDP_SIENAX_WM
			echo "${SubID} ${SesID} ${StudyID} NaN" >> $IDP_SIENAX_GM
			echo "${SubID} ${SesID} ${StudyID} NaN" >> $IDP_SIENAX_BRN

			echo "${SubID} ${SesID} ${StudyID} NaN" >> $IDP_SIENAX_VSCALING

			continue

		fi

		echo "${SubID} ${SesID} ${StudyID} `cat ${SienaXOutputDir}/report.sienax | grep GREY | awk '{print $3 "  " $2}'`"  >> $IDP_SIENAX_WM
		echo "${SubID} ${SesID} ${StudyID} `cat ${SienaXOutputDir}/report.sienax | grep WHITE | awk '{print $3 "  " $2}'`" >> $IDP_SIENAX_GM
		echo "${SubID} ${SesID} ${StudyID} `cat ${SienaXOutputDir}/report.sienax | grep BRAIN | awk '{print $3 "  " $2}'`" >> $IDP_SIENAX_BRN
		
		echo "${SubID} ${SesID} ${StudyID} `cat ${SienaXOutputDir}/report.sienax | grep VSCALING | awk '{print $2}'`" >> $IDP_SIENAX_VSCALING

	done<$SesIDFILE


	NumOfSess=`cat ${SesIDFILE} | wc -l`

	if [ $NumOfSess -gt 2 ] ; then 
		echo "There are more than two sessions, which is impossible with Siena"
		continue
	elif [ $NumOfSess -lt 2 ] ; then 
		echo "There is only one session, which is not enough for Siena"
		continue
	fi


	#SIENA
	ADir=`sed -n '1p' ${SesIDFILE}` # Get the first data point
	BDir=`sed -n '2p' ${SesIDFILE}` # Get the second data point

	SesA=`basename $ADir`
	SesB=`basename $BDir`

	echo "$SesA *** $SesB"

	if [ $ImgType == T13D ] ; then
            SienaDirName=${SubID}_${SesA}-${SesB}_acq-3d_run-${RunID}_T1w
        elif [ $ImgType == T12D ] ; then
            SienaDirName=${SubID}_${SesA}-${SesB}_run-${RunID}_T1w
        elif [ $ImgType == PD2D ] ; then
            SienaDirName=${SubID}_${SesA}-${SesB}_run-${RunID}_PDT2_1
        elif [ $ImgType == T22D ] ; then
            SienaDirName=${SubID}_${SesA}-${SesB}_run-${RunID}_PDT2_2
        else
            # throw an error and halt here
            echo "$ImgType is unrecognised"
        fi


	SienaOutputDir=${PathProcParent}/${SubID}/siena/${SienaDirName}.siena

	if [ ! -d ${SienaOutputDir} ]; then 
		echo "${SubID} ${SesA}-${SesB} ${StudyID} NaN" >> $IDP_SIENA_FINALPBVC

		continue	
	fi


	# Halfway from B > A
        echo "${SubID} ${SesA}-${SesB} ${StudyID} `cat ${SienaOutputDir}/report.siena | grep PBVC | awk {'print $2'} | awk 'NR==2'`" >> $IDP_SIENA_B2A_PBVC
        echo "${SubID} ${SesA}-${SesB} ${StudyID} `cat ${SienaOutputDir}/report.siena | grep RATIO | awk {'print $2'} | awk 'NR==2'`" >> $IDP_SIENA_B2A_RATIO
        echo "${SubID} ${SesA}-${SesB} ${StudyID} `cat ${SienaOutputDir}/report.siena | grep VOLC | awk {'print $2'} | awk 'NR==2'`" >> $IDP_SIENA_B2A_VOLC
        echo "${SubID} ${SesA}-${SesB} ${StudyID} `cat ${SienaOutputDir}/report.siena | grep AREA | awk {'print $2'} | awk 'NR==2'`" >>	$IDP_SIENA_B2A_AREA


	# Halfway from A > B
	echo "${SubID} ${SesA}-${SesB} ${StudyID} `cat ${SienaOutputDir}/report.siena | grep PBVC | awk {'print $2'} | awk 'NR==1'`" >> $IDP_SIENA_A2B_PBVC
	echo "${SubID} ${SesA}-${SesB} ${StudyID} `cat ${SienaOutputDir}/report.siena | grep RATIO | awk {'print $2'} | awk 'NR==1'`" >> $IDP_SIENA_A2B_RATIO
	echo "${SubID} ${SesA}-${SesB} ${StudyID} `cat ${SienaOutputDir}/report.siena | grep VOLC | awk {'print $2'} | awk 'NR==1'`" >>	$IDP_SIENA_A2B_VOLC
	echo "${SubID} ${SesA}-${SesB} ${StudyID} `cat ${SienaOutputDir}/report.siena | grep AREA | awk {'print $2'} | awk 'NR==1'`" >> $IDP_SIENA_A2B_AREA
	
	#FINAL
	echo "${SubID} ${SesA}-${SesB} ${StudyID} `cat ${SienaOutputDir}/report.siena | grep finalPBVC | awk '{print $2}'`" >> $IDP_SIENA_FINALPBVC


done<${SubIDFILE}
