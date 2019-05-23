
set -e

source NVR-OX-PARSINGFUNC.sh

type=1  # For FAST: 1 = T1w, 2 = T2w, 3 = PD

Usage() {
echo "For later..."
}

if [ $# -eq 0 ] ; then Usage; exit 0; fi
if [ $# -lt 2 ] ; then Usage; exit 1; fi
while [ $# -ge 1 ] ; do
    iarg=`get_opt1 $1`;
    case "$iarg"
	in
	-i)
	    inputimage=`get_imarg2 $1 $2`;
	    shift 2;;
  -d)
    	outputname=`get_arg2 $1 $2`;
    	shift 2;;
	-t)
	    typestr=`get_arg2 $1 $2`;
	    if [ $typestr = T1 ] ; then type=1; fi
	    if [ str = T2 ] ; then type=2; fi
	    if [ $typestr = PD ] ; then type=3; fi
	    shift 2;;
      *)
    	    #if [ `echo $1 | sed 's/^\(.\).*/\1/'` = "-" ] ; then
    	    echo "Unrecognised option $1" 1>&2
    	    exit 1
    esac
done

LOGFILE=log.txt
run() {
  echo $@ >> $LOGFILE
  $@
}

runt() {
echo `date` $1 >> $LOGFILE
echo $1
}

# Well, this is not very clean, but no matter what the input is the image under
# the hammer will be called T1
T1=T1;
if [ $type = 2 ] ; then T1=T2; fi
if [ $type = 3 ] ; then T1=PD; fi

# Read and Clean
#inputimage=$1

inputimage=`$FSLDIR/bin/remove_ext $inputimage`; #Get the name of the image without the file formats (e.g. nii/nii.gz etc)

if [ X$outputname = X ] ; then
  outputname=$inputimage; #Put the name of the input image as name of the anat folder
fi


runt "Here is the image: $inputimage"

if [ -d ${outputname}.REORCROP ] ; then
  if [ $clobber = no ] ; then
    echo "ERROR: Directory ${outputname}.REORCROP already exists!"
    exit 1;
  else
    rm -rf ${outputname}.REORCROP
  fi
fi

anatdir=${outputname}.REORCROP
mkdir -p $anatdir
$FSLDIR/bin/fslmaths ${inputimage} $anatdir/T1
cd $anatdir
pwd
echo " " >> $LOGFILE

#### FIXING NEGATIVE RANGE
# required input: ${T1}
# output: ${T1}
minval=`$FSLDIR/bin/fslstats ${T1} -p 0`;
maxval=`$FSLDIR/bin/fslstats ${T1} -p 100`;
if [ X`echo "if ( $minval < 0 ) { 1 }" | bc -l` = X1 ] ; then
    if [ X`echo "if ( $maxval > 0 ) { 1 }" | bc -l` = X1 ] ; then
	# if there are just some negative values among the positive ones then reset zero to the min value
	run ${FSLDIR}/bin/fslmaths ${T1} -sub $minval ${T1} -odt float
    else
	# if all values are negative then make them positive, but retain any zeros as zeros
	run ${FSLDIR}/bin/fslmaths ${T1} -bin -binv zeromask
	run ${FSLDIR}/bin/fslmaths ${T1} -sub $minval -mas zeromask ${T1} -odt float
    fi
fi

#### REORIENTATION 2 STANDARD #############################################################################
# required input: ${T1}
# output: ${T1} (modified) [ and ${T1}_orig and .mat ]
runt "Reorienting to standard orientation"
run $FSLDIR/bin/fslmaths ${T1} ${T1}_orig

echo "Take a picture..."
Take_a_Pic ${T1}_orig `pwd`

run $FSLDIR/bin/fslreorient2std ${T1} > ${T1}_orig2std.mat
run $FSLDIR/bin/convert_xfm -omat ${T1}_std2orig.mat -inverse ${T1}_orig2std.mat
run $FSLDIR/bin/fslreorient2std ${T1} ${T1}_orig2std

echo "Take a picture..."
Take_a_Pic ${T1} `pwd`

#### AUTOMATIC CROPPING ####################################################################################
# required input: ${T1}
# output: ${T1} (modified) [ and ${T1}_fullfov plus various .mats ]

runt "Cropping out neck and fixing the field of view"
run $FSLDIR/bin/immv ${T1}_orig2std ${T1}_fullfov
run $FSLDIR/bin/robustfov -i ${T1}_fullfov -r ${T1}_fullfov -m ${T1}_roi2nonroi.mat | grep [0-9] | tail -1 > ${T1}_roi.log
# combine this mat file and the one above (if generated)
run $FSLDIR/bin/convert_xfm -omat ${T1}_nonroi2roi.mat -inverse ${T1}_roi2nonroi.mat
run $FSLDIR/bin/convert_xfm -omat ${T1}_orig2roi.mat -concat ${T1}_nonroi2roi.mat ${T1}_orig2std.mat
run $FSLDIR/bin/convert_xfm -omat ${T1}_roi2orig.mat -inverse ${T1}_orig2roi.mat

echo "Take a picture..."
Take_a_Pic ${T1}_fullfov `pwd`

runt "Cleaning up intermediate files"

runt "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
runt "xxxxx END OF CODE xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
runt "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
