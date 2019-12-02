StudyID=$1
ImgType=T12D
SegType=atropos

########################################
TransposeMe () {

awk '
{
    for (i=1; i<=NF; i++)  {
        a[NR,i] = $i
    }
}
NF>p { p = NF }
END {
    for(j=1; j<=p; j++) {
        str=a[1,j]
        for(i=2; i<=NR; i++){
            str=str" "a[i,j];
        }
        print str
    }
}' $1
}
######################################

echo ${SubIDFILE}

PathProcParent="/well/nvs-mri-temp/data/ms/processed/IDPs/${StudyID}"
mkdir -p ${PathProcParent}
IDP_GMP="${PathProcParent}/IDP_${StudyID}_${ImgType}_GMParcels_RAWAVG.txt"

rm -rf $IDP_GMP

ResultDir="/well/nvs-mri-temp/data/ms/processed/${StudyID}"
GMP_WC=${ResultDir}/sub-${StudyID}x*/ses-*/anat/sub-${StudyID}x*x*_ses-*_${SegType}_brain_rawavg/IDPs/GMVols/sub-${StudyID}x*_ses-*_UKB-GMAtlas_GMVols_rawavg.txt

Path2Labels=/well/nvs-mri-temp/users/scf915/NVROXBOX/AUX/atlas/GMatlas/labels.txt

echo "Study Subject Visit `TransposeMe $Path2Labels`" > $IDP_GMP

echo "==== ${StudyID}, ${ImgType}, ${SegType}"
echo "The Wildcard: ${GMP_WC}"

for Path2File in $GMP_WC
do

	StudyIDVar=$(echo $Path2File | awk -F"/" '{print $7}') # Study ID

	SubIDVar=$(echo $Path2File | awk -F"/" '{print $8}') # Sub ID
	SubID=$(echo $SubIDVar | awk -F"-" '{print $2}')

	SesIDVar=$(echo $Path2File | awk -F"/" '{print $9}') # Session ID
	SesID=$(echo $SesIDVar | awk -F"-" '{print $2}')

	echo "We are on: ${SegType}, ${StudyIDVar} ${SubIDVar} ${SesIDVar}"

	echo "${StudyID} ${SubID} ${SesID} `TransposeMe ${Path2File}`"  >> $IDP_GMP

done

echo "The final results are in: ${IDP_GMP}"

#while read SubID
#do
#
#	echo "${StudyID} ${SubID} ${SesID} `TransposeMe ${GMPOutputDir}/NVROX-GMPVOLS.txt`"  >> $IDP_GMP
#
#done
