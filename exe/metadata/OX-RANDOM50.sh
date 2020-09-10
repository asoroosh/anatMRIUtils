#!/bin/bash
# Randomly picks $NRNDSST number of subjects
# Soroosh Afyouni, University of Oxford, 2020

StudyID=$1

DataDir="/XXXXX/XXXXX/XXXXXX/XXXX/XXXXX"

NRNDSST=60

TXT50RND=${DataDir}/${StudyID}/T12D/${StudyID}_T12D_ImageList_50RND.txt
rm -f $TXT50RND

SUBTXT50RND=${DataDir}/${StudyID}/T12D/${StudyID}_T12D_ImageSubIDs_50RND.txt
rm -f $SUBTXT50RND

AA=2
ls ${DataDir}/${StudyID}/T12D/Sessions/${StudyID}_sub-* | sort -R |tail -$NRNDSST | while read TFILENAME; do
	echo $TFILENAME

	InputImageName=$(basename $TFILENAME .txt)
	SubIDVar=$(echo $InputImageName | awk -F"_" -v xx=$AA '{print $xx}')

	echo $SubIDVar
	echo ${SubIDVar} >> $SUBTXT50RND
	cat ${TFILENAME} >> ${TXT50RND}
done
