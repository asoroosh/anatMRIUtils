# produces png files of the volume, using $FSLDIR/bin/slicer and then stiches the images together and make them ready
# for the python html code to come and read them
# sh FUNCTION.sh <wild card to the images> <path to the output images>

PATH2IMGB=

if [ "$#" -eq 2 ]; then
	PATH2IMG=$1
	OUPUTIMAGE=$2
elif [ "$#" -eq 3 ]; then
	PATH2IMG=$1
	PATH2IMGB=$2
	OUPUTIMAGE=$3
else
	echo "Illegal number of input!"
	exit 1
fi

#PATH2IMG=$1
#OUPUTIMAGE=$2
#/home/bdivdi.local/dfgtyk/NVROXBOX/EXE/qc/slicesdir_test/slicesdir

sliceropts="-x 0.4 $OUPUTIMAGE/grota.png -x 0.5 $OUPUTIMAGE/grotb.png -x 0.6 $OUPUTIMAGE/grotc.png -y 0.4 $OUPUTIMAGE/grotd.png -y 0.5 $OUPUTIMAGE/grote.png -y 0.6 $OUPUTIMAGE/grotf.png -z 0.4 $OUPUTIMAGE/grotg.png -z 0.5 $OUPUTIMAGE/groth.png -z 0.6 $OUPUTIMAGE/groti.png"
convertopts="$OUPUTIMAGE/grota.png + $OUPUTIMAGE/grotb.png + $OUPUTIMAGE/grotc.png + $OUPUTIMAGE/grotd.png + $OUPUTIMAGE/grote.png + $OUPUTIMAGE/grotf.png + $OUPUTIMAGE/grotg.png + $OUPUTIMAGE/groth.png + $OUPUTIMAGE/groti.png"

mkdir -p $OUPUTIMAGE

echo "OUTPUTDIR: ${OUPUTIMAGE}"

slicer $PATH2IMG $PATH2IMGB -s 1 $sliceropts
IMG_basename=$(basename $PATH2IMG .nii.gz)
SingleImageName="${OUPUTIMAGE}/IMG_${IMG_basename}.png"
pngappend $convertopts $SingleImageName

rm $OUPUTIMAGE/grot*.png



