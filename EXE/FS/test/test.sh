#!/bin/bash
#SBATCH --partition=main
#SBATCH --job-name=FS_test
#SBATCH --mem=8G
#SBATCH --time=20:00
#SBATCH --output=/home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/test/test.out
#SBATCH --error=/home/bdivdi.local/dfgtyk/NVROXBOX/EXE/FS/test/test.err
#SBATCH --array=1-1

ImgName=sub-CFTY720D2201.0063.00012_ses-V10_run-1_T1w
DirSuffix=autorecon12
InputDir=/data/ms/unprocessed/mri/CFTY720D2201.anon.2019.07.23/sub-CFTY720D2201.0063.00012/ses-V10/anat/sub-CFTY720D2201.0063.00012_ses-V10_run-1_T1w.nii.gz
OutputDir=/data/ms/processed/mri/CFTY720D2201.anon.2019.07.23/sub-CFTY720D2201.0063.00012/ses-V10/anat/sub-CFTY720D2201.0063.00012_ses-V10_run-1_T1w.autorecon12

rm -r $OutputDir

mkdir -p $OutputDir

set -e

ml FreeSurfer
ml Perl
source /apps/eb/software/FreeSurfer/6.0.1-centos6_x86_64/FreeSurferEnv.sh

### ### ### ### ### ###
# And now the operations
# Load packages and software here
recon-all \
-subjid ${ImgName} \
-i ${InputDir} \
-sd ${OutputDir} \
-autorecon1 \
-subcortseg \
-gcareg \
-canorm
