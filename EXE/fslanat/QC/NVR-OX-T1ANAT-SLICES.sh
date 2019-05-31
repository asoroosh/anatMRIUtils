

StudyID=CFTY720D2201E2
ImageType="acq-3d"

AnatDir=" /data/output/habib/processed/${StudyID}/*/*/anat/*_${ImageType}_*.anat/


# T1 Raw

mkdir 
${AnatDir}/T1_orig.nii.gz

# T1 Crop and Re-orient
${AnatDir}/T1_fullfov.nii.gz

# T1 BET

# T1 Lin Reg
slicesdir -p ${FSLDIR}/data/standard/MNI152lin_T1_2mm_brain.nii.gz ${AnatDir}/T1_to_MNI_lin.nii.gz

# T1 nonLin Reg
slicesdir -p ${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz ${AnatDir}/T1_to_MNI_nonlin.nii.gz

# T1 FAST -- Segmentations:

# Each one seperately 
slicesdir -p T1_fast_pve_0.nii.gz ${AnatDir}/T1_fast_seg.nii.gz
slicesdir -p T1_fast_pve_1.nii.gz ${AnatDir}/T1_fast_seg.nii.gz
slicesdir -p T1_fast_pve_2.nii.gz ${AnatDir}/T1_fast_seg.nii.gz

