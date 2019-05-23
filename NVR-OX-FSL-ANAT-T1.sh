

######
set -e

LOGFILE=log.txt
run() {
  echo $@ >> $LOGFILE
  $@
}

runt() {
echo `date` $1 >> $LOGFILE
echo $1
}

quick_smooth() {
  in=$1
  out=$2
  run $FSLDIR/bin/fslmaths $in -subsamp2 -subsamp2 -subsamp2 -subsamp2 vol16
  run $FSLDIR/bin/flirt -in vol16 -ref $in -out $out -noresampblur -applyxfm -paddingsize 16
  # possibly do a tiny extra smooth to $out here?
  run $FSLDIR/bin/imrm vol16
}
###### READ IN THE FILES
runt "Read and clean"
# Initialisation
clobber=no #Never let the script to over-write, if the directory exists, quit
type=1 # In the original script:: For FAST: 1 = T1w, 2 = T2w, 3 = PD

#run $FSLDIR/bin/fast -o ${T1}_fast -l ${smooth} -b -B -t $type --iter=${niter} ${T1}_biascorr_maskedbrain
niter=10;
smooth=20;

betfparam=0.1;
betopts="-f ${betfparam}"
#run ${FSLDIR}/bin/bet ${T1}_biascorr ${T1}_biascorr_bet -s -m $betopts

# Well, this is not very clean, but no matter what the input is the image under
# the hammer will be called T1
T1=T1;
if [ $type = 2 ] ; then T1=T2; fi
if [ $type = 3 ] ; then T1=PD; fi
# Read and Clean
inputimage=$1
inputimage=`$FSLDIR/bin/remove_ext $inputimage`; #Get the name of the image without the file formats (e.g. nii/nii.gz etc)
outputname=$inputimage; #Put the name of the input image as name of the anat folder

runt "Here is the image: $inputimage"

if [ -d ${outputname}.anat ] ; then
  if [ $clobber = no ] ; then
    echo "ERROR: Directory ${outputname}.anat already exists!"
    exit 1;
  else
    rm -rf ${outputname}.anat
  fi
fi

anatdir=${outputname}.anat
mkdir $anatdir
$FSLDIR/bin/fslmaths ${inputimage} $anatdir/T1
cd $anatdir
pwd
echo " " >> $LOGFILE

#echo "Script invoked from directory = `pwd`" >> ${outputname}.anat/$LOGFILE
#echo "Output directory = ${outputname}.anat" >> ${outputname}.anat/$LOGFILE
######

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
run $FSLDIR/bin/fslreorient2std ${T1} > ${T1}_orig2std.mat
run $FSLDIR/bin/convert_xfm -omat ${T1}_std2orig.mat -inverse ${T1}_orig2std.mat
run $FSLDIR/bin/fslreorient2std ${T1} ${T1}

#### AUTOMATIC CROPPING ####################################################################################
# required input: ${T1}
# output: ${T1} (modified) [ and ${T1}_fullfov plus various .mats ]

runt "Cropping out neck and fixing the field of view"
run $FSLDIR/bin/immv ${T1} ${T1}_fullfov
run $FSLDIR/bin/robustfov -i ${T1}_fullfov -r ${T1} -m ${T1}_roi2nonroi.mat | grep [0-9] | tail -1 > ${T1}_roi.log
# combine this mat file and the one above (if generated)
run $FSLDIR/bin/convert_xfm -omat ${T1}_nonroi2roi.mat -inverse ${T1}_roi2nonroi.mat
run $FSLDIR/bin/convert_xfm -omat ${T1}_orig2roi.mat -concat ${T1}_nonroi2roi.mat ${T1}_orig2std.mat
run $FSLDIR/bin/convert_xfm -omat ${T1}_roi2orig.mat -inverse ${T1}_orig2roi.mat

### LESION MASK
# make appropriate (reoreinted and cropped) lesion mask (or a default blank mask to simplify the code later on)
runt "Lesion mask"
$FSLDIR/bin/fslmaths ${T1} -mul 0 lesionmask
$FSLDIR/bin/fslmaths lesionmask -bin lesionmask
$FSLDIR/bin/fslmaths lesionmask -binv lesionmaskinv

#### BIAS FIELD CORRECTION ##################################################################################
# (main work, although also refined later on if segmentation run)
# required input: ${T1}
# output: ${T1}_biascorr  [ other intermediates to be cleaned up ]
# Bet
# -m          generate binary brain mask
# -f <f>      fractional intensity threshold (0->1); default=0.5; smaller values give larger brain outline estimates
# -g <g>      vertical gradient in fractional intensity threshold (-1->1); default=0; positive values give larger brain outline at bottom, smaller at top

# FAST =========================================================================
#-b		      output estimated bias field
#-B		      output bias-corrected image
#-l         low-pass filter
#--nopve	  turn off PVE (partial volume estimation)
#-O,--fixed	Number of main-loop iterations after bias-field removal; default=4
#--iter     Number of main-loop interations during bias-field removal

# Here is an example for weakbias for time being:
run $FSLDIR/bin/bet ${T1} ${T1}_initfast2_brain -m -f 0.1
run $FSLDIR/bin/fslmaths ${T1}_initfast2_brain ${T1}_initfast2_restore

# redo fast again to try and improve bias field
run $FSLDIR/bin/fslmaths ${T1}_initfast2_restore -mas lesionmaskinv ${T1}_initfast2_maskedrestore

run $FSLDIR/bin/fast -o ${T1}_fast -l ${smooth} -b -B -t $type --iter=${niter} --nopve --fixed=0 -v ${T1}_initfast2_maskedrestore

runt "Extrapolating bias field from central region"
# use the latest fast output
run $FSLDIR/bin/fslmaths ${T1} -div ${T1}_fast_restore -mas ${T1}_initfast2_brain_mask ${T1}_fast_totbias
run $FSLDIR/bin/fslmaths ${T1}_initfast2_brain_mask -ero -ero -ero -ero -mas lesionmaskinv ${T1}_initfast2_brain_mask2
run $FSLDIR/bin/fslmaths ${T1}_fast_totbias -sub 1 ${T1}_fast_totbias
run $FSLDIR/bin/fslsmoothfill -i ${T1}_fast_totbias -m ${T1}_initfast2_brain_mask2 -o ${T1}_fast_bias
run $FSLDIR/bin/fslmaths ${T1}_fast_bias -add 1 ${T1}_fast_bias
run $FSLDIR/bin/fslmaths ${T1}_fast_totbias -add 1 ${T1}_fast_totbias
# run $FSLDIR/bin/fslmaths ${T1}_fast_totbias -sub 1 -mas ${T1}_initfast2_brain_mask -dilall -add 1 ${T1}_fast_bias  # alternative to fslsmoothfill
run $FSLDIR/bin/fslmaths ${T1} -div ${T1}_fast_bias ${T1}_biascorr

#### REGISTRATION AND BRAIN EXTRACTION ####################################################################################
# required input: ${T1}_biascorr
# output: ${T1}_biascorr_brain ${T1}_biascorr_brain_mask ${T1}_to_MNI_lin ${T1}_to_MNI [plus transforms, inverse transforms, jacobians, etc.]
runt "Registering to standard space (linear)"
flirtargs="$flirtargs $nosearch"
# FLIRT ============================================================================================================
# The reference is the non-linear MNI152_T1_2mm?!
run $FSLDIR/bin/flirt -interp spline -dof 12 -in ${T1}_biascorr -ref $FSLDIR/data/standard/MNI152_${T1}_2mm -dof 12 -omat ${T1}_to_MNI_lin.mat -out ${T1}_to_MNI_lin $flirtargs

# FNIRT ============================================================================================================
#  -fillh : fill holes in a binary mask (holes are internal - i.e. do not touch the edge of the FOV)
#  -dilF    : Maximum filtering of all voxels
runt "Registering to standard space (non-linear)"
refmask=MNI152_${T1}_2mm_brain_mask_dil1
fnirtargs=""
run $FSLDIR/bin/fslmaths $FSLDIR/data/standard/MNI152_${T1}_2mm_brain_mask -fillh -dilF $refmask

#--config	Name of config file specifying command line arguments
run ${FSLDIR}/bin/fnirt --in=T1_biascorr --ref=${FSLDIR}/data/standard/MNI152_${T1}_2mm --fout=T1_to_MNI_nonlin_field --jout=T1_to_MNI_nonlin_jac --iout=T1_to_MNI_nonlin --logout=T1_to_MNI_nonlin.txt --cout=T1_to_MNI_nonlin_coeff --config=$FSLDIR/etc/flirtsch/${T1}_2_MNI152_2mm.cnf --aff=${T1}_to_MNI_lin.mat --refmask=$refmask $fnirtargs

runt "Performing brain extraction (using FNIRT)"
run $FSLDIR/bin/invwarp --ref=${T1}_biascorr -w ${T1}_to_MNI_nonlin_coeff -o MNI_to_${T1}_nonlin_field
run $FSLDIR/bin/applywarp --interp=nn --in=$FSLDIR/data/standard/MNI152_${T1}_2mm_brain_mask --ref=${T1}_biascorr -w MNI_to_${T1}_nonlin_field -o ${T1}_biascorr_brain_mask
run $FSLDIR/bin/fslmaths ${T1}_biascorr_brain_mask -fillh ${T1}_biascorr_brain_mask
run $FSLDIR/bin/fslmaths ${T1}_biascorr -mas ${T1}_biascorr_brain_mask ${T1}_biascorr_brain

#### TISSUE-TYPE SEGMENTATION ################################################################################################
# required input: ${T1}_biascorr ${T1}_biascorr_brain ${T1}_biascorr_brain_mask
# output: ${T1}_biascorr ${T1}_biascorr_brain (modified) ${T1}_fast* (as normally output by fast) ${T1}_fast_bias (modified)
# FAST ==================
runt "Performing tissue-type segmentation"
run $FSLDIR/bin/fslmaths ${T1}_biascorr_brain -mas lesionmaskinv ${T1}_biascorr_maskedbrain
run $FSLDIR/bin/fast -o ${T1}_fast -l ${smooth} -b -B -t $type --iter=${niter} ${T1}_biascorr_maskedbrain
run $FSLDIR/bin/immv ${T1}_biascorr ${T1}_biascorr_init
run $FSLDIR/bin/fslmaths ${T1}_fast_restore ${T1}_biascorr_brain
# extrapolate bias field and apply to the whole head image
run $FSLDIR/bin/fslmaths ${T1}_biascorr_brain_mask -mas lesionmaskinv ${T1}_biascorr_brain_mask2
run $FSLDIR/bin/fslmaths ${T1}_biascorr_init -div ${T1}_fast_restore -mas ${T1}_biascorr_brain_mask2 ${T1}_fast_totbias
run $FSLDIR/bin/fslmaths ${T1}_fast_totbias -sub 1 ${T1}_fast_totbias
run $FSLDIR/bin/fslsmoothfill -i ${T1}_fast_totbias -m ${T1}_biascorr_brain_mask2 -o ${T1}_fast_bias
run $FSLDIR/bin/fslmaths ${T1}_fast_bias -add 1 ${T1}_fast_bias
run $FSLDIR/bin/fslmaths ${T1}_fast_totbias -add 1 ${T1}_fast_totbias
# run $FSLDIR/bin/fslmaths ${T1}_fast_totbias -sub 1 -mas ${T1}_biascorr_brain_mask2 -dilall -add 1 ${T1}_fast_bias # alternative to fslsmoothfill
run $FSLDIR/bin/fslmaths ${T1}_biascorr_init -div ${T1}_fast_bias ${T1}_biascorr

# regenerate the standard space version with the new bias field correction applied
run $FSLDIR/bin/applywarp -i ${T1}_biascorr -w ${T1}_to_MNI_nonlin_field -r $FSLDIR/data/standard/MNI152_${T1}_2mm -o ${T1}_to_MNI_nonlin --interp=spline

#### SKULL-CONSTRAINED BRAIN VOLUME ESTIMATION (only done if registration turned on, and segmentation done, and it is a T1 image)
# required inputs: ${T1}_biascorr
# output: ${T1}_vols.txt

runt "Skull-constrained registration (linear)"
run ${FSLDIR}/bin/bet ${T1}_biascorr ${T1}_biascorr_bet -s -m $betopts
run ${FSLDIR}/bin/pairreg ${FSLDIR}/data/standard/MNI152_T1_2mm_brain ${T1}_biascorr_bet ${FSLDIR}/data/standard/MNI152_T1_2mm_skull ${T1}_biascorr_bet_skull ${T1}2std_skullcon.mat

vscale=`${FSLDIR}/bin/avscale ${T1}2std_skullcon.mat | grep Determinant | awk '{ print $3 }'`;
ugrey=`$FSLDIR/bin/fslstats ${T1}_fast_pve_1 -m -v | awk '{ print $1 * $3 }'`;
ngrey=`echo "$ugrey * $vscale" | bc -l`;
uwhite=`$FSLDIR/bin/fslstats ${T1}_fast_pve_2 -m -v | awk '{ print $1 * $3 }'`;
nwhite=`echo "$uwhite * $vscale" | bc -l`;
ubrain=`echo "$ugrey + $uwhite" | bc -l`;
nbrain=`echo "$ngrey + $nwhite" | bc -l`;
echo "Scaling factor from ${T1} to MNI (using skull-constrained linear registration) = $vscale" > ${T1}_vols.txt
echo "Brain volume in mm^3 (native/original space) = $ubrain" >> ${T1}_vols.txt
echo "Brain volume in mm^3 (normalised to MNI) = $nbrain" >> ${T1}_vols.txt

#### SUB-CORTICAL STRUCTURE SEGMENTATION
# required input: ${T1}_biascorr
# output: ${T1}_first*
runt "Performing subcortical segmentation"
# Future note, would be nice to use ${T1}_to_MNI_lin.mat to initialise first_flirt
ffopts=""
run $FSLDIR/bin/first_flirt ${T1}_biascorr ${T1}_biascorr_to_std_sub $ffopts
run mkdir first_results
echo "$FSLDIR/bin/run_first_all $firstreg -i ${T1}_biascorr -o first_results/${T1}_first -a ${T1}_biascorr_to_std_sub.mat" >> $LOGFILE

#FIRSTID=`$FSLDIR/bin/run_first_all $firstreg -i ${T1}_biascorr -o first_results/${T1}_first -a ${T1}_biascorr_to_std_sub.mat`
#echo "$FSLDIR/bin/fsl_sub -T 1 -j $FIRSTID $FSLDIR/bin/imcp first_results/${T1}_first_all_fast_firstseg.${ext} ${T1}_subcort_seg.${ext}" >> $LOGFILE  ## Fix for fsl_sub
#$FSLDIR/bin/fsl_sub -T 1 -j $FIRSTID $FSLDIR/bin/imcp first_results/${T1}_first_all_fast_firstseg.${ext} ${T1}_subcort_seg.${ext} ## Fix for fsl_sub

$FSLDIR/bin/run_first_all $firstreg -i ${T1}_biascorr -o first_results/${T1}_first -a ${T1}_biascorr_to_std_sub.mat
echo "$FSLDIR/bin/fsl_sub -T 1 -j $FIRSTID $FSLDIR/bin/imcp first_results/${T1}_first_all_fast_firstseg.${ext} ${T1}_subcort_seg.${ext}" >> $LOGFILE  ## Fix for fsl_sub

#### CLEANUP
#if [ $do_cleanup = yes ] ; then
  runt "Cleaning up intermediate files"
  run $FSLDIR/bin/imrm ${T1}_biascorr_bet_mask ${T1}_biascorr_bet ${T1}_biascorr_brain_mask2 ${T1}_biascorr_init ${T1}_biascorr_maskedbrain ${T1}_biascorr_to_std_sub ${T1}_fast_bias_idxmask ${T1}_fast_bias_init ${T1}_fast_bias_vol2 ${T1}_fast_bias_vol32 ${T1}_fast_totbias ${T1}_hpf* ${T1}_initfast* ${T1}_s20 ${T1}_initmask_s20
#fi

runt "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
runt "xxxxx END OF CODE xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
runt "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
