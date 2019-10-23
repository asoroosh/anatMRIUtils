

# Prepare the data
#cd /home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/autorecon12ws/test_autorecon12ws
#MovingImage_tmp=/data/ms/unprocessed/mri/CFTY720D2309.anon.2019.07.15/sub-CFTY720D2309.0102.00004/ses-V777/anat/sub-CFTY720D2309.0102.00004_ses-V777_run-1_T1w.nii.gz
#CWD=/home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/autorecon12ws/test_autorecon12ws
#copy the image here, just to be safe
#cp $MovingImage_tmp $CWD
#address to the psudo code
#InputImagePath=$CWD/sub-CFTY720D2309.0102.00004_ses-V777_run-1_T1w.nii.gz

InputImagePath=$1

# source freesurfer
ml FreeSurfer
ml Perl
source /apps/eb/software/FreeSurfer/6.0.1-centos6_x86_64/FreeSurferEnv.sh

ImgName=$(basename $InputImagePath .nii.gz)

#Make an output directory
CWD=/home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/autorecon12ws/test_autorecon12ws
OutputDir=$CWD/autorecon12/$ImgName
rm -rf $OutputDir
mkdir -p $OutputDir

echo "========"
echo "*InputDir: $InputImagePath"
echo "*OutputDir: $OutputDir"
echo "*ImageName: $ImgName"
echo "========"

# Call freesurfer:

#----------- LOOSE WATERSHED -------
recon-all \
-subjid ${ImgName} \
-i ${InputImagePath} \
-sd ${OutputDir} \
-autorecon1 \

#-wsmore \
#-subcortseg \
#-gcareg \
#-canorm


#----------- DEFAULT ---------------
#OutputDir=$CWD/autorecon12
#rm -rf $OutputDir
#mkdir -p $OutputDir

#recon-all \
#-subjid ${ImgName} \
#-i ${InputImagePath} \
#-sd ${OutputDir} \
#-autorecon1 \
