# produces png files of the volume, using $FSLDIR/bin/slicer and then stiches the images together and make them ready
# for the python html code to come and read them
# sh FUNCTION.sh <wild card to the images> <path to the output images>

NUMIMG_IMG=

PATH2IMG=$1
OUPUTIMAGE=$2
NUMIMG_IMG=$3
#/home/bdivdi.local/dfgtyk/NVROXBOX/EXE/qc/slicesdir_test/slicesdir

sliceropts="-x 0.4 $OUPUTIMAGE/grota.png -x 0.5 $OUPUTIMAGE/grotb.png -x 0.6 $OUPUTIMAGE/grotc.png -y 0.4 $OUPUTIMAGE/grotd.png -y 0.5 $OUPUTIMAGE/grote.png -y 0.6 $OUPUTIMAGE/grotf.png -z 0.4 $OUPUTIMAGE/grotg.png -z 0.5 $OUPUTIMAGE/groth.png -z 0.6 $OUPUTIMAGE/groti.png"
convertopts="$OUPUTIMAGE/grota.png + $OUPUTIMAGE/grotb.png + $OUPUTIMAGE/grotc.png + $OUPUTIMAGE/grotd.png + $OUPUTIMAGE/grote.png + $OUPUTIMAGE/grotf.png + $OUPUTIMAGE/grotg.png + $OUPUTIMAGE/groth.png + $OUPUTIMAGE/groti.png"

NUMALLIMG=$(ls $PATH2IMG | wc -l)
IMG_tfile=$(mktemp /tmp/NVROX_MRI_QC_IMG.XXXXXXXXX)
ls $PATH2IMG > $IMG_tfile

mkdir -p $OUPUTIMAGE

echo "Total number of images: $NUMALLIMG"

if [ -z $NUMIMG_IMG ]; then
	NUMIMG_IMG=$NUMALLIMG
	echo "We use total number of images: $NUMIMG_IMG"
else
#	NUMIMG_IMG=$NUMALLIMG
	echo "Number of images set to: $NUMIMG_IMG"
fi


echo "OUTPUTDIR: ${OUPUTIMAGE}"

for linenum in `seq 1 $NUMIMG_IMG`
do

	IMGPATH=$(cat $IMG_tfile | sed -n ${linenum}p) #read the linenum_th line

	StudyIDVar=$(echo $IMGPATH | awk -F"/" '{print $6}') # Study ID
	SubIDVar=$(echo $IMGPATH | awk -F"/" '{print $7}') # Sub ID
	SesIDVar=$(echo $IMGPATH | awk -F"/" '{print $8}') # Session ID
	ModIDVar=$(echo $IMGPATH | awk -F"/" '{print $9}')
	ImgNameEx=$(echo $IMGPATH | awk -F"/" '{print $10}')

	Img1=$(echo $ImgNameEx | awk -F"." '{print $1}')
	Img2=$(echo $ImgNameEx | awk -F"." '{print $2}')
	Img3=$(echo $ImgNameEx | awk -F"." '{print $3}')

#	echo "== == == == =="
#	echo "NOW ON $linenum "
#	echo "TO: ($linenum) $IMGPATH"
#	echo "== == == == =="

	slicer $IMGPATH -s 1 $sliceropts

	IMG_basename=$(basename $IMGPATH .nii.gz)

	SingleImageName="${OUPUTIMAGE}/IMG_${SubIDVar}_${SesIDVar}_${IMG_basename}.png"
	echo "IMAGE ($linenum) $SingleImageName"
	pngappend $convertopts $SingleImageName

	rm $OUPUTIMAGE/grot*.png
done

rm $IMG_tfile


