#!/bin/bash
#SBATCH --partition=main
#SBATCH --job-name=antsSST
#SBATCH --mem=8GB
#SBATCH --time=6-23:59:00
#SBATCH --output=/home/bdivdi.local/dfgtyk/NVROXBOX/EXE/subtemplates/subsamplingtests/logs/antsSST_60x20x10x2_%A_%a.out
#SBATCH --error=/home/bdivdi.local/dfgtyk/NVROXBOX/EXE/subtemplates/subsamplingtests/logs/antsSST_60x20x10x2_%A_%a.err
#SBATCH --array=1-6

ml ANTs

qstring=60x20x10x2

ImgIDX=$SLURM_ARRAY_TASK_ID
SubID=$(cat somesubj.txt | sed -n ${ImgIDX}p)
StudyID=$(echo $SubID | awk -F"-" '{print $2}' | awk -F"." '{print $1}')

ProcessedDir=/data/ms/processed/mri/
StudyID_Date=$(ls ${ProcessedDir} | grep "${StudyID}.anon.2019.07")

ProcessedDir=/data/ms/processed/mri/${StudyID_Date}

SSTDir=${ProcessedDir}/${SubID}/T12D.autorecon12ws.nuws_mrirobusttemplate/

mkdir -p ${SSTDir}/${qstring}

nu_template_pathname=${ProcessedDir}/${SubID}_norm_nu_median.nii.gz

antsMultivariateTemplateConstruction2.sh \
-d 3 \
-f 8x4x2x1 \
-s 3x2x1x0vox \
-q ${qstring} \
-l 1  \
-t SyN \
-m CC[4] \
-c 0 \
-a 2 \
-z ${nu_template_pathname} \
-o ${SSTDir}/${qstring}/${SubID}_ants_temp_med_nu \
${SSTDir}/${SubID}_*_nu_2_median_nu.nii.gz

