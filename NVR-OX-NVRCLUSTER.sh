/apps/software/fsl/bin/fslmaths T1 T1_orig
/apps/software/fsl/bin/fslreorient2std T1
/apps/software/fsl/bin/convert_xfm -omat T1_std2orig.mat -inverse T1_orig2std.mat
/apps/software/fsl/bin/fslreorient2std T1 T1
/apps/software/fsl/bin/immv T1 T1_fullfov
/apps/software/fsl/bin/robustfov -i T1_fullfov -r T1 -m T1_roi2nonroi.mat
/apps/software/fsl/bin/convert_xfm -omat T1_nonroi2roi.mat -inverse T1_roi2nonroi.mat
/apps/software/fsl/bin/convert_xfm -omat T1_orig2roi.mat -concat T1_nonroi2roi.mat T1_orig2std.mat
/apps/software/fsl/bin/convert_xfm -omat T1_roi2orig.mat -inverse T1_orig2roi.mat
/apps/software/fsl/bin/bet T1 T1_initfast2_brain -m -f 0.1
/apps/software/fsl/bin/fslmaths T1_initfast2_brain T1_initfast2_restore
/apps/software/fsl/bin/fslmaths T1_initfast2_restore -mas lesionmaskinv T1_initfast2_maskedrestore
/apps/software/fsl/bin/fast -o T1_fast -l 20 -b -B -t 1 --iter=10 --nopve --fixed=0 -v T1_initfast2_maskedrestore
/apps/software/fsl/bin/fslmaths T1 -div T1_fast_restore -mas T1_initfast2_brain_mask T1_fast_totbias
/apps/software/fsl/bin/fslmaths T1_initfast2_brain_mask -ero -ero -ero -ero -mas lesionmaskinv T1_initfast2_brain_mask2
/apps/software/fsl/bin/fslmaths T1_fast_totbias -sub 1 T1_fast_totbias
/apps/software/fsl/bin/fslsmoothfill -i T1_fast_totbias -m T1_initfast2_brain_mask2 -o T1_fast_bias
/apps/software/fsl/bin/fslmaths T1_fast_bias -add 1 T1_fast_bias
/apps/software/fsl/bin/fslmaths T1_fast_totbias -add 1 T1_fast_totbias
/apps/software/fsl/bin/fslmaths T1 -div T1_fast_bias T1_biascorr
/apps/software/fsl/bin/flirt -interp spline -dof 12 -in T1_biascorr -ref /apps/software/fsl/data/standard/MNI152_T1_2mm -dof 12 -omat T1_to_MNI_lin.mat -out T1_to_MNI_lin
/apps/software/fsl/bin/fslmaths /apps/software/fsl/data/standard/MNI152_T1_2mm_brain_mask -fillh -dilF MNI152_T1_2mm_brain_mask_dil1
/apps/software/fsl/bin/fnirt --in=T1_biascorr --ref=/apps/software/fsl/data/standard/MNI152_T1_2mm --fout=T1_to_MNI_nonlin_field --jout=T1_to_MNI_nonlin_jac --iout=T1_to_MNI_nonlin --logout=T1_to_MNI_nonlin.txt --cout=T1_to_MNI_nonlin_coeff --config=/apps/software/fsl/etc/flirtsch/T1_2_MNI152_2mm.cnf --aff=T1_to_MNI_lin.mat --refmask=MNI152_T1_2mm_brain_mask_dil1
/apps/software/fsl/bin/invwarp --ref=T1_biascorr -w T1_to_MNI_nonlin_coeff -o MNI_to_T1_nonlin_field
/apps/software/fsl/bin/applywarp --interp=nn --in=/apps/software/fsl/data/standard/MNI152_T1_2mm_brain_mask --ref=T1_biascorr -w MNI_to_T1_nonlin_field -o T1_biascorr_brain_mask
/apps/software/fsl/bin/fslmaths T1_biascorr_brain_mask -fillh T1_biascorr_brain_mask
/apps/software/fsl/bin/fslmaths T1_biascorr -mas T1_biascorr_brain_mask T1_biascorr_brain
/apps/software/fsl/bin/fslmaths T1_biascorr_brain -mas lesionmaskinv T1_biascorr_maskedbrain
/apps/software/fsl/bin/fast -o T1_fast -l 20 -b -B -t 1 --iter=10 T1_biascorr_maskedbrain
/apps/software/fsl/bin/immv T1_biascorr T1_biascorr_init
/apps/software/fsl/bin/fslmaths T1_fast_restore T1_biascorr_brain
/apps/software/fsl/bin/fslmaths T1_biascorr_brain_mask -mas lesionmaskinv T1_biascorr_brain_mask2
/apps/software/fsl/bin/fslmaths T1_biascorr_init -div T1_fast_restore -mas T1_biascorr_brain_mask2 T1_fast_totbias
/apps/software/fsl/bin/fslmaths T1_fast_totbias -sub 1 T1_fast_totbias
/apps/software/fsl/bin/fslsmoothfill -i T1_fast_totbias -m T1_biascorr_brain_mask2 -o T1_fast_bias
/apps/software/fsl/bin/fslmaths T1_fast_bias -add 1 T1_fast_bias
/apps/software/fsl/bin/fslmaths T1_fast_totbias -add 1 T1_fast_totbias
/apps/software/fsl/bin/fslmaths T1_biascorr_init -div T1_fast_bias T1_biascorr
/apps/software/fsl/bin/applywarp -i T1_biascorr -w T1_to_MNI_nonlin_field -r /apps/software/fsl/data/standard/MNI152_T1_2mm -o T1_to_MNI_nonlin --interp=spline
/apps/software/fsl/bin/bet T1_biascorr T1_biascorr_bet -s -m -f 0.1
/apps/software/fsl/bin/pairreg /apps/software/fsl/data/standard/MNI152_T1_2mm_brain T1_biascorr_bet /apps/software/fsl/data/standard/MNI152_T1_2mm_skull T1_biascorr_bet_skull T12std_skullcon.mat
