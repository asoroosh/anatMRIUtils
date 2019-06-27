############################################################################################
#StudyID=CFTY720D2201E2
StudyID=$1

# One of the following: T13D T12D T22D PD2D
#ImgType=PD2D
ImgType=$2

# One the following: raw, fov, linreg, reg, seg
QCType=$3


RunID=1

clobber=no
############################################################################################

#Image Name
if [ $ImgType == T13D ] ; then
        #sub-2okKlAKGz7_ses-V1_M2_acq-3d_run-1_T1w.nii.gz
        ImageName=sub-*_ses-V*_M[0-9]_*_run-[0-9]_T1w
elif [ $ImgType == T12D ] ; then
        #sub-2okKlAKGz7_ses-V1_M2_run-1_T1w.nii.gz
        ImageName=sub-*_ses-V*_M[0-9]_run-[0-9]_T1w
elif [ $ImgType == PD2D ] ; then
        ImageName=*_*_run-*_PDT2_1
elif [ $ImgType == T22D ] ; then
        #sub-2okKlAKGz7_ses-V1_M2_run-1_PDT2_2.nii.gz
        ImageName=*_*_run-*_PDT2_2
else
        # throw an error and halt here
        echo "$ImgType is unrecognised"
fi

ImageSubName=""

if [ $QCType == raw ] ; then
	ImageSubName=T1_orig.nii.gz
elif [ $QCType == fov ] ; then
	ImageSubName=T1_fullfov.nii.gz
elif [ $QCType == linreg ] ; then
	SlicesDirArg="-p ${FSLDIR}/data/standard/MNI152lin_T1_2mm_brain.nii.gz"
	ImageSubName=T1_to_MNI_lin.nii.gz
elif [ $QCType == reg ] ; then
	SlicesDirArg="-p ${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz"
	ImageSubName=T1_to_MNI_nonlin.nii.gz
elif [ $QCType == seg ] ; then
	ImageSubName=T1_fast_seg.nii.gz
else
	echo "${QCType} is unrecognised"
fi

############################################################################################

QCDir=/data/output/habib/processed/${StudyID}/QC

AnatDir="/data/output/habib/processed/${StudyID}/*/*/anat/${ImageName}.anat/"

Where2DoTheJob=${QCDir}/QC_${ImgType}_${QCType}

echo "=========== ${QCType} Images ${ImgType} ==============="
echo "From: ${AnatDir}"
echo "To: ${Where2DoTheJob}"
echo "-------------------------------------------------------"

mkdir -p ${Where2DoTheJob}
# Okay! this looks shitty! But it is mainly because slicesdir was implemented in a reallysloppy way and takes time to implement parsing for it
cd ${Where2DoTheJob}

${FSLDIR}/bin/slicesdir ${SlicesDirArg} ${AnatDir}/${ImageSubName}

# T1 FAST -- Segmentations:
# Each one seperately
# slicesdir -p T1_fast_pve_0.nii.gz ${AnatDir}/T1_fast_seg.nii.gz
# slicesdir -p T1_fast_pve_1.nii.gz ${AnatDir}/T1_fast_seg.nii.gz
# slicesdir -p T1_fast_pve_2.nii.gz ${AnatDir}/T1_fast_seg.nii.gz
