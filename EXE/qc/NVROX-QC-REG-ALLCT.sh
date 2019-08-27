#!/bin/bash
#SBATCH --partition=main
#SBATCH --mem=8GB
#SBATCH --time=05:00:00
#SBATCH --output=/home/bdivdi.local/dfgtyk/NVROXBOX/EXE/qc/logs/QC-HTM-GENERATE_%A_%a.out
#SBATCH --error=/home/bdivdi.local/dfgtyk/NVROXBOX/EXE/qc/logs/QC-HTM-GENERATE_%A_%a.err
#SBATCH --array=1-8

CleanCTs=${HOME}/NVROXBOX/EXE/getinfo/StudyIDs_Clean.txt
StudyID=$(cat ${CleanCTs} | sed -n ${SLURM_ARRAY_TASK_ID}p)

echo "+_+_+_+_+_+_+_+_+_+_+____ ${StudyID} ________+_+_+_+_+_"

sh NVROX-QC-REG.sh ${StudyID}
