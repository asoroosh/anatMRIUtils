# Attemps to register PVE files into the MNI space
# just for the sake of comparison across subject
# T1_fast_pve_*.nii.gz

PVEImgDir=$1
PVE_MNI_ImgDir=${PVEImgDir}/pve_MNI

mkdir -p $PVE_MNI_ImgDir

for pvecnt in 0 1 2
do
	echo "Now on PVE: $pvecnt"
	date
	echo "RUNING APPLYWARP NOW..."

	applywarp \
	-i ${PVEImgDir}/T1_fast_pve_${pvecnt}.nii.gz \
	-o ${PVE_MNI_ImgDir}/T1_fast_pve${pvecnt}_to_MNI_nonlin.nii.gz \
	-r ${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz \
	-w ${PVEImgDir}/T1_to_MNI_nonlin_field.nii.gz
done

#	flirt \
#	-interp spline \
#	-dof 12 \
#	-in ${PVEImgDir}/T1_fast_pve_${pvecnt}.nii.gz  \
#	-ref $FSLDIR/data/standard/MNI152_T1_2mm \
#	-dof 12 \
#	-omat ${PVE_MNI_ImgDir}/T1_fast_pve${pvecnt}_to_MNI_lin.mat \
#	-out ${PVE_MNI_ImgDir}/T1_fast_pve${pvecnt}_to_MNI_lin

#	date
#	echo "RUNING FNIRT NOW..."

#	fnirt \
#	--in=${PVEImgDir}/T1_fast_pve_${pvecnt}.nii.gz \
#	--ref=$FSLDIR/data/standard/MNI152_T1_2mm \
#	--fout=${PVE_MNI_ImgDir}/T1_fast_pve${pvecnt}_to_MNI_nonlin_field \
#	--iout=${PVE_MNI_ImgDir}/T1_fast_pve${pvecnt}_to_MNI_nonlin \
#	--logout=${PVE_MNI_ImgDir}/T1_fast_pve${pvecnt}_to_MNI_nonlin.txt \
#	--cout=${PVE_MNI_ImgDir}/T1_fast_pve${pvecnt}_to_MNI_nonlin_coeff \
#	--config=$FSLDIR/etc/flirtsch/T1_2_MNI152_2mm.cnf \
#	--aff=${PVE_MNI_ImgDir}/T1_fast_pve${pvecnt}_to_MNI_lin.mat \
	#--refmask=$refmask 
