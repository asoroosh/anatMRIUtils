set -e

StudyID=$1
SubID=$2

BEOP=$3

DataDir=/rescompdata/ms/unprocessed/RESCOMP/MetaData
SessionsFileName=${DataDir}/${StudyID}/T12D/Sessions/${StudyID}_sub-${SubID}_T12D.txt

while read SessionPathsFiles
do
  	ses_SesID_tmp=$(echo $SessionPathsFiles | awk -F"/" '{print $9}')
        SesID_tmp=$(echo $ses_SesID_tmp | awk -F"-" '{print $2}');
        SesIDList="${SesIDList} $SesID_tmp"
#        echo ${SesIDList}
done<${SessionsFileName}

SesIDList=(${SesIDList})
NumSes=${#SesIDList[@]}

processed_dir=/data/ms/processed/mri/${StudyID}
unprocessed_dir=/data/ms/unprocessed/mri/relabelled/sesVISITYYYYMMDD

OutputDIR=/rescompdata/ms/unprocessed/RESCOMP/QC/BE-${BEOP}/${StudyID}
rubbishbin=$(mktemp -d /tmp/slicerdir.XXXXXXXXX)

mkdir -p ${OutputDIR}
mkdir -p $rubbishbin

sliceropts="$edgeopts -x 0.4 $rubbishbin/grota.png -x 0.5 $rubbishbin/grotb.png -x 0.6 $rubbishbin/grotc.png -y 0.4 $rubbishbin/grotd.png -y 0.5 $rubbishbin/grote.png -y 0.6 $rubbishbin/grotf.png -z 0.4 $rubbishbin/grotg.png -z 0.5 $rubbishbin/groth.png -z 0.6 $rubbishbin/groti.png"
convertopts="$rubbishbin/grota.png + $rubbishbin/grotb.png + $rubbishbin/grotc.png + $rubbishbin/grotd.png + $rubbishbin/grote.png + $rubbishbin/grotf.png + $rubbishbin/grotg.png + $rubbishbin/groth.png + $rubbishbin/groti.png"

PNGRAWLIST=
for SesID in ${SesIDList[@]}
do

	RAWIMAGEDIR=${unprocessed_dir}/${StudyID}/sub-${SubID}/ses-${SesID}/anat
	RAWIMAGE=${RAWIMAGEDIR}/sub-${SubID}_ses-${SesID}_run-1_T1w

	BRAINMASKDIR=${processed_dir}/sub-${SubID}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_run-1_T1w.$BEOP
	BRAINMASK=${BRAINMASKDIR}/sub-${SubID}_ses-${SesID}_run-1_T1w_${BEOP}_BrainMask

	$FSLDIR/bin/fslmaths $BRAINMASK.nii.gz -thr 0.1 -bin $rubbishbin/thrbrainmask

	PNGIMGNAME_BE=sub-${SubID}_ses-${SesID}_${BEOP}
	${FSLDIR}/bin/slicer ${RAWIMAGE}.nii.gz $rubbishbin/thrbrainmask.nii.gz -s 1 $sliceropts
	${FSLDIR}/bin/pngappend $convertopts ${OutputDIR}/${PNGIMGNAME_BE}.png

	rm -f $rubbishbin/*.png
	rm -f $rubbishbin/*.nii.gz

	PNGRAWLIST="$PNGRAWLIST - ${OutputDIR}/${PNGIMGNAME_BE}.png"

done

#echo $PNGRAWLIST

PNGRAWLIST=$(echo $PNGRAWLIST | cut -c2-)

#echo $PNGRAWLIST

#PNGRAWLIST="${OutputDIR}/${PNGIMGNAME_BE}.png $PNGRAWLIST"
#ImgMagickPath=/apps/eb/software/ImageMagick/7.0.8-11-GCCcore-7.3.0/bin
#$ImgMagickPath/convert ${OutputDIR}/${PNGIMGNAME_BE}.png -resize $($ImgMagickPath/identify -format "%w" "${OutputDIR}/${PNGIMGNAME_RAWBE}.png") ${OutputDIR}/${PNGIMGNAME_BE}.png
#echo $PNGRAWLIST

mkdir -p ${OutputDIR}/SUBs
PNGIMGNAME_FINAL=${SubID}_${BEOP}
${FSLDIR}/bin/pngappend $PNGRAWLIST ${OutputDIR}/SUBs/${PNGIMGNAME_FINAL}.png

echo "Check: ${OutputDIR}/SUBs/${PNGIMGNAME_FINAL}.png"

rm -rf $rubbishbin
