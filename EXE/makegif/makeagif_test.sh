NonLinTempImg=sub-CFTY720D2324.0217.00001_ants_temp_med_nutemplate0

InputDir=/data/ms/processed/mri/CFTY720D2324.anon.2019.07.15/sub-CFTY720D2324.0217.00001/T12D.autorecon12ws.nuws_mrirobusttemplate
NonLinTempDirImg=${InputDir}/${NonLinTempImg}.nii.gz

BETOutput=/home/bdivdi.local/dfgtyk/NVROXBOX/EXE/brainmasks/brainimg/
BETOutputDirImg=${BETOutput}/${NonLinTempImg}_brain.nii.gz


# BET
#echo "Run BET:"
#echo "Input: ${NonLinTempDirImg}"
#echo "Output: ${BETOutputDirImg}"
#${FSLDIR}/bin/bet ${NonLinTempDirImg} ${BETOutputDirImg} -R -f 0.25

ml FreeSurfer
ml Perl
source /apps/eb/software/FreeSurfer/6.0.1-centos6_x86_64/FreeSurferEnv.sh

SesIDList=(V2 V3 V4 V5)

for SesID in V2 V3 V4 V5
do
	echo ${SesID}

	MGZ_FileName=${InputDir}/sub-CFTY720D2324.0217.00001_ses-${SesID}_nu_2_median_nu.nii.gz
	NII_FileName=/home/bdivdi.local/dfgtyk/NVROXBOX/EXE/makegif/nii/sub-CFTY720D2324.0217.00001_ses-${SesID}_nu_2_median_nu_RAS.nii.gz

#	mri_convert --in_type mgz --out_type nii --out_orientation RAS ${MGZ_FileName} ${NII_FileName}
	fslreorient2std ${MGZ_FileName} ${NII_FileName}

	slices ${NII_FileName} -o ${SesID}.png
done

ml ImageMagick
convert -delay 20 -loop 0 V*.png sub-CFTY720D2324.0217.00001_median.gif

#whirlgif

