StudyID=$1
ImgType=T12D
SegType=atropos

OPTAG=BETsREG

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

PathProcParent="/rescompdata/ms/unprocessed/RESCOMP/IDPs/${StudyID}"
mkdir -p ${PathProcParent}
IDP_GMP="${PathProcParent}/IDP_${StudyID}_${ImgType}_${OPTAG}_BRAINVOLS_RAWAVG.txt"

rm -rf $IDP_GMP

#ResultDir="/well/nvs-mri-temp/data/ms/processed/${StudyID}"

ResultDir="/rescompdata/ms/unprocessed/RESCOMP/${StudyID}"
GMP_WC=${ResultDir}/sub-${StudyID}x*x*/ses-V*x*/anat/sub-${StudyID}x*x*_ses-V*x*_atropos_${OPTAG}_brain_rawavg/IDPs/SIENAX/sub-${StudyID}x*x*_ses-V*x*_${OPTAG}_Sienax_Report

echo "Study Subject Visit Raw_BrainVol_Cereb Norm_BrainVol_Cereb Raw_BrainVol_NoCereb Norm_BrainVol_NoCereb Raw_GMVol_Cereb Norm_GMVol_Cereb Raw_GMVol_NoCereb Norm_GMVol_NoCereb Raw_WMVol_Cereb Norm_WMVol_Cereb Raw_WMVol_NoCereb Norm_WMVol_NoCereb Raw_PGM Norm_PGM Raw_CSF Norm_CSF vscale" > $IDP_GMP

echo "==== ${StudyID}, ${ImgType}, ${SegType}"
echo "The Wildcard: ${GMP_WC}"

for Path2File in $GMP_WC
do

	StudyIDVar=$(echo $Path2File | awk -F"/" '{print $6}') # Study ID

	SubIDVar=$(echo $Path2File | awk -F"/" '{print $7}') # Sub ID
	SubID=$(echo $SubIDVar | awk -F"-" '{print $2}')

	SesIDVar=$(echo $Path2File | awk -F"/" '{print $8}') # Session ID
	SesID=$(echo $SesIDVar | awk -F"-" '{print $2}')

	echo "We are on: ${SegType}, ${StudyIDVar} ${SubIDVar} ${SesIDVar}"

	#Brain Volume
	BrainVol=$(cat $Path2File | grep "BRAIN   " | awk '{print $2}')
	NormBrainVol=$(cat $Path2File | grep "BRAIN   " | awk '{print $3}')

	BrainVol_NoCreb=$(cat $Path2File | grep "BRAIN w/o" | awk '{print $4}')
	NormBrainVol_NoCreb=$(cat $Path2File | grep "BRAIN w/o" | awk '{print $5}')

#	echo "Brain Volumes"
#	echo ${BrainVol} ${NormBrainVol} ${BrainVol_NoCreb} ${NormBrainVol_NoCreb}

	# Grey Matter
	GREYVol=$(cat $Path2File | grep "GREY   " | awk '{print $2}')
	NormGREYVol=$(cat $Path2File | grep "GREY   " | awk '{print $3}')

        GREYVol_NoCreb=$(cat $Path2File | grep "GREY w/o" | awk '{print $4}')
        NormGREYVol_NoCreb=$(cat $Path2File | grep "GREY w/o" | awk '{print $5}')

#	echo "Grey Matter"
#	echo ${GREYVol} ${NormGREYVol} ${GREYVol_NoCreb} ${NormGREYVol_NoCreb}

	#WhiteMatter
	WHITEVol=$(cat $Path2File | grep "WHITE   " | awk '{print $2}')
        NormWHITEVol=$(cat $Path2File | grep "WHITE   " | awk '{print $3}')

        WHITEVol_NoCreb=$(cat $Path2File | grep "WHITE w/o" | awk '{print $4}')
        NormWHITEVol_NoCreb=$(cat $Path2File | grep "WHITE w/o" | awk '{print $5}')

#	echo "White Matter"
#	echo ${WHITEVol} ${NormWHITEVol} ${WHITEVol_NoCreb} ${NormWHITEVol_NoCreb}

	#pgrey
	pgrey=$(cat $Path2File | grep "pgrey   " | awk '{print $2}')
	normpgrey=$(cat $Path2File | grep "pgrey   " | awk '{print $3}')

#	echo "Partial Grey Matter"
#	echo ${pgrey} ${normpgrey}

	#vcsf
	vcsf=$(cat $Path2File | grep "vcsf   " | awk '{print $2}')
	normvcsf=$(cat $Path2File | grep "vcsf   " | awk '{print $3}')

#	echo "CSF"
#	echo ${vcsf} ${normvcsf}

	#VSCALING
	vscale=$(cat $Path2File | grep "VSCALING" | awk '{print $2}')

#	echo "Volumetric Scaling"
#	echo ${vscale}

	echo "${StudyID} ${SubID} ${SesID} ${BrainVol} ${NormBrainVol} ${BrainVol_NoCreb} ${NormBrainVol_NoCreb} ${GREYVol} ${NormGREYVol} ${GREYVol_NoCreb} ${NormGREYVol_NoCreb} ${WHITEVol} ${NormWHITEVol} ${WHITEVol_NoCreb} ${NormWHITEVol_NoCreb} ${pgrey} ${normpgrey} ${vcsf} ${normvcsf} ${vscale}"  >> $IDP_GMP

done

echo "The final results are in: ${IDP_GMP}"

