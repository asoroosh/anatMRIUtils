ImgTyp=T12D
NumSub=50

StudyCleanIDTxtFile="${HOME}/NVROXBOX/EXE/getinfo/StudyIDs_Clean.txt"

StudyNum=$(cat $StudyCleanIDTxtFile | wc -l)
echo $StudyNum

#for StudyIDX in $(seq 1 $StudyNum)
#do
#	echo $StudyIDX
#	StudyID=$(sed "${StudyIDX}q;d" ${StudyCleanIDTxtFile})
	
	StudyID=$1
	echo "+++++ STUDY ${StudyID}++++++++"

	FullSessionTxtFile=${HOME}/NVROXBOX/Data/${StudyID}/${ImgTyp}/Sessions/${StudyID}_FullSessionSubID_${ImgTyp}.txt
	echo ${FullSessionTxtFile}

	ImageListTxt=${HOME}/NVROXBOX/Data/${StudyID}/${ImgTyp}/${StudyID}_${ImgTyp}_ImageList.txt
	echo ${ImageListTxt}

	SubIDListTxt=${HOME}/NVROXBOX/Data/${StudyID}/${ImgTyp}/${StudyID}_${ImgTyp}_ImageList_${NumSub}Sub.txt
#	rm -rf $SubIDListTxt

	for SubIDX in $(seq 1 $NumSub); do
		SubID=$(sed "${SubIDX}q;d" ${FullSessionTxtFile})
		echo "===Subject $SubIDX, SubID: $SubID===="
		grep $SubID $ImageListTxt >> $SubIDListTxt
	done

	wc -l $SubIDListTxt

#done
