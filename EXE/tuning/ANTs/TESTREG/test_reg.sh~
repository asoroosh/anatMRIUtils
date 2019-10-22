MovingImage_tmp=/data/ms/processed/mri/CFTY720D2201.anon.2019.07.23/sub-CFTY720D2201.0063.00012/ses-V5/anat/sub-CFTY720D2201.0063.00012_ses-V5_run-1_T1w.ants/antsCorticalThickness/BrainExtractionBrain.nii.gz
FixedImage_MNI=/apps/software/fsl/data/standard/MNI152_T1_2mm_brain.nii.gz
cp $MovingImage_tmp .
MovingImage=BrainExtractionBrain.nii.gz

OutputPrefix=MNI

ml ANTs

antsRegistrationSyN.sh \
-d 3 \
-t s \
-f ${FixedImage_MNI} \
-m ${MovingImage} \
-o ${OutputPrefix}

antsApplyTransforms \
--dimensionality 3 \
--reference-image ${FixedImage_MNI} \
--input ${MovingImage} \
--transform ${OutputPrefix}1Warp.nii.gz \
--transform ${OutputPrefix}0GenericAffine.mat \
--output TEST_MNI_2mm.nii.gz \
--verbose 1
