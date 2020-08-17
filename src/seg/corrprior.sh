#!/bin/bash

set -e

ml ANTs

StudyID=$1
SubID=$2
SesID=$3

SEGOP=fast
REGOP=BETsREG
TissueType=(csf gray white)
pvetag=(0 1 2)

ProcessedDir=/XX/XX/XX/XX/
SEGDIR=${ProcessedDir}/${StudyID}/sub-${SubID}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_${SEGOP}_${REGOP}_brain_rawavg

#Image1=$1
#Image2=$2
#Mask=$3

pvetag=0
for tt in ${TissueType[@]}
do
	RAWAVGPVE=${SEGDIR}/sub-${SubID}_ses-${SesID}_${SEGOP}_${REGOP}_brain_rawavg_denoised_N4_pve_${pvetag}.nii.gz
	RAWAVGPRIORS=${SEGDIR}/tissuepriors_sst/sub-${SubID}_ses-${SesID}_avg152T1_${tt}_LIA_${REGOP}_rawavg.nii.gz
	RAWAVGMASK=

	RR=$(ImageMath 3 "" PearsonCorrelation $RAWAVGPVE $RAWAVGPRIORS $RAWAVGMASK)
	echo "${tt},${pvetag}: $RR"

	pvetag=$((pvetag+1))
done
