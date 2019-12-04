
set -e

ml ImageMagick
ml FreeSurfer
ml Perl
source /apps/eb/software/FreeSurfer/6.0.1-centos6_x86_64/FreeSurferEnv.sh

StudyID=CFTY720D2201
SubID=CFTY720D2201x0043x00011
ImgTyp=T12D

PRSD_DIR=/rescompdata/ms/unprocessed/RESCOMP
FS_DIR=${PRSD_DIR}/${StudyID}/sub-${SubID}/

UNPRSD_DIR="/data/ms/unprocessed/mri/relabelled/sesVISITYYYYMMDD/"

DirSuffix="autorecon12ws"
LT_DirSuffix="nuws_mrirobusttemplate"
#/rescompdata/ms/unprocessed/RESCOMP/CFTY720D2201/sub-CFTY720D2201x0043x00011/T12D.autorecon12ws.nuws_mrirobusttemplate_demo
LT_OUTPUT_DIR=${PRSD_DIR}/${StudyID}/sub-${SubID}/${ImgTyp}.${DirSuffix}.${LT_DirSuffix}
mkdir -p ${LT_OUTPUT_DIR}

echo ""
echo "made this dude: $LT_OUTPUT_DIR"
echo ""

DataDir="/home/bdivdi.local/dfgtyk/NVROXBOX/Data/RELAB"
SessionsDir=${DataDir}/${StudyID}/${ImgTyp}/Sessions
SessionTxtFile=${SessionsDir}/${StudyID}_sub-${SubID}_${ImgTyp}.txt


#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------
OutputDIR=/home/bdivdi.local/dfgtyk/NVROXBOX/EXE/makegif/sliceR
rubbishbin=$(mktemp -d /tmp/slicerdir.XXXXXXXXX)

rm -rf ${OutputDIR}
mkdir -p ${OutputDIR}
mkdir -p $rubbishbin

sliceropts="$edgeopts -x 0.4 $rubbishbin/grota.png -x 0.5 $rubbishbin/grotb.png -x 0.6 $rubbishbin/grotc.png -y 0.4 $rubbishbin/grotd.png -y 0.5 $rubbishbin/grote.png -y 0.6 $rubbishbin/grotf.png -z 0.4 $rubbishbin/grotg.png -z 0.5 $rubbishbin/groth.png -z 0.6 $rubbishbin/groti.png"
convertopts="$rubbishbin/grota.png + $rubbishbin/grotb.png + $rubbishbin/grotc.png + $rubbishbin/grotd.png + $rubbishbin/grote.png + $rubbishbin/grotf.png + $rubbishbin/grotg.png + $rubbishbin/groth.png + $rubbishbin/groti.png"

echo ${SesID_List_arr[@]}





#fslreorient2std ${template_pathname} $rubbishbin/fs_tmp.nii.gz
#${FSLDIR}/bin/slicer $rubbishbin/fs_tmp.nii.gz -s 1 $sliceropts
#${FSLDIR}/bin/pngappend $convertopts ${OutputDIR}/fs_template.png


SINCEBL=(0 6 12 24)

#for SesID in ${SesID_List_arr[@]}
RAWGIF=""
FSSSTGIF=""
ANTSSTGIF=""
SEGGIF=""
SEG2RAWGIF=""
SEG1GIF=""

cnt_fk=(3 0 1 2)

cnt=0
while read SesID
do

	echo $cnt
	echo "Now on: $SesID"

	SesIDDate0=$(echo $SesID | awk -F"x" '{print $2}')
	YEARRR=$(echo "$SesIDDate0" | cut -c1-4)
	MONTHHH=$(echo "$SesIDDate0" | cut -c5-6)
	DAYYY=$(echo "$SesIDDate0" | cut -c7-8)

	SesIDDate="Month(s) since baseline ${SINCEBL[$cnt]} (${YEARRR}/${MONTHHH}/${DAYYY})"
#	SesIDDate="${YEARRR}/${MONTHHH}/${DAYYY}"
	echo $SesIDDate

#	RAWAVG_DIR=${PRSD_DIR}/${StudyID}/sub-${SubID}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_run-1_T1w.autorecon12ws/sub-${SubID}_ses-${SesID}_run-1_T1w/mri
#	mri_convert $RAWAVG_DIR/orig/001.mgz $rubbishbin/001.nii.gz > /dev/null 2>&1
#	fslreorient2std $rubbishbin/001.nii.gz $rubbishbin/rawavgwholebrain.nii.gz

	RAWAVG_DIR=${UNPRSD_DIR}/${StudyID}/sub-${SubID}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_run-1_T1w.nii.gz
	cp $RAWAVG_DIR $rubbishbin/rawavgwholebrain.nii.gz

	PNGIMGNAME_RAWBE=${SubID}_${SesID}_RAWAVG_core
	${FSLDIR}/bin/slicer $rubbishbin/rawavgwholebrain.nii.gz -s 1 $sliceropts
	${FSLDIR}/bin/pngappend $convertopts ${OutputDIR}/${PNGIMGNAME_RAWBE}.png

	convert ${OutputDIR}/${PNGIMGNAME_RAWBE}.png -resize 2304x286! -quality 100 ${OutputDIR}/${PNGIMGNAME_RAWBE}.png

	convert ${OutputDIR}/${PNGIMGNAME_RAWBE}.png -background Khaki -pointsize 30 label:"$SesIDDate" -gravity Center -append ${OutputDIR}/${PNGIMGNAME_RAWBE}.png

	RAWGIF="${RAWGIF} ${OutputDIR}/${PNGIMGNAME_RAWBE}.png"

#----------------------------

	FSSST=${LT_OUTPUT_DIR}/sub-${SubID}_ses-${SesID}_nu_2_median_nu.nii.gz
	fslreorient2std $FSSST $rubbishbin/fssst.nii.gz

	PNGIMGNAME_RAWBE=${SubID}_${SesID}_FSSST_core
	${FSLDIR}/bin/slicer $rubbishbin/fssst.nii.gz -s 1 $sliceropts
	${FSLDIR}/bin/pngappend $convertopts ${OutputDIR}/${PNGIMGNAME_RAWBE}.png

	convert ${OutputDIR}/${PNGIMGNAME_RAWBE}.png -resize 2304x286! -quality 100 ${OutputDIR}/${PNGIMGNAME_RAWBE}.png

	convert ${OutputDIR}/${PNGIMGNAME_RAWBE}.png -background Khaki -pointsize 30 label:"$SesIDDate" -gravity Center -append ${OutputDIR}/${PNGIMGNAME_RAWBE}.png

	FSSSTGIF="${FSSSTGIF} ${OutputDIR}/${PNGIMGNAME_RAWBE}.png"

#---------------------------

	ANTSST=${LT_OUTPUT_DIR}/sub-${SubID}_ants_temp_med_nutemplate0sub-${SubID}_ses-${SesID}_nu_2_median_nu${cnt_fk[$cnt]}WarpedToTemplate.nii.gz
	fslreorient2std $ANTSST $rubbishbin/antsst.nii.gz

	PNGIMGNAME_RAWBE=${SubID}_${SesID}_ANTSSST_core
	${FSLDIR}/bin/slicer $rubbishbin/antsst.nii.gz -s 1 $sliceropts
	${FSLDIR}/bin/pngappend $convertopts ${OutputDIR}/${PNGIMGNAME_RAWBE}.png

	convert ${OutputDIR}/${PNGIMGNAME_RAWBE}.png -resize 2304x286! -quality 100 ${OutputDIR}/${PNGIMGNAME_RAWBE}.png

	convert ${OutputDIR}/${PNGIMGNAME_RAWBE}.png -background Khaki -pointsize 30 label:"$SesIDDate" -gravity Center -append ${OutputDIR}/${PNGIMGNAME_RAWBE}.png

	ANTSSTGIF="${ANTSSTGIF} ${OutputDIR}/${PNGIMGNAME_RAWBE}.png"

#---------------------------

	SEGDIR=${PRSD_DIR}/${StudyID}/sub-${SubID}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_fast_BETsREG_2tissues_brain_rawavg
	SEGIMG=${SEGDIR}/sub-${SubID}_ses-${SesID}_fast_BETsREG_brain_rawavg_denoised_N4_2tissues_pve_1.nii.gz

	fslreorient2std $SEGIMG $rubbishbin/seg.nii.gz

	PNGIMGNAME_RAWBE=${SubID}_${SesID}_SEG_core
	${FSLDIR}/bin/slicer $rubbishbin/seg.nii.gz -s 1 $sliceropts
	${FSLDIR}/bin/pngappend $convertopts ${OutputDIR}/${PNGIMGNAME_RAWBE}.png

	convert ${OutputDIR}/${PNGIMGNAME_RAWBE}.png -resize 2304x286! -quality 100 ${OutputDIR}/${PNGIMGNAME_RAWBE}.png

	convert ${OutputDIR}/${PNGIMGNAME_RAWBE}.png -background Khaki -pointsize 30 label:"$SesIDDate" -gravity Center -append ${OutputDIR}/${PNGIMGNAME_RAWBE}.png

	SEGGIF="${SEGGIF} ${OutputDIR}/${PNGIMGNAME_RAWBE}.png"


#---------------------------

	PNGIMGNAME_RAWBE=${SubID}_${SesID}_SEGonRAW_core
	${FSLDIR}/bin/slicer $rubbishbin/rawavgwholebrain.nii.gz $rubbishbin/seg.nii.gz -s 1 $sliceropts
	${FSLDIR}/bin/pngappend $convertopts ${OutputDIR}/${PNGIMGNAME_RAWBE}.png

	convert ${OutputDIR}/${PNGIMGNAME_RAWBE}.png -resize 2304x286! -quality 100 ${OutputDIR}/${PNGIMGNAME_RAWBE}.png
	convert ${OutputDIR}/${PNGIMGNAME_RAWBE}.png -background Khaki -pointsize 30 label:"$SesIDDate" -gravity Center -append ${OutputDIR}/${PNGIMGNAME_RAWBE}.png

	SEG2RAWGIF="${SEG2RAWGIF} ${OutputDIR}/${PNGIMGNAME_RAWBE}.png"

#---------------------------

	PNGIMGNAME_RAWBE=${SubID}_${SesID}_SEG1onRAW_core

	SEGDIR=${PRSD_DIR}/${StudyID}/sub-${SubID}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_fast_brain_rawavg
	SEGIMG=${SEGDIR}/sub-${SubID}_ses-${SesID}_fast_brain_rawavg_denoised_N4_seg_1.nii.gz

	fslreorient2std $SEGIMG $rubbishbin/seg1.nii.gz

	${FSLDIR}/bin/slicer $rubbishbin/rawavgwholebrain.nii.gz $rubbishbin/seg1.nii.gz -s 1 $sliceropts
	${FSLDIR}/bin/pngappend $convertopts ${OutputDIR}/${PNGIMGNAME_RAWBE}.png

	convert ${OutputDIR}/${PNGIMGNAME_RAWBE}.png -resize 2304x286! -quality 100 ${OutputDIR}/${PNGIMGNAME_RAWBE}.png
	convert ${OutputDIR}/${PNGIMGNAME_RAWBE}.png -background Khaki -pointsize 30 label:"$SesIDDate" -gravity Center -append ${OutputDIR}/${PNGIMGNAME_RAWBE}.png

	SEG1GIF="${SEG1GIF} ${OutputDIR}/${PNGIMGNAME_RAWBE}.png"

	cnt=$((cnt+1))

done</home/bdivdi.local/dfgtyk/NVROXBOX/EXE/makegif/ordereddates_core


echo $FSSSTGIF
echo $RAWGIF
echo $ANTSSTGIF
echo $SEGGIF

convert -loop 0 -delay 100 $FSSSTGIF sub-${SubID}_FSSST_core.gif
convert -loop 0 -delay 100 $RAWGIF sub-${SubID}_RAW_core.gif
convert -loop 0 -delay 100 $ANTSSTGIF sub-${SubID}_ANTSST_core.gif
convert -loop 0 -delay 100 $SEGGIF sub-${SubID}_SEG_core.gif
convert -loop 0 -delay 100 $SEG2RAWGIF sub-${SubID}_SEG2RAW_core.gif
convert -loop 0 -delay 100 $SEG1GIF sub-${SubID}_SEG1_core.gif
