/usr/local/fsl/bin/fslmaths T1 T1_orig
/usr/local/fsl/bin/fslreorient2std T1 #> ${T1}_orig2std.mat
/usr/local/fsl/bin/convert_xfm -omat T1_std2orig.mat -inverse T1_orig2std.mat
/usr/local/fsl/bin/fslreorient2std T1 T1

/usr/local/fsl/bin/immv T1 T1_fullfov
/usr/local/fsl/bin/robustfov -i T1_fullfov -r T1 -m T1_roi2nonroi.mat
/usr/local/fsl/bin/convert_xfm -omat T1_nonroi2roi.mat -inverse T1_roi2nonroi.mat
/usr/local/fsl/bin/convert_xfm -omat T1_orig2roi.mat -concat T1_nonroi2roi.mat T1_orig2std.mat
/usr/local/fsl/bin/convert_xfm -omat T1_roi2orig.mat -inverse T1_orig2roi.mat

#Bias Field Correction
/usr/local/fsl/bin/bet T1 T1_initfast2_brain -m -f 0.1
/usr/local/fsl/bin/fslmaths T1_initfast2_brain T1_initfast2_restore

/usr/local/fsl/bin/fslmaths T1_initfast2_restore -mas lesionmaskinv T1_initfast2_maskedrestore
/usr/local/fsl/bin/fast -o T1_fast -l 20 -b -B -t 1 --iter=10 --nopve --fixed=0 -v T1_initfast2_maskedrestore

/usr/local/fsl/bin/fslmaths T1 -div T1_fast_restore -mas T1_initfast2_brain_mask T1_fast_totbias
/usr/local/fsl/bin/fslmaths T1_initfast2_brain_mask -ero -ero -ero -ero -mas lesionmaskinv T1_initfast2_brain_mask2
/usr/local/fsl/bin/fslmaths T1_fast_totbias -sub 1 T1_fast_totbias
/usr/local/fsl/bin/fslsmoothfill -i T1_fast_totbias -m T1_initfast2_brain_mask2 -o T1_fast_bias
/usr/local/fsl/bin/fslmaths T1_fast_bias -add 1 T1_fast_bias
/usr/local/fsl/bin/fslmaths T1_fast_totbias -add 1 T1_fast_totbias
/usr/local/fsl/bin/fslmaths T1 -div T1_fast_bias T1_biascorr

#### REGISTRATION AND BRAIN EXTRACTION ##########################################
#FLIRT
/usr/local/fsl/bin/flirt -interp spline -dof 12 -in T1_biascorr -ref /usr/local/fsl/data/standard/MNI152_T1_2mm -dof 12 -omat T1_to_MNI_lin.mat -out T1_to_MNI_lin
# FNIRT
/usr/local/fsl/bin/fslmaths /usr/local/fsl/data/standard/MNI152_T1_2mm_brain_mask -fillh -dilF MNI152_T1_2mm_brain_mask_dil1
/usr/local/fsl/bin/fnirt --in=T1_biascorr --ref=/usr/local/fsl/data/standard/MNI152_T1_2mm --fout=T1_to_MNI_nonlin_field --jout=T1_to_MNI_nonlin_jac --iout=T1_to_MNI_nonlin --logout=T1_to_MNI_nonlin.txt --cout=T1_to_MNI_nonlin_coeff --config=/usr/local/fsl/etc/flirtsch/T1_2_MNI152_2mm.cnf --aff=T1_to_MNI_lin.mat --refmask=MNI152_T1_2mm_brain_mask_dil1
/usr/local/fsl/bin/invwarp --ref=T1_biascorr -w T1_to_MNI_nonlin_coeff -o MNI_to_T1_nonlin_field
/usr/local/fsl/bin/applywarp --interp=nn --in=/usr/local/fsl/data/standard/MNI152_T1_2mm_brain_mask --ref=T1_biascorr -w MNI_to_T1_nonlin_field -o T1_biascorr_brain_mask
/usr/local/fsl/bin/fslmaths T1_biascorr_brain_mask -fillh T1_biascorr_brain_mask
/usr/local/fsl/bin/fslmaths T1_biascorr -mas T1_biascorr_brain_mask T1_biascorr_brain


#### TISSUE-TYPE SEGMENTATION ################################################################################################
# required input: ${T1}_biascorr ${T1}_biascorr_brain ${T1}_biascorr_brain_mask
# output: ${T1}_biascorr ${T1}_biascorr_brain (modified) ${T1}_fast* (as normally output by fast) ${T1}_fast_bias (modified)
# FAST ==================
/usr/local/fsl/bin/fslmaths T1_biascorr_brain -mas lesionmaskinv T1_biascorr_maskedbrain
/usr/local/fsl/bin/fast -o T1_fast -l 20 -b -B -t 1 --iter=10 T1_biascorr_maskedbrain
/usr/local/fsl/bin/immv T1_biascorr T1_biascorr_init
/usr/local/fsl/bin/fslmaths T1_fast_restore T1_biascorr_brain
/usr/local/fsl/bin/fslmaths T1_biascorr_brain_mask -mas lesionmaskinv T1_biascorr_brain_mask2
/usr/local/fsl/bin/fslmaths T1_biascorr_init -div T1_fast_restore -mas T1_biascorr_brain_mask2 T1_fast_totbias
/usr/local/fsl/bin/fslmaths T1_fast_totbias -sub 1 T1_fast_totbias
/usr/local/fsl/bin/fslsmoothfill -i T1_fast_totbias -m T1_biascorr_brain_mask2 -o T1_fast_bias
/usr/local/fsl/bin/fslmaths T1_fast_bias -add 1 T1_fast_bias
/usr/local/fsl/bin/fslmaths T1_fast_totbias -add 1 T1_fast_totbias
/usr/local/fsl/bin/fslmaths T1_biascorr_init -div T1_fast_bias T1_biascorr
/usr/local/fsl/bin/applywarp -i T1_biascorr -w T1_to_MNI_nonlin_field -r /usr/local/fsl/data/standard/MNI152_T1_2mm -o T1_to_MNI_nonlin --interp=spline

#### SKULL-CONSTRAINED BRAIN VOLUME ESTIMATION (only done if registration turned on, and segmentation done, and it is a T1 image)
# required inputs: ${T1}_biascorr
# output: ${T1}_vols.txt
/usr/local/fsl/bin/bet T1_biascorr T1_biascorr_bet -s -m -f 0.1
/usr/local/fsl/bin/pairreg /usr/local/fsl/data/standard/MNI152_T1_2mm_brain T1_biascorr_bet /usr/local/fsl/data/standard/MNI152_T1_2mm_skull T1_biascorr_bet_skull T12std_skullcon.mat

#### SUB-CORTICAL STRUCTURE SEGMENTATION
# required input: ${T1}_biascorr
# output: ${T1}_first*
/usr/local/fsl/bin/first_flirt T1_biascorr T1_biascorr_to_std_sub
mkdir first_results
/usr/local/fsl/bin/run_first_all  -i T1_biascorr -o first_results/T1_first -a T1_biascorr_to_std_sub.mat
/usr/local/fsl/bin/fsl_sub -T 1 -j 19638 imcp first_results/T1_first_all_fast_firstseg. T1_subcort_seg.

# CleanUps
/usr/local/fsl/bin/imrm T1_biascorr_bet_mask T1_biascorr_bet T1_biascorr_brain_mask2 T1_biascorr_init T1_biascorr_maskedbrain T1_biascorr_to_std_sub T1_fast_bias_idxmask T1_fast_bias_init T1_fast_bias_vol2 T1_fast_bias_vol32 T1_fast_totbias T1_hpf* T1_initfast2_brain.nii.gz T1_initfast2_brain_mask.nii.gz T1_initfast2_brain_mask2.nii.gz T1_initfast2_maskedrestore.nii.gz T1_initfast2_restore.nii.gz T1_s20 T1_initmask_s20
