
ImgTyp=T12D
while read StudyID;
do
	echo "${StudyID}: `ls -d /data/ms/unprocessed/mri/${StudyID}.anon.*/sub-* | wc -l`";

	sh NVR-OX-GET-STUDYSTATs.sh ${StudyID} ${ImgTyp}

done<StudyIDs.txt

wc -l ${HOME}/NVROXBOX/Data/*/${ImgTyp}/*_${ImgTyp}_ImageList.txt
