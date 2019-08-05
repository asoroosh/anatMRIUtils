# Check the jobs and possibly resubmit them

DirSuffix=autorecon12
ImgTyp=T12D # Here we only use T13D and T12D

NUMJB_INPT=200

DataDir="${HOME}/NVROXBOX/Data"
Path2StudyTxtFile=${HOME}/NVROXBOX/EXE/getinfo/StudyIDs_Clean.txt

#This should later be in a loop around StudyIDs
while read StudyID
do
	StudyDir="${DataDir}/${StudyID}"
	ImgTypDir=${StudyDir}/${ImgTyp}
	ImageFileTxt=${ImgTypDir}/${StudyID}_${ImgTyp}_ImageList.txt

	NUMJB=$NUMJB_INPT
	NUMJB_SUCCESSFUL=

	if [ -z $NUMJB ]
	then
		NUMJB=$(cat $ImageFileTxt | wc -l)
	else
		NUMJB_tmp=$(cat $ImageFileTxt | wc -l)
		NUMJBList_tmp=($NUMJB $NUMJB_tmp)
		IFS=$'\n'
		NUMJB=$(echo "${NUMJBList_tmp[*]}" | sort -n | head -n1)
	fi

	WhereTheStatFilesAre=${HOME}/NVROXBOX/Data/${StudyID}/${ImgTyp}/${DirSuffix}/Logs_02-08-19

	Path2StatFile=${WhereTheStatFilesAre}/${StudyID}_${DirSuffix}_${NUMJB}_*_*.stat

	NUMJB_SUCCESSFUL=$(cat ${Path2StatFile} | awk '{print $2}' | awk '{s+=$1} END {print s}')

	echo "======= ====== ====== ====== ======"
	echo "=+_+_+_+_+_+_+_ ${StudyID} _+_+_+_+_+_+_+_+_+"
	echo "Number of successulf jobs: ${NUMJB_SUCCESSFUL}"
	echo "Number of expected jobs: ${NUMJB}"
	echo "======= ====== ====== ====== ======"

done<${Path2StudyTxtFile}

