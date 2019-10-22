

#---------------------------------
# New invocation of recon-all Wed Sep 18 09:46:42 UTC 2019 

 mv -f /home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/autorecon12ws/test_autorecon12ws/autorecon12ws_rng/sub-CFTY720D2309.0102.00009_ses-V8_run-1_T1w/sub-CFTY720D2309.0102.00009_ses-V8_run-1_T1w/mri/optimal_preflood_height /home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/autorecon12ws/test_autorecon12ws/autorecon12ws_rng/sub-CFTY720D2309.0102.00009_ses-V8_run-1_T1w/sub-CFTY720D2309.0102.00009_ses-V8_run-1_T1w/trash 


 mv -f /home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/autorecon12ws/test_autorecon12ws/autorecon12ws_rng/sub-CFTY720D2309.0102.00009_ses-V8_run-1_T1w/sub-CFTY720D2309.0102.00009_ses-V8_run-1_T1w/mri/optimal_skullstrip_invol /home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/autorecon12ws/test_autorecon12ws/autorecon12ws_rng/sub-CFTY720D2309.0102.00009_ses-V8_run-1_T1w/sub-CFTY720D2309.0102.00009_ses-V8_run-1_T1w/trash 


 mri_convert /data/ms/unprocessed/mri/CFTY720D2309.anon.2019.07.15/sub-CFTY720D2309.0102.00009/ses-V8/anat/sub-CFTY720D2309.0102.00009_ses-V8_run-1_T1w.nii.gz /home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/autorecon12ws/test_autorecon12ws/autorecon12ws_rng/sub-CFTY720D2309.0102.00009_ses-V8_run-1_T1w/sub-CFTY720D2309.0102.00009_ses-V8_run-1_T1w/mri/orig/001.mgz 

#--------------------------------------------
#@# Skull Stripping Wed Sep 18 09:46:44 UTC 2019

 mri_em_register -rusage /home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/autorecon12ws/test_autorecon12ws/autorecon12ws_rng/sub-CFTY720D2309.0102.00009_ses-V8_run-1_T1w/sub-CFTY720D2309.0102.00009_ses-V8_run-1_T1w/touch/rusage.mri_em_register.skull.dat -skull nu.mgz /apps/eb/software/FreeSurfer/6.0.1-centos6_x86_64/average/RB_all_withskull_2016-05-10.vc700.gca transforms/talairach_with_skull.lta 

