# Check the jobs and possibly resubmit them

DirSuffix=ants
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

#	echo ${WhereTheStatFilesAre}
	Path2StatFile=${WhereTheStatFilesAre}/${StudyID}_${DirSuffix}_${NUMJB}_*_*.stat
#	echo ${Path2StatFile}
	NUMJB_SUCCESSFUL=$(cat ${Path2StatFile} | awk '{print $2}' | awk '{s+=$1} END {print s}')

	echo "======= ====== ====== ====== ======"
	echo "=+_+_+_+_+_+_+_ ${StudyID} _+_+_+_+_+_+_+_+_+"
	echo "Number of successulf jobs: ${NUMJB_SUCCESSFUL}"
	echo "Number of expected jobs: ${NUMJB}"
	echo "======= ====== ====== ====== ======"

	failedjobstxtfileDir=${HOME}/NVROXBOX/EXE/jobcheck/failedjobs/${StudyID}
	failedjobstxtfile=${failedjobstxtfileDir}/${StudyID}_${DirSuffix}.failedjobs.txt
	mkdir -p ${failedjobstxtfileDir}
	rm -f ${failedjobstxtfile}

	for i_NUMJB in `seq 1 ${NUMJB}`
	do
		Path2StatPerFile=${WhereTheStatFilesAre}/${StudyID}_${DirSuffix}_${NUMJB}_*_${i_NUMJB}.stat
		JBSTAT=$(cat ${Path2StatPerFile} | awk '{print $2}')

		if [ ${JBSTAT} == 0 ]; then
#			echo ${Path2StatPerFile}

			FileName=$(basename $Path2StatPerFile .stat)
			JOBID="$(cut -d'_' -f4 <<<"$FileName")"

			echo "Stat:${JBSTAT}, JobNumb:${i_NUMJB}, JobID:${JOBID}" >> ${failedjobstxtfile}
			cat ${WhereTheStatFilesAre}/${StudyID}_${DirSuffix}_${NUMJB}_${JOBID}_${i_NUMJB}.err >> ${failedjobstxtfile}
			sacct --format=Nodelist -j ${JOBID}_${i_NUMJB} >> ${failedjobstxtfile}


		fi
	done


done<${Path2StudyTxtFile}

