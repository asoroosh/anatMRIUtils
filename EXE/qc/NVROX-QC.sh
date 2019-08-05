
QC_Results=/data/output/habib/processed/CFTY720D2201E2/QC

StudyID=CFTY720D2201E2
ProcessedPath="/data/output/habib/processed/${StudyID}"

######################### FSL
for ImageName in T1_to_MNI_nonlin T1_to_MNI_lin
do

	TargetDir=${QC_Results}/FSL_${ImageName}
	mkdir -p ${TargetDir}
	cd ${TargetDir}

	T12D_Dir=${ProcessedPath}/sub-*/ses-V*[0-9]_M*[0-9]/anat/sub-*_ses-V*[0-9]_M*[0-9]_run-1_T1w.anat/${ImageName}.nii.gz
#	T13D_Dir=${ProcessedPath}/sub-*/ses-V*[0-9]_M*[0-9]/anat/sub-*_ses-V*[0-9]_M*[0-9]_acq-3d_run-1_T1w.anat/${ImageName}.nii.gz

	slicesdir -p ${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz ${T12D_Dir}
#	slicesdir -p ${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz ${T13D_Dir}
done

TargetDir=${QC_Results}/FSL_T1_biascorr_brain
mkdir -p ${TargetDir}
cd ${TargetDir}

T12D_Dir=${ProcessedPath}/sub-*/ses-V*[0-9]_M*[0-9]/anat/sub-*_ses-V*[0-9]_M*[0-9]_run-1_T1w.anat/T1_biascorr_brain.nii.gz
#T13D_Dir=${ProcessedPath}/sub-*/ses-V*[0-9]_M*[0-9]/anat/sub-*_ses-V*[0-9]_M*[0-9]_acq-3d_run-1_T1w.anat/T1_biascorr_brain.nii.gz

slicesdir ${T12D_Dir}
#slicesdir ${T13D_Dir}

######################### ANTs

# Nonlinear Registration

TargetDir=${QC_Results}/ANTs_BrainExtractionBrain_MNI_2mm
mkdir -p ${TargetDir}
cd ${TargetDir}

T12D_Dir=${ProcessedPath}/sub-*/ses-V*[0-9]_M*[0-9]/anat/sub-*_ses-V*[0-9]_M*[0-9]_run-1_T1w.ANTs/MNI/BrainExtractionBrain_MNI_2mm.nii.gz
#T13D=${ProcessedPath}/${StudyID}/sub-*/ses-V*[0-9]_M*[0-9]/anat/sub-*_ses-V*[0-9]_M*[0-9]_acq-3d_run-1_T1w.ANTs/MNI/BrainExtractionBrain_MNI_2mm.nii.gz

slicesdir -p ${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz ${T12D_Dir}
#slicesdir -p ${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz ${T13D_Dir}

######################### CAT12


######################### FS
T12D_Dir=${ProcessedPath}/sub-*/ses-V*[0-9]_M*[0-9]/anat/sub-*_ses-V*[0-9]_M*[0-9]_run-1_T1w.AUTORECON12/sub-*_ses-V*[0-9]_M*[0-9]_run-1_T1w.AUTORECON12/mri/nii/norm_RAS.nii.gz

TargetDir=${QC_Results}/FS_norm_RAS
mkdir -p ${TargetDir}
cd ${TargetDir}

slicesdir ${T12D_Dir}
