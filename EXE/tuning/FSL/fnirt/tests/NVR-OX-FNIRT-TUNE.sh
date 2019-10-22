InputImageName=T1_biascorr
DirSuffix=fslanat

FNIRT_TXTFILECORRATIO="/home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FSL/fnirt/tests/T1-2-MNI-FNIRT-CORRATIO.txt"
rm -rf ${FNIRT_TXTFILECORRATIO}

FLIRT_TXTFILECORRATIO="/home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FSL/fnirt/tests/T1-2-MNI-FLIRT-CORRATIO.txt"
rm -rf ${FLIRT_TXTFILECORRATIO}

STANDARDDIR=$FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz

for SubIDX in 1 #$(seq 1 15)
do
	echo $SubIDX

	SubSesID=$(sed "${SubIDX}q;d" failed_fnirt_studyid.txt)

	echo $SubSesID

	StudyID_Date=$(echo $SubSesID | awk -F"_" '{print $1}')
	SubID=$(echo $SubSesID | awk -F"_" '{print $2}')
	SesID=$(echo $SubSesID | awk -F"_" '{print $3}')

#	StudyID=$(echo $SubID | awk -F"-" '{print $2}' | awk -F"." '{print $1}')
#	StudyID_Date=$(ls /data/ms/unprocessed/mri/ | grep "${StudyID}.anon") #because the damn Study names has inconsistant dates in them!

	StudyID=$(echo $StudyID_Date | awk -F"." '{print $1}')

	echo "===REPORT===="
	echo $SubID
	echo $SesID
	echo $StudyID
	echo $StudyID_Date
	echo "============="
	RawInputImage=/data/ms/unprocessed/mri/${StudyID_Date}/${SubID}/${SesID}/anat/${SubID}_${SesID}_run-1_T1w.nii.gz
#	echo $RawInputImage

	RawInputImageName=$(basename ${RawInputImage} .nii.gz)

	InputImage=/data/ms/processed/mri/${StudyID_Date}/${SubID}/${SesID}/anat/${RawInputImageName}.${DirSuffix}/${RawInputImageName}.anat/${InputImageName}.nii.gz
	OutputDir=/home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FSL/fnirt/tests/out_fnirt/${RawInputImageName}_${InputImageName}

	mkdir -p ${OutputDir}

	cp ${InputImage} ${OutputDir}
	cp ${RawInputImage} ${OutputDir}

######################### Images
	slicesImageDir=/data/ms/processed/mri/QC/${StudyID}/fslanat_T1_to_MNI_lin-T1_to_MNI_nonlin/TRI
	cp ${slicesImageDir}/TRI_${SubID}_${SesID}_T1_to_MNI_lin-T1_to_MNI_nonlin.png ${OutputDir}

#	OutputImage=${OutputDir}/${InputImageName}_fnirt2MNI2mm_${}.nii.gz
	echo "Inputimage: $InputImage"
	echo "Outputimage: $OutputDir "


######################### FLIRT
	echo "-----FLIRT------------"

	#if I had a lesion mask add this to the flirt args: "$-inweight lesionmaskinv"

	FLIRTSuffix="FLIRT-DOF12-3D"

	$FSLDIR/bin/flirt \
	-interp spline \
	-dof 12 \
	-in $InputImage \
	-ref $FSLDIR/data/standard/MNI152_T1_2mm \
	-omat ${OutputDir}/T1_to_MNI_lin_${FLIRTSuffix}.mat \
	-out ${OutputDir}/T1_to_MNI_lin_${FLIRTSuffix}

	CORRATIO_FLIRT=$(sh /home/bdivdi.local/dfgtyk/NVROXBOX/SOURCE/NVR-OX-IMGSIM.sh "${OutputDir}/T1_to_MNI_lin_${FLIRTSuffix}.nii.gz" "${STANDARDDIR}")
	echo $CORRATIO_FLIRT
	echo "${SubID},${SesID}: ${CORRATIO_FLIRT}" >> ${FLIRT_TXTFILECORRATIO}

##### TAKE A PIC
STANDARDDIR=$FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz
OUTPUTpngIMAGE=${OutputDir}
IMAGE_FLIRT_WC=${OutputDir}/T1_to_MNI_lin_${FLIRTSuffix}.nii.gz
sh /home/bdivdi.local/dfgtyk/NVROXBOX/SOURCE/NVR-OX-slicer-overlay.sh "${IMAGE_FLIRT_WC}" "$STANDARDDIR" "$OUTPUTpngIMAGE" 1

sh /home/bdivdi.local/dfgtyk/NVROXBOX/SOURCE/NVR-OX-slicer.sh  "${InputImage}" "${OutputDir}" 1

sh /home/bdivdi.local/dfgtyk/NVROXBOX/SOURCE/NVR-OX-slicer.sh "${RawInputImage}" "${OutputDir}" 1

####################### FNIRT
	echo "-----FNIRT-----------"

	#Reference Mask -- later replace with lesionmask
	refmask=${OutputDir}/MNI152_T1_2mm_brain_mask_dil1
	$FSLDIR/bin/fslmaths $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask -fillh -dilF $refmask

	FNIRTSuffix="${FLIRTSuffix}_FNIRT-FNIRTCHECK_infwhm4322-lambda3001005030-sbsmpl1111-nomask_T1_2_MNI152_2mm-cnf"

#--config=$FSLDIR/etc/flirtsch/T1_2_MNI152_2mm.cnf \

	$FSLDIR/bin/fnirt \
	--in=$InputImage \
	--ref=$FSLDIR/data/standard/MNI152_T1_2mm \
	--fout=${OutputDir}/T1_to_MNI_nonlin_${FNIRTSuffix}_field \
	--jout=${OutputDir}/T1_to_MNI_nonlin_${FNIRTSuffix}_jac \
	--iout=${OutputDir}/T1_to_MNI_nonlin_${FNIRTSuffix} \
	--logout=${OutputDir}/T1_to_MNI_nonlin_${FNIRTSuffix}.txt \
	--cout=${OutputDir}/T1_to_MNI_nonlin_${FNIRTSuffix}_coeff \
	--aff=${OutputDir}/T1_to_MNI_lin_${FLIRTSuffix}.mat \
	--refmask=$refmask \
	--config=FNIRTCHECK_infwhm4322-lambda3001005030-sbsmpl1111-nomask_T1_2_MNI152_2mm.cnf
#	--miter=10,10,10,10,10 \
#	--subsamp=2,1,1,1,1 \
#	--lambda=100,75,50,20,10 \

	CORRATIO_FNIRT=$(sh /home/bdivdi.local/dfgtyk/NVROXBOX/SOURCE/NVR-OX-IMGSIM.sh "${OutputDir}/T1_to_MNI_nonlin_${FNIRTSuffix}.nii.gz" "${STANDARDDIR}")
	echo "${SubID},${SesID}: ${CORRATIO_FNIRT}" >> ${FNIRT_TXTFILECORRATIO}

##### TAKE A PIC
IMAGE_FNIRT_WC=${OutputDir}/T1_to_MNI_nonlin_${FNIRTSuffix}.nii.gz
sh /home/bdivdi.local/dfgtyk/NVROXBOX/SOURCE/NVR-OX-slicer-overlay.sh "${IMAGE_FNIRT_WC}" "$STANDARDDIR" "$OUTPUTpngIMAGE" 1

done
