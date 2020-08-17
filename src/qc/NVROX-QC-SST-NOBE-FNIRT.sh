set -e

ml ImageMagick
ml FreeSurfer
ml Perl
source /apps/eb/software/FreeSurfer/6.0.1-centos6_x86_64/FreeSurferEnv.sh

#ml ImageMagick

StudyID=$1
SubID=$2

BEOP="_BETFNIRT"

#CFTY720D2201 sub-CFTY720D2201x0030x00006 _BETFNIRT

DataDir=/rescompdata/ms/unprocessed/RESCOMP/MetaData
SessionsFileName=${DataDir}/${StudyID}/T12D/Sessions/${StudyID}_sub-${SubID}_T12D.txt

while read SessionPathsFiles
do
  	ses_SesID_tmp=$(echo $SessionPathsFiles | awk -F"/" '{print $9}')
        SesID_tmp=$(echo $ses_SesID_tmp | awk -F"-" '{print $2}');
        SesIDList="${SesIDList} $SesID_tmp"
done<${SessionsFileName}

SesIDList=(${SesIDList})
NumSes=${#SesIDList[@]}

mnitemplate=$FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz
processed_dir=/rescompdata/ms/unprocessed/RESCOMP/${StudyID}
SST_DIR=${processed_dir}/sub-${SubID}/T12D.autorecon12ws.nuws_mrirobusttemplate
SST_IMG=${SST_DIR}/sub-${SubID}_ants_temp_med_nutemplate0.nii.gz
SST_BRAIN_IMG=${SST_DIR}/sub-${SubID}_ants_temp_med_nutemplate0${BEOP}_brain.nii.gz
SSTMNI_IMG=${SST_DIR}/BETFNIRT/sub-${SubID}_ants_temp_med_nutemplate0_MNI-FNIRT-2mm-warped.nii.gz

OutputDIR=/rescompdata/ms/unprocessed/RESCOMP/QC/SST-BE${BEOP}/${StudyID}

rubbishbin=$(mktemp -d /tmp/slicerdir.XXXXXXXXX)

mkdir -p ${OutputDIR}/SST-AVG-REG
mkdir -p ${OutputDIR}/SST-AVG
mkdir -p $rubbishbin

sliceropts="$edgeopts -x 0.4 $rubbishbin/grota.png -x 0.5 $rubbishbin/grotb.png -x 0.6 $rubbishbin/grotc.png -y 0.4 $rubbishbin/grotd.png -y 0.5 $rubbishbin/grote.png -y 0.6 $rubbishbin/grotf.png -z 0.4 $rubbishbin/grotg.png -z 0.5 $rubbishbin/groth.png -z 0.6 $rubbishbin/groti.png"
convertopts="$rubbishbin/grota.png + $rubbishbin/grotb.png + $rubbishbin/grotc.png + $rubbishbin/grotd.png + $rubbishbin/grote.png + $rubbishbin/grotf.png + $rubbishbin/grotg.png + $rubbishbin/groth.png + $rubbishbin/groti.png"

# ------------------ MNI -------------------------------------------------------

fslreorient2std ${SST_IMG} $rubbishbin/sst.nii.gz

PNGIMGNAME_SST=${SubID}_SST
${FSLDIR}/bin/slicer $rubbishbin/sst.nii.gz -s 1 $sliceropts
${FSLDIR}/bin/pngappend $convertopts ${OutputDIR}/${PNGIMGNAME_SST}.png

mri_convert --in_orientation LIA --out_orientation LAS ${SSTMNI_IMG} $rubbishbin/sstmni.nii.gz > /dev/null 2>&1

PNGIMGNAME_MNI=${SubID}_MNI
${FSLDIR}/bin/slicer $rubbishbin/sstmni.nii.gz $mnitemplate -s 1 $sliceropts
${FSLDIR}/bin/pngappend $convertopts ${OutputDIR}/${PNGIMGNAME_MNI}.png

ImgMagickPath=/apps/eb/software/ImageMagick/7.0.8-11-GCCcore-7.3.0/bin
$ImgMagickPath/convert ${OutputDIR}/${PNGIMGNAME_MNI}.png -resize $($ImgMagickPath/identify -format "%w" "${OutputDIR}/${PNGIMGNAME_SST}.png") ${OutputDIR}/${PNGIMGNAME_MNI}.png

PNGIMGNAME_REG=${SubID}_SST-RAW-MNI
${FSLDIR}/bin/pngappend ${OutputDIR}/${PNGIMGNAME_SST}.png - ${OutputDIR}/${PNGIMGNAME_MNI}.png ${OutputDIR}/SST-AVG-REG/${PNGIMGNAME_REG}.png

rm -f $rubbishbin/*.png
rm -f $rubbishbin/*.nii.gz

echo "Check Reg: ${OutputDIR}/SST-AVG-REG/${PNGIMGNAME_REG}.png"

# ------------------ BET -------------------------------------------------------
fslmaths $SST_BRAIN_IMG -bin $rubbishbin/brainmask.nii.gz
fslreorient2std $rubbishbin/brainmask.nii.gz $rubbishbin/brainmask.nii.gz
fslreorient2std $SST_IMG $rubbishbin/wholebrain.nii.gz

PNGIMGNAME_BE=${SubID}_SST${BEOP}

${FSLDIR}/bin/slicer $rubbishbin/wholebrain.nii.gz $rubbishbin/brainmask.nii.gz -s 1 $sliceropts
${FSLDIR}/bin/pngappend $convertopts ${OutputDIR}/${PNGIMGNAME_BE}.png

rm -f $rubbishbin/*.png
rm -f $rubbishbin/*.nii.gz

PNGRAWLIST=
for SesID in ${SesIDList[@]}
do

	RAWAVG_DIR=${processed_dir}/sub-${SubID}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_run-1_T1w.autorecon12ws/sub-${SubID}_ses-${SesID}_run-1_T1w/mri

	mri_convert $RAWAVG_DIR/orig/001.mgz $rubbishbin/001.nii.gz > /dev/null 2>&1

	fslmaths ${RAWAVG_DIR}/nu${BEOP}_brain_rawavg.nii.gz -bin $rubbishbin/rawavgmask.nii.gz

	fslreorient2std $rubbishbin/rawavgmask.nii.gz $rubbishbin/rawavgmask.nii.gz
	fslreorient2std $rubbishbin/001.nii.gz $rubbishbin/rawavgwholebrain.nii.gz

	PNGIMGNAME_RAWBE=${SubID}_${SesID}_RAWAVG${BEOP}
	${FSLDIR}/bin/slicer $rubbishbin/rawavgwholebrain.nii.gz $rubbishbin/rawavgmask.nii.gz -s 1 $sliceropts
	${FSLDIR}/bin/pngappend $convertopts ${OutputDIR}/${PNGIMGNAME_RAWBE}.png

	PNGRAWLIST="$PNGRAWLIST - ${OutputDIR}/${PNGIMGNAME_RAWBE}.png"

	rm -f $rubbishbin/*.nii.gz
	rm -f $rubbishbin/*.png
done

PNGRAWLIST="${OutputDIR}/${PNGIMGNAME_BE}.png $PNGRAWLIST"

ImgMagickPath=/apps/eb/software/ImageMagick/7.0.8-11-GCCcore-7.3.0/bin
#ls $ImgMagickPath
$ImgMagickPath/convert ${OutputDIR}/${PNGIMGNAME_BE}.png -resize $($ImgMagickPath/identify -format "%w" "${OutputDIR}/${PNGIMGNAME_RAWBE}.png") ${OutputDIR}/${PNGIMGNAME_BE}.png

PNGIMGNAME_FINAL=${SubID}_SST-AVG${BEOP}
${FSLDIR}/bin/pngappend $PNGRAWLIST ${OutputDIR}/SST-AVG/${PNGIMGNAME_FINAL}.png

echo "Check: ${OutputDIR}/SST-AVG/${PNGIMGNAME_FINAL}.png"

rm -rf $rubbishbin
