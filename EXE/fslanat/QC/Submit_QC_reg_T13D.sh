#!/bin/bash
#SBATCH --partition=main
#SBATCH --job-name=QC_reg_T13D
#SBATCH --mem=5G
#SBATCH --time=20:00
#SBATCH --output=/home/bdivdi.local/dfgtyk/NVROXBOX/EXE/fslanat/QC/logs/QC_reg_T13D.out
#SBATCH --error=/home/bdivdi.local/dfgtyk/NVROXBOX/EXE/fslanat/QC/logs/QC_reg_T13D.err

## Code goes here ## ## ##

sh /home/bdivdi.local/dfgtyk/NVROXBOX/EXE/fslanat/QC/NVR-OX-SLICESDIR-QC.sh CFTY720D2201E2 T13D reg

## ## ## ## ## ## ## ## ## ## ## ##
