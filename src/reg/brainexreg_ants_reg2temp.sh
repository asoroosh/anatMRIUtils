#!/bin/bash

#
# Soroosh Afyouni, University of Oxford, 2020
#
#Copyright (c) 2020
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

source ${HOME}/NVROXBOX/AUX/Config/XXX

echo "===================="
echo "Paths imported:"
echo "processed: $PRSD_DIR"
echo "unprocessed: $UPRSD_DIR"
echo "home: $MyHOME"
echo "datadir: $DataDir"
echo "===================="

set -e

do_reg=1

#--------- SubID, StudyID, info from ANTs SST -----------------------------------------
StudyID=$1
SubID=$2

OrFlag=LIA
BETREGOP="antsstudtemp"
ImgTyp=T12D
XSectionalDirSuffix=autorecon12ws
LogitudinalDirSuffix=nuws_mrirobusttemplate
VoxRes=2
MaskThr=0.5
#--------------------------------------------------------------------------------------
echo "======================================="
echo "STARTED @" $(date)
echo "======================================="
echo ""
echo "======================================="
echo "======================================="
echo "** StudyID: ${StudyID}, SubID: ${SubID}"
echo "======================================="
echo "======================================="

#SessionsFileName=${DataDir}/${StudyID}/T12D/Sessions/${StudyID}_sub-${SubID}_T12D.txt
#cat $SessionsFileName
#AA=$(echo "${UnprocessedPath}" | awk -F"/" '{print NF-1}');
#while read SessionPathsFiles
#do
#	ses_SesID_tmp=$(echo $SessionPathsFiles | awk -F"/" -v xx=$((AA+3)) '{print $xx}')
#	SesID_tmp=$(echo $ses_SesID_tmp | awk -F"-" '{print $2}');
#	SesIDList="${SesIDList} $SesID_tmp"
#	echo ${SesIDList}
#done<${SessionsFileName}
#SesIDList=(${SesIDList})
#NumSes=${#SesIDList[@]}

SUBSESTABLE=${DataDir}/${StudyID}/${ImageType}/${StudyID}_${ImageType}_ImageSubSesID.table
SesIDList=($(sh ${SOURCEPATH}/mis/getmesesids.sh ${StudyID} ${SubID} ${SUBSESTABLE} | sed -n '1p'))
NumSes=$(sh ${SOURCEPATH}/mis/getmesesids.sh ${StudyID} ${SubID} ${SUBSESTABLE} | sed -n '5p')

echo "Session List: ${SesIDList[@]}"
echo "NUMBER OF SESSIONS: ${NumSes}"

#--------------------------------------------------------------------------------------
PRSD_SUBDIR=${PRSD_DIR}/${StudyID}/sub-${SubID}

#-------------= X Sectional paths
SST_Dir=${PRSD_SUBDIR}/${ImgTyp}.${XSectionalDirSuffix}.${LogitudinalDirSuffix}
#--------------= Unprocessed paths
UnprocessedDir=${UPRSD_DIR}/${StudyID}

#--------------= Study specific template
#StudyTemplateDir=${PRSD_DIR}/TEMPLATES/${StudyID}/${StudyID}_50_RNDSST
StudyTemplateDir=${STUDTEMPDIR}/${StudyID}_50_RNDSST
StudyTemplateImg=${StudyTemplateDir}/${StudyID}template
StudyTemplateBrainMask=${StudyTemplateDir}/antscorticalthickness/BrainExtractionMask

#--------------= Path to SST templates =-----------------------------------------------
# Nonlinear Template
NonLinTempImgName=sub-${SubID}_ants_temp_med_nutemplate0
NonLinSSTDirImg=${SST_Dir}/${NonLinTempImgName}
# Linear Template
LinSST=${SST_Dir}/sub-${SubID}_norm_nu_median.nii.gz # this should be moved

# ------- Path inistialisations --------------------------------------------------------

if [ $do_reg == 1 ] || [ $do_reg == 10 ]; then
		echo "TEST"
	else
		echo "############# No Registration will be done..."
fi

# ------- Do the job ---------------------------------------------------------------------

## REGISTRATION ######

mkdir -p ${SST_Dir}/${BETREGOP}
if [ $do_reg == 1 ]; then
	sh ${SOURCEREG}/reg2temp/reg2temp.sh ${NonLinSSTDirImg}.nii.gz ${StudyTemplateImg}.nii.gz
else
	echo "############# No Registration will be done..."
fi

TEMP2SSTWARP=${SST_Dir}/reg2temp/${NonLinTempImgName}_reg2temp_1Warp
TEMP2SSTINVWARP=${SST_Dir}/reg2temp/${NonLinTempImgName}_reg2temp_1InverseWarp
TEMP2SSTAFFINE=${SST_Dir}/reg2temp/${NonLinTempImgName}_reg2temp_0GenericAffine
NonLinSST_BrainMask=${SST_Dir}/sub-${SubID}_NonLinearSST_BrainMask

antsApplyTransforms -d 3 \
-i ${StudyTemplateBrainMask}.nii.gz \
-r ${NonLinSSTDirImg}.nii.gz \
-t [${TEMP2SSTAFFINE}.mat, 1] \
-t ${TEMP2SSTINVWARP}.nii.gz \
-n NearestNeighbor \
-o ${NonLinSST_BrainMask}.nii.gz >> /dev/null

$FSLDIR/bin/fslmaths ${NonLinSST_BrainMask}.nii.gz -fillh ${NonLinSST_BrainMask}.nii.gz
${FSLDIR}/bin/fslmaths ${NonLinSSTDirImg}.nii.gz -mas ${NonLinSST_BrainMask}.nii.gz ${NonLinSSTDirImg}_${BETREGOP}_brain.nii.gz
${FSLDIR}/bin/fslmaths ${NonLinSSTDirImg}.nii.gz -sub ${NonLinSSTDirImg}_${BETREGOP}_brain.nii.gz ${NonLinSSTDirImg}_${BETREGOP}_skull.nii.gz

######################

echo "++++++Now sort out the masks...."
echo ""

v_cnt=0
for SesID in ${SesIDList[@]}
do
	#SesID=${SesIDList[v_cnt]}

	echo "============================================================"
	echo "** StudyID: ${StudyID}, SubID: ${SubID}, SesID: ${SesID}"
	echo "============================================================"

	echo " ------------------------------------------------- SESSION: ${SesID} -------------"

	FreeSurfer_Dir=${PRSD_SUBDIR}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_run-1_T1w.${XSectionalDirSuffix}
	FreeSurfer_Vol_Dir=${FreeSurfer_Dir}/sub-${SubID}_ses-${SesID}_run-1_T1w/mri
	FreeSurfer_Vol_nuImg=${FreeSurfer_Vol_Dir}/nu

	#Moving Image
	Sub2NonLinSST_InvWarpFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nusub-${SubID}_ses-${SesID}_nu_2_median_nu${v_cnt}1InverseWarp
	Sub2NonLinSST_AffineFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nusub-${SubID}_ses-${SesID}_nu_2_median_nu${v_cnt}0GenericAffine
	FreeSurferVol_SubInMedian=${SST_Dir}/sub-${SubID}_ses-${SesID}_nu_2_median_nu

	LinearSSTBrainMask=${SST_Dir}/sub-${SubID}_ses-${SesID}_BrainMaskLinearSST
	#rm -f ${LinearSSTBrainMask}.nii.gz

	echo "*************************************************************"
	echo "--Session ID: ${SesID}, ${v_cnt}/${NumSes}"
	echo "MEDIAN LINEAR TEMPLATE: ${FreeSurferVol_SubInMedian}"
	echo "NU FS IMAGE IN MEDIAN LINEAR TEMPLATE: ${FreeSurferVol_SubInMedian}"
	echo "BRAIN MASK IN LINEAR SST: ${LinearSSTBrainMask}"
	echo "*************************************************************"

	# Take the mask from Nonlinear SST to single subjects in the median linear space -- all with skull
	antsApplyTransforms -d 3 \
	-i ${NonLinSST_BrainMask}.nii.gz \
	-r ${FreeSurferVol_SubInMedian}.nii.gz \
	-t [${Sub2NonLinSST_AffineFile}.mat, 1] \
	-t ${Sub2NonLinSST_InvWarpFile}.nii.gz \
	-o ${LinearSSTBrainMask}.nii.gz >> /dev/null

	echo "*************************************************************"
	echo "Brain Extraction on nu of each subject, in Linear SST"
	${FSLDIR}/bin/fslmaths ${LinearSSTBrainMask}.nii.gz -thr ${MaskThr} -bin ${LinearSSTBrainMask}.nii.gz
	${FSLDIR}/bin/fslmaths ${LinearSSTBrainMask}.nii.gz -fillh ${LinearSSTBrainMask}.nii.gz
	${FSLDIR}/bin/fslmaths ${FreeSurferVol_SubInMedian}.nii.gz -mas ${LinearSSTBrainMask}.nii.gz ${FreeSurferVol_SubInMedian}_${BETREGOP}_brain.nii.gz
	#skull
	${FSLDIR}/bin/fslmaths ${FreeSurferVol_SubInMedian}.nii.gz -sub ${FreeSurferVol_SubInMedian}_${BETREGOP}_brain.nii.gz ${FreeSurferVol_SubInMedian}_${BETREGOP}_skull.nii.gz
	echo "*************************************************************"

	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Nonlinear SST > Linear SST : DONE"
	${FSLDIR}/bin/fslinfo ${LinearSSTBrainMask}.nii.gz
	${FSLDIR}/bin/fslhd ${LinearSSTBrainMask}.nii.gz | grep sform
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

	# Get inverse of LTA
	LTA_FILE=${SST_Dir}/sub-${SubID}_ses-${SesID}_norm_xforms.lta
	INV_LTA_FILE=${SST_Dir}/sub-${SubID}_ses-${SesID}_norm_xforms_inv.lta # Inverse LTA
	lta_convert --inlta ${LTA_FILE} --outlta ${INV_LTA_FILE} --invert >> /dev/null # Convert the LTAs

	SubjBrainMaskFS=${SST_Dir}/sub-${SubID}_ses-${SesID}_BrainMaskFS
	#rm -f ${SubjBrainMaskFS}.nii.gz

	# take everything back into the nu.mgz space using inverse LTA
	mri_vol2vol --lta ${LTA_FILE} \
	--targ ${LinearSSTBrainMask}.nii.gz \
	--mov ${FreeSurfer_Vol_nuImg}.mgz \
	--no-resample \
	--inv \
	--o ${SubjBrainMaskFS}.nii.gz > /dev/null

	echo "*************************************************************"
	echo "Brain Extraction on FreeSurfer 1x1x1 256^3 space"
	${FSLDIR}/bin/fslmaths ${SubjBrainMaskFS}.nii.gz -thr ${MaskThr} -bin ${SubjBrainMaskFS}.nii.gz
	${FSLDIR}/bin/fslmaths ${SubjBrainMaskFS}.nii.gz -fillh ${SubjBrainMaskFS}.nii.gz
	mri_convert ${FreeSurfer_Vol_nuImg}.mgz ${FreeSurfer_Vol_nuImg}.nii.gz >> /dev/null
	${FSLDIR}/bin/fslmaths ${FreeSurfer_Vol_nuImg}.nii.gz -mas ${SubjBrainMaskFS}.nii.gz ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain.nii.gz
	#skull
	${FSLDIR}/bin/fslmaths ${FreeSurfer_Vol_nuImg}.nii.gz -sub ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain.nii.gz ${FreeSurfer_Vol_nuImg}_${BETREGOP}_skull.nii.gz
	echo "*************************************************************"

	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Linear SST > 1x1x1 256^3 : DONE"
	${FSLDIR}/bin/fslinfo ${SubjBrainMaskFS}.nii.gz
	${FSLDIR}/bin/fslhd ${SubjBrainMaskFS}.nii.gz | grep sform
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

	echo ""
	echo ""
	echo "*************************************************************"
	echo "Take the brains from FreeSurfer brain images to the rawavg space."
	echo "Make a mask of the rawavg."
	echo "*************************************************************"
	echo ""
	echo ""

	UnprocessedImg=${UnprocessedDir}/sub-${SubID}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_run-1_T1w

        #skull
        mri_vol2vol --mov ${FreeSurfer_Vol_nuImg}_${BETREGOP}_skull.nii.gz --targ ${UnprocessedImg}.nii.gz --regheader \
        --o ${FreeSurfer_Vol_nuImg}_${BETREGOP}_skull_rawavg.nii.gz --no-save-reg >> /dev/null

        #-- BRAIN MASKS
        mri_vol2vol --mov ${SubjBrainMaskFS}.nii.gz --targ ${UnprocessedImg}.nii.gz --regheader \
        --o ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg_mask.nii.gz --nearest --no-save-reg >> /dev/null

        ${FSLDIR}/bin/fslmaths ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg_mask.nii.gz -fillh ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg_mask.nii.gz
        ${FSLDIR}/bin/fslmaths ${UnprocessedImg}.nii.gz -mas ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg_mask.nii.gz ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg.nii.gz

        #echo "+_+_+_+_+__CHECK THIS:"
        #echo "${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg.nii.gz"
        #echo "${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg_mask.nii.gz"

		v_cnt=$((v_cnt+1))
done

echo "==================================="
echo "DONE-DONE-DONE-DONE-DONE-DONE-DONE"
echo "STARTED @" $(date)
echo "==================================="
