
StudyIDTxtFileName=${HOME}/NVROXBOX/EXE/getinfo/StudyIDs_Clean.txt
NUMJB=200

# Loop around the image types
for ImgTyp in T12D
do
	#Loop around the study IDs
	while read StudyID
	do

		echo "=============================================================="
                echo "=============================================================="
                echo ""
		echo "*** ${StudyID}, ${ImgTyp}"
		echo ""
                echo "=============================================================="
                echo "=============================================================="
		sh NVR-OX-FSLANAT.sh ${StudyID} ${ImgTyp} ${NUMJB}

	done<$StudyIDTxtFileName
done