

#---------------------------------
# New invocation of recon-all Tue Sep  3 10:00:35 UTC 2019 

 mri_convert /home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/autorecon12ws/test_autorecon12ws/sub-CFTY720D2309.0102.00004_ses-V777_run-1_T1w.nii.gz /home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/autorecon12ws/test_autorecon12ws/autorecon12/sub-CFTY720D2309.0102.00004_ses-V777_run-1_T1w/mri/orig/001.mgz 

#--------------------------------------------
#@# MotionCor Tue Sep  3 10:00:37 UTC 2019

 cp /home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/autorecon12ws/test_autorecon12ws/autorecon12/sub-CFTY720D2309.0102.00004_ses-V777_run-1_T1w/mri/orig/001.mgz /home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/autorecon12ws/test_autorecon12ws/autorecon12/sub-CFTY720D2309.0102.00004_ses-V777_run-1_T1w/mri/rawavg.mgz 


 mri_convert /home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/autorecon12ws/test_autorecon12ws/autorecon12/sub-CFTY720D2309.0102.00004_ses-V777_run-1_T1w/mri/rawavg.mgz /home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/autorecon12ws/test_autorecon12ws/autorecon12/sub-CFTY720D2309.0102.00004_ses-V777_run-1_T1w/mri/orig.mgz --conform 


 mri_add_xform_to_header -c /home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/autorecon12ws/test_autorecon12ws/autorecon12/sub-CFTY720D2309.0102.00004_ses-V777_run-1_T1w/mri/transforms/talairach.xfm /home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/autorecon12ws/test_autorecon12ws/autorecon12/sub-CFTY720D2309.0102.00004_ses-V777_run-1_T1w/mri/orig.mgz /home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/autorecon12ws/test_autorecon12ws/autorecon12/sub-CFTY720D2309.0102.00004_ses-V777_run-1_T1w/mri/orig.mgz 

#--------------------------------------------
#@# Talairach Tue Sep  3 10:00:43 UTC 2019

 mri_nu_correct.mni --no-rescale --i orig.mgz --o orig_nu.mgz --n 1 --proto-iters 1000 --distance 50 


 talairach_avi --i orig_nu.mgz --xfm transforms/talairach.auto.xfm 

talairach_avi log file is transforms/talairach_avi.log...

 cp transforms/talairach.auto.xfm transforms/talairach.xfm 

#--------------------------------------------
#@# Talairach Failure Detection Tue Sep  3 10:02:06 UTC 2019

 talairach_afd -T 0.005 -xfm transforms/talairach.xfm 


 awk -f /apps/eb/software/FreeSurfer/6.0.1-centos6_x86_64/bin/extract_talairach_avi_QA.awk /home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/autorecon12ws/test_autorecon12ws/autorecon12/sub-CFTY720D2309.0102.00004_ses-V777_run-1_T1w/mri/transforms/talairach_avi.log 


 tal_QC_AZS /home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/autorecon12ws/test_autorecon12ws/autorecon12/sub-CFTY720D2309.0102.00004_ses-V777_run-1_T1w/mri/transforms/talairach_avi.log 

#--------------------------------------------
#@# Nu Intensity Correction Tue Sep  3 10:02:06 UTC 2019

 mri_nu_correct.mni --i orig.mgz --o nu.mgz --uchar transforms/talairach.xfm --n 2 


 mri_add_xform_to_header -c /home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/autorecon12ws/test_autorecon12ws/autorecon12/sub-CFTY720D2309.0102.00004_ses-V777_run-1_T1w/mri/transforms/talairach.xfm nu.mgz nu.mgz 

#--------------------------------------------
#@# Intensity Normalization Tue Sep  3 10:03:34 UTC 2019

 mri_normalize -g 1 -mprage nu.mgz T1.mgz 

#--------------------------------------------
#@# Skull Stripping Tue Sep  3 10:04:54 UTC 2019

 mri_em_register -rusage /home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/autorecon12ws/test_autorecon12ws/autorecon12/sub-CFTY720D2309.0102.00004_ses-V777_run-1_T1w/touch/rusage.mri_em_register.skull.dat -skull nu.mgz /apps/eb/software/FreeSurfer/6.0.1-centos6_x86_64/average/RB_all_withskull_2016-05-10.vc700.gca transforms/talairach_with_skull.lta 


 mri_watershed -rusage /home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/autorecon12ws/test_autorecon12ws/autorecon12/sub-CFTY720D2309.0102.00004_ses-V777_run-1_T1w/touch/rusage.mri_watershed.dat -T1 -brain_atlas /apps/eb/software/FreeSurfer/6.0.1-centos6_x86_64/average/RB_all_withskull_2016-05-10.vc700.gca transforms/talairach_with_skull.lta T1.mgz brainmask.auto.mgz 


 cp brainmask.auto.mgz brainmask.mgz 

