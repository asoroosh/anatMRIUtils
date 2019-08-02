# Just a raw registration
# FixedImage_MNI_2mm=/apps/software/fsl/data/standard/MNI152_T1_2mm_brain.nii.gz
# FixedImage_MNI_1mm=/apps/software/fsl/data/standard/MNI152_T1_1mm_brain.nii.gz

ANTs_Dir=$1
OutputDir=$2
mkdir -p ${OutputDir}

OutputPrefix=MNI

ImageList=(BrainSegmentationResampled BrainExtractionBrain BrainSegmentation CorticalThickness)

for Res in 2
do
	for ImageName in ${ImageList[@]}
	do

		FixedImage_MNI=/apps/software/fsl/data/standard/MNI152_T1_${Res}mm_brain.nii.gz
		MovingImage=${ANTs_Dir}/antsCorticalThickness/${ImageName}.nii.gz

		echo "==== Moving Img: ${MovingImage} ===="
		echo "==== Ref Img: ${FixedImage_MNI} ===="

		######### 1mm & 2mm upsampling: ###############

		antsRegistrationSyN.sh \
		-d 3 \
		-t s \
		-f ${FixedImage_MNI} \
		-m ${MovingImage} \
		-o ${OutputDir}/${OutputPrefix}_${Res}mm_${ImageName}_

		######

		antsApplyTransforms \
		--dimensionality 3 \
		--reference-image ${FixedImage_MNI} \
		--input ${MovingImage} \
		--transform ${OutputDir}/${OutputPrefix}_${Res}mm_${ImageName}_1Warp.nii.gz \
		--transform ${OutputDir}/${OutputPrefix}_${Res}mm_${ImageName}_0GenericAffine.mat \
		--output ${OutputDir}/${ImageName}_MNI_${Res}mm.nii.gz \
		--verbose 1
	done
done


#	########## 1mm upsampling: ###############
#
#	antsRegistrationSyN.sh \
#	-d 3 \
#	-t s \
#	-f ${FixedImage_MNI_1mm} \
#	-m ${MovingImage} \
#	-o ${OutputDir}/${OutputPrefix}_111_
#
#	######
#
#	antsApplyTransforms \
#	--dimensionality 3 \
#	--reference-image ${FixedImage_MNI_1mm} \
#	--input ${MovingImage} \
#	--transform ${OutputDir}/${OutputPrefix}_111_1Warp.nii.gz \
#	--transform ${OutputDir}/${OutputPrefix}_111_0GenericAffine.mat \
#	--output ${OutputDir}/${ImageName}_MNI_111.nii.gz \
#	--verbose 1
#
#	rm ${OutputDir}/${OutputPrefix}_111_1Warp.nii.gz ${OutputDir}/${OutputPrefix}_222_1Warp.nii.gz
#	rm ${OutputDir}/${OutputPrefix}_111_0GenericAffine.mat ${OutputDir}/${OutputPrefix}_222_0GenericAffine.mat
#done
