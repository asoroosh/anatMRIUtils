
StudyID=CFTY720D2201E2

SubIDtxt="/home/bdivdi.local/dfgtyk/NVROXBOX/Data/${StudyID}/SubDirID_${StudyID}.txt"

while read SubID
do

SubID=`basename ${SubID}`

Dir2beRM_A=/home/bdivdi.local/dfgtyk/NVROXBOX/Data/${StudyID}/${SubID}/data
Dir2beRM_B=/home/bdivdi.local/dfgtyk/NVROXBOX/Data/${StudyID}/${SubID}/anat

echo ${Dir2beRM_A}
echo ${Dir2beRM_B}

rm -r $Dir2beRM_A
rm -r $Dir2beRM_B

done<${SubIDtxt}



