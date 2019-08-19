# prints out the png files of the images overlied at top of each other.
# note that the images should be paired, otherwise it doesn't work properly
# sh FUNCTION.sh <background images> <rediutlined images> <path to the png images>

PATH2IMG_B=/data/ms/processed/mri/CFTY720D2201.anon.2019.07.23/sub-CFTY720D2201.0063.00012/ses-*/anat/*.fslanat/*.anat/T1_biascorr_brain.nii.gz
PATH2IMG_A=/data/ms/processed/mri/CFTY720D2201.anon.2019.07.23/sub-CFTY720D2201.0063.00012/ses-*/anat/*.fslanat/*.anat/T1_biascorr.nii.gz
OUPUTIMAGE=/home/bdivdi.local/dfgtyk/NVROXBOX/EXE/qc/slicesdir_test/slicesdir
NUMIMG_IMG=3

mkdir -p $OUPUTIMAGE
sliceropts="-x 0.4 $OUPUTIMAGE/grota.png -x 0.5 $OUPUTIMAGE/grotb.png -x 0.6 $OUPUTIMAGE/grotc.png -y 0.4 $OUPUTIMAGE/grotd.png -y 0.5 $OUPUTIMAGE/grote.png -y 0.6 $OUPUTIMAGE/grotf.png -z 0.4 $OUPUTIMAGE/grotg.png -z 0.5 $OUPUTIMAGE/groth.png -z 0.6 $OUPUTIMAGE/groti.png"
convertopts="$OUPUTIMAGE/grota.png + $OUPUTIMAGE/grotb.png + $OUPUTIMAGE/grotc.png + $OUPUTIMAGE/grotd.png + $OUPUTIMAGE/grote.png + $OUPUTIMAGE/grotf.png + $OUPUTIMAGE/grotg.png + $OUPUTIMAGE/groth.png + $OUPUTIMAGE/groti.png"

NUMIMG_A=$(ls $PATH2IMG_A | wc -l)
echo "Number of background images: $NUMIMG_A"
IMG_A_tfile=$(mktemp /tmp/NVROX_MRI_QC_Redlayer.XXXXXXXXX)
ls $PATH2IMG_A > $IMG_A_tfile

NUMIMG_B=$(ls $PATH2IMG_B | wc -l)
echo "Number of redoutlines: $NUMIMG_B"

if [ $NUMIMG_A != $NUMIMG_B ]; then
	echo "&&&& WARNING: Number of input images are different from red outlines. &&&&&"
fi

if [ $NUMIMG_B -gt 1 ]; then
	IMG_B_tfile=$(mktemp /tmp/NVROX_MRI_QC_BG.XXXXXXXXX)
	ls $PATH2IMG_B > $IMG_B_tfile
else
	echo "There is only one image to overlay on all other input images"
	BackgroundImage=$PATH2IMG_B
fi

if [ -z $NUMIMG_IMG ]; then
	NUMIMG_IMG=$NUMIMG_A
	echo "Number of images: $NUMIMG_IMG"
fi

for linenum in `seq 1 $NUMIMG_IMG`
do
	IMG_A_LINE=$(cat $IMG_A_tfile | sed -n ${linenum}p) #read the linenum_th line

	StudyIDVar=$(echo $IMG_A_LINE | awk -F"/" '{print $6}') # Study ID
	SubIDVar=$(echo $IMG_A_LINE | awk -F"/" '{print $7}') # Sub ID
	SesIDVar=$(echo $IMG_A_LINE | awk -F"/" '{print $8}') # Session ID
	ModIDVar=$(echo $IMG_A_LINE | awk -F"/" '{print $9}')
	ImgNameEx=$(echo $IMG_A_LINE | awk -F"/" '{print $10}')

	Img1=$(echo $ImgNameEx | awk -F"." '{print $1}')
	Img2=$(echo $ImgNameEx | awk -F"." '{print $2}')
	Img3=$(echo $ImgNameEx | awk -F"." '{print $3}')

	if [ $NUMIMG_B -gt 1 ]; then
		IMG_B_LINE=$(cat $IMG_B_tfile | grep "/$SubIDVar/$SesIDVar/$ModIDVar/")
	fi

	echo "== == == == =="
	echo "On image set $linenum atm."
	echo "FROM: $IMG_A_LINE"
	echo "TO: $IMG_B_LINE"
	echo "== == == == =="

	$FSLDIR/bin/slicer $IMG_A_LINE $IMG_B_LINE -s 1 $sliceropts

	A_basename=$(basename $IMG_A_LINE .nii.gz)
	B_basename=$(basename $IMG_B_LINE .nii.gz)

	CombImageName="${OUPUTIMAGE}/COMB_${SubIDVar}_${SesIDVar}_${A_basename}_on_${B_basename}.png"
	echo "IMAGE: $CombImageName"
	$FSLDIR/bin/pngappend $convertopts $CombImageName

	rm $OUPUTIMAGE/grot*.png
done

rm $IMG_A_tfile $IMG_B_tfile
