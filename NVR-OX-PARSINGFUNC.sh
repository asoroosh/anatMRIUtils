###############################################################################
###############################################################################
# extracts the option name from any version (-- or -)
get_opt1() {
    arg=`echo $1 | sed 's/=.*//'`
    echo $arg
}

# get arg for -- options
get_arg1() {
    if [ X`echo $1 | grep '='` = X ] ; then
	echo "Option $1 requires an argument" 1>&2
	exit 1
    else
	arg=`echo $1 | sed 's/.*=//'`
	if [ X$arg = X ] ; then
	    echo "Option $1 requires an argument" 1>&2
	    exit 1
	fi
	echo $arg
    fi
}

# get image filename from -- options
get_imarg1() {
    arg=`get_arg1 $1`;
    arg=`$FSLDIR/bin/remove_ext $arg`;
    echo $arg
}

# get arg for - options (need to pass both $1 and $2 to this)
get_arg2() {
    if [ X$2 = X ] ; then
	echo "Option $1 requires an argument" 1>&2
	exit 1
    fi
    echo $2
}

# get arg of image filenames for - options (need to pass both $1 and $2 to this)
get_imarg2() {
    arg=`get_arg2 $1 $2`;
    arg=`$FSLDIR/bin/remove_ext $arg`;
    echo $arg
}

Take_a_Pic(){
  A=`${FSLDIR}/bin/remove_ext $1`
  #echo "Will be read from:  $A"
  FileName=${A##*/}
  #echo $FileName
  outputpath=$2
  echo "The picture will be saved in: $outputpath"
  sliceropts="-x 0.4 tmp_a.png -x 0.5 tmp_b.png -x 0.6 tmp_c.png -y 0.4 tmp_d.png -y 0.5 tmp_e.png -y 0.6 tmp_f.png -z 0.4 tmp_g.png -z 0.5 tmp_h.png -z 0.6 tmp_i.png"
  convertopts="tmp_a.png + tmp_b.png + tmp_c.png + tmp_d.png + tmp_e.png + tmp_f.png + tmp_g.png + tmp_h.png + tmp_i.png"

  ${FSLDIR}/bin/slicer $A -s 1 $sliceropts
  ${FSLDIR}/bin/pngappend $convertopts $outputpath/${FileName}.png
  rm tmp_*.png
}

###############################################################################
###############################################################################
