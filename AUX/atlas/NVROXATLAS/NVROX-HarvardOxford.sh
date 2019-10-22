
MaskName=MNI152_T1_2mm_brain_mask

AtlasDir=/apps/software/fsl/data/atlases
MNIBrainMask=/apps/software/fsl/data/standard/${MaskName}.nii.gz
HOX_Atlas=${AtlasDir}/HarvardOxford/HarvardOxford-cort-maxprob-thr25-2mm.nii.gz
MNI_Atlas=${AtlasDir}/MNI/MNI-maxprob-thr0-2mm.nii.gz

# split the hemispheres
fslroi ${MNIBrainMask} ${MaskName}_LH.nii.gz 0 45 0 -1 0 -1
fslroi ${MNIBrainMask} ${MaskName}_RH.nii.gz 46 90 0 -1 0 -1

# mask the atlas

# multiply by some number / sum by the max of the one hemisphere

# put them back together

