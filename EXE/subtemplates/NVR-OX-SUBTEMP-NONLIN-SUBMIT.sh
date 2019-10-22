#NumSub=50
#FullSessionSubIDs=""
#sed '${NumSub}q;d' $FullSessionSubIDs
#A=$(grep -n $SubID  | tail -n1)

StudyIDTxtFileName=${HOME}/NVROXBOX/EXE/getinfo/StudyIDs_Clean.txt
NUMJB=50
SUBMITME=1

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
                sh NVR-OX-SUBTEMP-NONLIN.sh ${StudyID} ${ImgTyp} ${NUMJB} ${SUBMITME}

        done<$StudyIDTxtFileName
done
