
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
LT_DirSuffix="nuws_mrirobusttemplate_demo"
#/rescompdata/ms/unprocessed/RESCOMP/CFTY720D2201/sub-CFTY720D2201x0043x00011/T12D.autorecon12ws.nuws_mrirobusttemplate_demo
LT_OUTPUT_DIR=${PRSD_DIR}/${StudyID}/sub-${SubID}/${ImgTyp}.${DirSuffix}.${LT_DirSuffix}
mkdir -p ${LT_OUTPUT_DIR}

echo ""
echo "made this dude: $LT_OUTPUT_DIR"
echo ""

DataDir="/home/bdivdi.local/dfgtyk/NVROXBOX/Data/RELAB"
SessionsDir=${DataDir}/${StudyID}/${ImgTyp}/Sessions
SessionTxtFile=${SessionsDir}/${StudyID}_sub-${SubID}_${ImgTyp}.txt

#--form the session image lists -----
mov_list=""
nu_mov_list=""

lta_list=""
mapmov_list=""

SesID_List=""

while read SessionFileName
do
        # Where do you want to get your data from? e.g. ANTs?
        StudyIDVar=$(echo $SessionFileName | awk -F"/" '{print $8}') # Study ID
        SubIDVar=$(echo $SessionFileName | awk -F"/" '{print $9}') # Sub ID
        SesIDVar=$(echo $SessionFileName | awk -F"/" '{print $10}') # Session ID
        SesID=$(echo $SesIDVar | awk -F"-" '{print $2}') # Session ID

	ModIDVar=$(echo $SessionFileName | awk -F"/" '{print $11}') #Modality type: anat, dwi etc
        ImgNameEx=$(echo $SessionFileName | awk -F"/" '{print $12}') #ImageName with extension
        ImgName=$(basename $ImgNameEx .nii.gz) # ImageName without extension

        echo "==== On session: ${StudyIDVar}, ${SubIDVar}, ${SesIDVar}"

        #CROSS SECTIONAL RESULTS -------------------------------------------------------

        #FS
        CS_INPUT_DIR=${PRSD_DIR}/${StudyIDVar}/${SubIDVar}/${SesIDVar}/${ModIDVar}/${ImgName}.${DirSuffix}
        CS_IMAGE_BASE=norm
        CS_IMAGE_NAME=${CS_INPUT_DIR}/${ImgName}/mri/${CS_IMAGE_BASE}.mgz
        CS_NU_IMAGE_NAME=${CS_INPUT_DIR}/${ImgName}/mri/nu.mgz

        #-------------------------------------------------------------------------------

        LTA_IMAGE_NAME=${LT_OUTPUT_DIR}/${SubIDVar}_${SesIDVar}_${CS_IMAGE_BASE}_xforms.lta
        MPMV_IMAGE_NAME=${LT_OUTPUT_DIR}/${SubIDVar}_${SesIDVar}_${CS_IMAGE_BASE}_mapmov.nii.gz

        # Now form the arrays for the robust_mri_template
        mov_list="${mov_list} ${CS_IMAGE_NAME}"
        nu_mov_list="${nu_mov_list} ${CS_NU_IMAGE_NAME}"
        lta_list="${lta_list} ${LTA_IMAGE_NAME}"
        mapmov_list="${mapmov_list} ${MPMV_IMAGE_NAME}"
        #SesID_List="${SesID_List} ${SesIDVar}"
	echo $SesID
	SesID_List="${SesID_List} ${SesID}"

done<${SessionTxtFile}

mov_list_arr=($mov_list)
nu_mov_list_arr=($nu_mov_list)
lta_list_arr=($lta_list)
mapmov_list_arr=($mapmov_list)
SesID_List_arr=($SesID_List)

NumSes=$(cat ${SessionTxtFile} | wc -l)

# Just keep a copy of the sessions for the record...
#cp ${SessionTxtFile} ${LT_OUTPUT_DIR}

template_pathname=${LT_OUTPUT_DIR}/sub-${SubID}_${CS_IMAGE_BASE}_median.nii.gz
nu_template_pathname=${LT_OUTPUT_DIR}/sub-${SubID}_${CS_IMAGE_BASE}_nu_median.nii.gz

echo "NumSes: $NumSes"




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





fslreorient2std ${template_pathname} $rubbishbin/fs_tmp.nii.gz
${FSLDIR}/bin/slicer $rubbishbin/fs_tmp.nii.gz -s 1 $sliceropts
${FSLDIR}/bin/pngappend $convertopts ${OutputDIR}/fs_template.png


SINCEBL=(0 1 2 3 4 5 6 12 18 24 36 60 72 84 96 123 124)

#for SesID in ${SesID_List_arr[@]}
RAWGIF=""
FSSSTGIF=""

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

	PNGIMGNAME_RAWBE=${SubID}_${SesID}_RAWAVG
	${FSLDIR}/bin/slicer $rubbishbin/rawavgwholebrain.nii.gz -s 1 $sliceropts
	${FSLDIR}/bin/pngappend $convertopts ${OutputDIR}/${PNGIMGNAME_RAWBE}.png

	convert ${OutputDIR}/${PNGIMGNAME_RAWBE}.png -resize 2304x286! -quality 100 ${OutputDIR}/${PNGIMGNAME_RAWBE}.png

	convert ${OutputDIR}/${PNGIMGNAME_RAWBE}.png -background Khaki -pointsize 30 label:"$SesIDDate" -gravity Center -append ${OutputDIR}/${PNGIMGNAME_RAWBE}.png

	RAWGIF="${RAWGIF} ${OutputDIR}/${PNGIMGNAME_RAWBE}.png"

#----------------------------

	FSSST=${LT_OUTPUT_DIR}/sub-${SubID}_ses-${SesID}_nu_2_median_nu.nii.gz
	fslreorient2std $FSSST $rubbishbin/fssst.nii.gz

	PNGIMGNAME_RAWBE=${SubID}_${SesID}_FSSST
	${FSLDIR}/bin/slicer $rubbishbin/fssst.nii.gz -s 1 $sliceropts
	${FSLDIR}/bin/pngappend $convertopts ${OutputDIR}/${PNGIMGNAME_RAWBE}.png

	convert ${OutputDIR}/${PNGIMGNAME_RAWBE}.png -resize 2304x286! -quality 100 ${OutputDIR}/${PNGIMGNAME_RAWBE}.png

	convert ${OutputDIR}/${PNGIMGNAME_RAWBE}.png -background Khaki -pointsize 30 label:"$SesIDDate" -gravity Center -append ${OutputDIR}/${PNGIMGNAME_RAWBE}.png

	FSSSTGIF="${FSSSTGIF} ${OutputDIR}/${PNGIMGNAME_RAWBE}.png"

	cnt=$((cnt+1))

done</home/bdivdi.local/dfgtyk/NVROXBOX/EXE/makegif/ordereddates


echo $FSSSTGIF
echo $RAWGIF

convert -loop 0 -delay 100 $FSSSTGIF sub-${SubID}_FSSST.gif
convert -loop 0 -delay 100 $RAWGIF sub-${SubID}_RAW.gif
