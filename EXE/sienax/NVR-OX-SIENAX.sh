#This should later be in a loop around StudyIDs
StudyID=CFTY720D2201E2

ImgType=$1

RunID=1

set -e

Mem=5G
Time="30:00"

PathProcParent="/data/output/habib/processed/$StudyID"

GitHubDataDir="/home/bdivdi.local/dfgtyk/NVROXBOX/Data/${StudyID}"
StudySubIDFile="${GitHubDataDir}/SubDirID_${StudyID}.txt"

#Submitter files, just save the path to them for future mass re-producing
SubmitterPath="${GitHubDataDir}/SLUMR_SIENA_Submitters_${StudyID}_${ImgType}.txt"
rm -f ${SubmitterPath}

while read SubID
do
	# Get the SubID from the directory path
        SubID=`basename $SubID`
	echo "For Subject: $SubID ========================================"

	GitHubDataDirSub=$GitHubDataDir/$SubID
        mkdir -p $GitHubDataDirSub

	SessionFileName="${GitHubDataDir}/Sessions/${StudyID}_${SubID}_Sessions.txt"
	
	NumOfSess=`cat ${SessionFileName} | wc -l`

	if [ $NumOfSess -gt 2 ] ; then 
		echo "There are more than two sessions, which is impossible with Siena"
		continue
	elif [ $NumOfSess -lt 2 ] ; then 
		echo "There is only one session, which is not enough for Siena"
		continue
	fi

	echo "=== Available sessions:"
	cat ${SessionFileName}

	ADir=`sed -n '1p' ${SessionFileName}` # Get the first data point
	BDir=`sed -n '2p' ${SessionFileName}` # Get the second data point

	SesA=`basename $ADir`
	SesB=`basename $BDir`

        #Image Name
        if [ $ImgType == T13D ] ; then
                #sub-2okKlAKGz7_ses-V1_M2_acq-3d_run-1_T1w.nii.gz
		ImageNameA=${SubID}_${SesA}_acq-3d_run-${RunID}_T1w
		ImageNameB=${SubID}_${SesB}_acq-3d_run-${RunID}_T1w
		SienaDirName=${SubID}_${SesA}-${SesB}_acq-3d_run-${RunID}_T1w

	elif [ $ImgType == T12D ] ; then
                #sub-2okKlAKGz7_ses-V1_M2_run-1_T1w.nii.gz
                ImageNameA=${SubID}_${SesA}_run-${RunID}_T1w
		ImageNameB=${SubID}_${SesB}_run-${RunID}_T1w
		SienaDirName=${SubID}_${SesA}-${SesB}_run-${RunID}_T1w

	elif [ $ImgType == PD2D ] ; then
                #sub-2okKlAKGz7_ses-V1_M2_run-1_PDT2_1.nii.gz
                ImageNameA=${SubID}_${SesA}_run-${RunID}_PDT2_1
		ImageNameB=${SubID}_${SesB}_run-${RunID}_PDT2_1
		SienaDirName=${SubID}_${SesA}-${SesB}_run-${RunID}_PDT2_1

        elif [ $ImgType == T22D ] ; then
                #sub-2okKlAKGz7_ses-V1_M2_run-1_PDT2_2.nii.gz
        	ImageNameA=${SubID}_${SesA}_run-${RunID}_PDT2_2
		ImageNameB=${SubID}_${SesB}_run-${RunID}_PDT2_2
		SienaDirName=${SubID}_${SesA}-${SesB}_run-${RunID}_PDT2_2

        else
                # throw an error and halt here
                echo "$ImgType is unrecognised"
        fi

	ImageADirName=${PathProcParent}/${SubID}/${SesA}/anat/${ImageNameA}.anat/T1_to_MNI_nonlin.nii.gz
	ImageBDirName=${PathProcParent}/${SubID}/${SesB}/anat/${ImageNameB}.anat/T1_to_MNI_nonlin.nii.gz

	SienaOutputDir=${PathProcParent}/${SubID}/siena/${SienaDirName}.siena
	SienaXOutputDir=${PathProcParent}/${SubID}/sienax/${SienaDirName}.sienax


	GitHubDataDirSubSiena=${GitHubDataDirSub}/siena
	mkdir -p ${GitHubDataDirSubSiena}	

	JobName=${StudyID}_${SienaDirName}_Siena
        SubmitterFileName="${GitHubDataDirSubSiena}/SubmitMe_${JobName}.sh"
        echo "${SubmitterFileName}" >> $SubmitterPath

cat > $SubmitterFileName << EOF
#!/bin/bash
#SBATCH --partition=main
#SBATCH --job-name=${JobName}
#SBATCH --mem=${Mem}
#SBATCH --time=${Time}
#SBATCH --output=${GitHubDataDirSubSiena}/${JobName}.out
#SBATCH --error=${GitHubDataDirSubSiena}/${JobName}.err


mkdir -p ${SienaOutputDir}

### ### ### ### ### ###
${FSLDIR}/bin/siena ${ImageADirName} ${ImageBDirName} -o ${SienaOutputDir}
### ### ### ### ### ###

EOF

done<${StudySubIDFile}
