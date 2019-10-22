ml ANTs

VoxRes=2

SubID=sub-CFTY720D2324.0217.00001
NonLinTempImg=${SubID}_ants_temp_med_nutemplate0

CWDD=/home/bdivdi.local/dfgtyk/NVROXBOX/EXE/brainmasks
NonLinTempl=${CWDD}/brainimg/T12D.autorecon12ws.nuws_mrirobusttemplate/${NonLinTempImg}

# Get the MNI template from LAS (MNI/FSL orientation) to RAS (FreeSurfer orientation)
MNI=$FSLDIR/data/standard/MNI152_T1_${VoxRes}mm
MNI_FS=${CWDD}/brainimg/MNI152_T1_${VoxRes}mm_FS
mri_convert --in_orientation LAS --out_orientation RAS ${MNI}.nii.gz ${MNI_FS}.nii.gz

NonLinTempl_mni=${CWDD}/brainimg/T12D.autorecon12ws.nuws_mrirobusttemplate/${NonLinTempImg}_MNI-${VoxRes}mm

NonLinTempl_mask=${CWDD}/brainimg/T12D.autorecon12ws.nuws_mrirobusttemplate/${NonLinTempImg}_mask.nii.gz
fslmaths ${NonLinTempl}.nii.gz -bin ${NonLinTempl_mask}.nii.gz
fslmaths ${NonLinTempl_mask}.nii.gz -dilM ${NonLinTempl_mask}.nii.gz

antsRegistrationSyNQuick.sh -d 3 \
-f ${MNI_FS}.nii.gz \
-m ${NonLinTempl}.nii.gz \
-t s \
-x ${NonLinTempl_mask}.nii.gz \
-o ${NonLinTempl_mni}_test
