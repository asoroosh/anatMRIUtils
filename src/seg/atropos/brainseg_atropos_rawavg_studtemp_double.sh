#!/bin/bash
#
# Soroosh Afyouni, University of Oxford, 2020

set -e

source ${HOME}/NVROXBOX/AUX/Config/XXX

do_seg=1
do_seg1=1
do_seg2=1

use_priors=2

ImgTyp=T12D
#++++++++= Subject/Session Information

StudyID=$1
SubID=$2
SesID=$3
REGOPTAG="reg2temp"
OPTAG="antsstudtemp"

OpDirSuffix="atropos_p2" # Name of the Segmentation operation

TS_PriorIntepMethod=Linear
TS_AtlasIntepMethod=NearestNeighbor

PriorIntepMethod=Linear
AtlasIntepMethod=NearestNeighbor

#---------------------------------
OrFlag=LIA
SegOrFlg=LIA #Segmentation Orientations
TSOrientationFlag=LIA #TS Template Orientation
AtOrFlg=LIA # Atlas Orientation
PrOrFlg=LIA # Prior Orientation

FASTOPTS1=""
FASTOPTS2=""

VoxRes=1
tn=2 # number of tissues.
echo "======================================="
echo "STARTED @" $(date)
echo "======================================="
echo ""
echo "============================================================"
echo "============================================================"
echo "** StudyID: ${StudyID}, SubID: ${SubID}, SesID: ${SesID}, ON: ${OPTAG}"
echo "============================================================"
echo "============================================================"


SessionsFileName=${DataDir}/${StudyID}/T12D/Sessions/${StudyID}_sub-${SubID}_T12D.txt

echo "Number of sessions: $(cat ${SessionsFileName} | wc -l)"

#-------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------
# THIS SHOULD BE FIXED NEXT TIME THE METADATA IS RAN

# some of the images have two runs {1,2}, but we only take the first run
tmptextsession=session$RANDOM

awk '!/run-2/' ${SessionsFileName} > ${tmptextsession}
echo "Number of sessions: $(cat ${tmptextsession} | wc -l)"

#-------------------------------------------------------------------------------------

AA=$(echo "${UnprocessedPath}" | awk -F"/" '{print NF-1}'); #AA=$((AA+1))
while read SessionPathsFiles
do
        ses_SesID_tmp=$(echo $SessionPathsFiles | awk -F"/" -v xx=$((AA+3)) '{print $xx}')
        SesID_tmp=$(echo $ses_SesID_tmp | awk -F"-" '{print $2}')
        SesIDList="${SesIDList} $SesID_tmp"
#       echo ${SesIDList}
done<${tmptextsession}

rm ${tmptextsession}

SesIDList=(${SesIDList})

for i in "${!SesIDList[@]}"; do
        if [[ "${SesIDList[$i]}" = "${SesID}" ]]; then
                v_cnt=${i}
                echo ${v_cnt}
        fi
done

echo " "
echo "                ========================================================================"
echo "We are on Study ${StudyID}, Subject ${SubID}, Session ${SesID}, Session count ${v_cnt}. "
echo "                ========================================================================"

#-----------------------------------------------

MyAUX=${MyHOME}/NVROXBOX/AUX
STUDTEMPAUX=${MyAUX}/STUDTEMP/${StudyID}_50_RNDSST

#MyHOME=/well/My-mri-temp/users/scf915
#++++++++= TS TISSUE PRIORS
STUDTEMPTISSUEPRIORSDIR=${STUDTEMPAUX}/tissuepriors
STUDTEMPMASKSDIR=${STUDTEMPAUX}/masks
STUDTEMPATLASDIR=${STUDTEMPAUX}/atlas

MNIAUX=${MyAUX}/MNItemplates/${TSOrientationFlag}
# head --
MNIImg_RAS=${MNIAUX}/MNI152_T1_${VoxRes}mm_${TSOrientationFlag}
# MNI brain --
MNIImgBrain_RAS=${MNIAUX}/MNI152_T1_${VoxRes}mm_brain_${TSOrientationFlag}
# MNI skull --
MNIImgSkull_RAS=${MNIAUX}/MNI152_T1_${VoxRes}mm_skull_${TSOrientationFlag}

#++++++++= Harvard Oxford Atlas
STUDTEMPATLASIMG=${STUDTEMPATLASDIR}/${StudyID}_GMatlas_${VoxRes}mm_${TSOrientationFlag}

#+++++++++++++++++++++++++++++++++++++= PROCESSED DATA ++++
XSectionalDirSuffix=autorecon12ws
LogitudinalDirSuffix=nuws_mrirobusttemplate
# ------

#------------= Main paths
PRSD_SUBDIR=${PRSD_DIR}/${StudyID}/sub-${SubID}

#-------------= X Sectional paths
SST_Dir=${PRSD_SUBDIR}/${ImgTyp}.${XSectionalDirSuffix}.${LogitudinalDirSuffix}

#--------------= Unprocessed paths
UnprocessedDir=${UPRSD_DIR}/${StudyID}
UnprocessedImg=${UnprocessedDir}/sub-${SubID}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_run-1_T1w

#-----------= FREESURFER (AUTORECONN) RESULTS:
FreeSurfer_Dir=${PRSD_SUBDIR}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_run-1_T1w.${XSectionalDirSuffix}
FreeSurfer_Vol_Dir=${FreeSurfer_Dir}/sub-${SubID}_ses-${SesID}_run-1_T1w/mri
FreeSurfer_Vol_nuImg=${FreeSurfer_Vol_Dir}/nu_${OPTAG}
FreeSurfer_Vol_FSnuImg=${FreeSurfer_Vol_Dir}/nu

#-----------= SST TEMPLATE RESULTS:

#------ LINEAR SST
FreeSurferVol_SubInMedian=${SST_Dir}/sub-${SubID}_ses-${SesID}_nu_2_median_nu

Sub2NonLinSST_InvWarpFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nusub-${SubID}_ses-${SesID}_nu_2_median_nu${v_cnt}1InverseWarp
Sub2NonLinSST_AffineFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nusub-${SubID}_ses-${SesID}_nu_2_median_nu${v_cnt}0GenericAffine
Sub2NonLinSST_WarpFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nusub-${SubID}_ses-${SesID}_nu_2_median_nu${v_cnt}1Warp

#Sub2NonLinSST_WarpFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nu${SubTag}${v_cnt}1Warp
#Sub2NonLinSST_InvWarpFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nu${SubTag}${v_cnt}1InverseWarp
#Sub2NonLinSST_AffineFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nu${SubTag}${v_cnt}0GenericAffine

#------ NONLINEAR SST
NonLinTempImgName=sub-${SubID}_ants_temp_med_nutemplate0
NonLinSSTDirImg=${SST_Dir}/${NonLinTempImgName}
NonLinSSTDirImg_brain=${SST_Dir}/${NonLinTempImgName}_${OPTAG}_brain

#+++++++++= Seg RESULTS
PVE_Suboutdir=${PRSD_SUBDIR}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_${OpDirSuffix}_${OPTAG}_${tn}tissues_brain_rawavg
TissuePriors=${PVE_Suboutdir}/tissuepriors_sst
AtlasesDir=${PVE_Suboutdir}/atlases
TMPLDir=${PVE_Suboutdir}/templates

if [ $do_seg0 == 1 ] && [ $do_seg1 == 1 ] && [ $do_seg2 == 1 ]; then
        rm -rf ${PVE_Suboutdir}
fi

mkdir -p ${TissuePriors}
mkdir -p ${AtlasesDir}
mkdir -p ${TMPLDir}

SEG_LOG=${PVE_Suboutdir}/sub-${SubID}_ses-${SesID}_${OpDirSuffix}_brain_rawavg.log

#++++++++++= IDPs Results
GMPTXTDIRNAME=${PVE_Suboutdir}/IDPs/GMVols
SIENAXDIRNAME=${PVE_Suboutdir}/IDPs/SIENAX

#mkdir -p ${GMPTXTDIRNAME}
mkdir -p ${SIENAXDIRNAME}

#-----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#------------------------------------- Denoise and Correct the bias for rawavg images ----------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------

if [ ! -f ${FreeSurfer_Vol_nuImg}_brain_rawavg.nii.gz ] || [  ! -f ${FreeSurfer_Vol_nuImg}_brain_rawavg_mask.nii.gz ]; then
	echo "+++ERROR: FILE DOES NOT EXISTS: ${FreeSurfer_Vol_nuImg}_brain_rawavg.nii.gz or ${FreeSurfer_Vol_nuImg}_brain_rawavg.nii.gz"
	exit 1
fi


echo "++++ Sort out the ITK bug -----------------------------"
echo "+++ Copy headers ++++"
CopyImageHeaderInformation ${FreeSurfer_Vol_nuImg}_brain_rawavg.nii.gz ${FreeSurfer_Vol_nuImg}_brain_rawavg_mask.nii.gz ${FreeSurfer_Vol_nuImg}_brain_rawavg_mask.nii.gz 1 1 1
echo "bug fix done ------------------------------------------"

#
#echo ""
#echo ""
#echo "==================================================================================="
#echo "Perform Denoising on: ${FreeSurfer_Vol_nuImg}_brain_rawavg.nii.gz"
#DenoiseImage -d 3 -v 1 \
#-i ${FreeSurfer_Vol_nuImg}_brain_rawavg.nii.gz \
#-n Gaussian \
#-x ${FreeSurfer_Vol_nuImg}_brain_rawavg_mask.nii.gz \
#-o ${FreeSurfer_Vol_nuImg}_brain_rawavg_denoised.nii.gz
#
#echo "Image Denoising Perfomed: ${FreeSurfer_Vol_nuImg}_brain_rawavg_denoised.nii.gz "
#echo "==================================================================================="
#
#echo ""
#echo ""
#echo "==================================================================================="
#echo "Perfome N4biasfieldcorrection on: ${FreeSurfer_Vol_nuImg}_brain_rawavg_denoised.nii.gz"
#
#N4BiasFieldCorrection -d 3 -v 1 \
#-i ${FreeSurfer_Vol_nuImg}_brain_rawavg_denoised.nii.gz \
#-x ${FreeSurfer_Vol_nuImg}_brain_rawavg_mask.nii.gz \
#-o ${FreeSurfer_Vol_nuImg}_brain_rawavg_denoised_N4.nii.gz
#
#echo "N4 Bias Corrected Image: ${FreeSurfer_Vol_nuImg}_brain_rawavg_denoised_N4.nii.gz"
#echo "==================================================================================="


RegOutputPrefix=${SST_Dir}/${REGOPTAG}/${NonLinTempImgName}_${REGOPTAG}
NonLinSST_TS=${RegOutputPrefix}_WarpedToTemplate
NonLinSST_TS_Warp=${RegOutputPrefix}1Warp
NonLinSST_TS_InvWarp=${RegOutputPrefix}_1InverseWarp
NonLinSST_TS_Affine=${RegOutputPrefix}_0GenericAffine

#+++++++++= Registration to NonLinear SST Results
#FreeSurferVol_SubInMedian=${SST_Dir}/sub-${SubID}_ses-${SesID}_nu_2_median_nu
#Sub2NonLinSST_WarpFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nu${SubTag}${v_cnt}1Warp
#Sub2NonLinSST_InvWarpFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nu${SubTag}${v_cnt}1InverseWarp
#Sub2NonLinSST_AffineFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nu${SubTag}${v_cnt}0GenericAffine

#+++++++++= Resampling to the Linear SST Results
LTA_FILE=${SST_Dir}/sub-${SubID}_ses-${SesID}_norm_xforms.lta
INV_LTA_FILE=${SST_Dir}/sub-${SubID}_ses-${SesID}_norm_xforms_inv.lta

FreeSurferVol_SubInMedian=${SST_Dir}/sub-${SubID}_ses-${SesID}_nu_2_median_nu

PriorLabels=1
for TissueType in gray white csf brain
do
        echo "-- Convert the gray matter prior from LAS orientation (FSL) to ${TSOrientationFlag} orientation (FS)."

        #STUDTEMPTISSUEPRIORSIMG=${TissuePriors}/avg152T1_${TissueType}_${PrOrFlg}_${OPTAG}
        #mri_convert --in_orientation LAS --out_orientation ${TSOrientationFlag} ${STUDTEMPTISSUEPRIORSDIR}/avg152T1_${TissueType}.nii.gz ${STUDTEMPTISSUEPRIORSIMG}.nii.gz

        STUDTEMPTISSUEPRIORSIMG=${STUDTEMPTISSUEPRIORSDIR}/${StudyID}_avg152T1_${TissueType}_${VoxRes}mm_${PrOrFlg}

        NLSSTPriorPreFix=${TissuePriors}/sub-${SubID}_avg152T1_${TissueType}_${PrOrFlg}_${OPTAG}
        SUBSESPriorPreFix=${TissuePriors}/sub-${SubID}_ses-${SesID}_avg152T1_${TissueType}_${PrOrFlg}_${OPTAG}

        # From TS to Nonlinear SST
        echo "######## Take the priors from TS into the Nonlinear SST, use inwarp (ants)"
        echo "-- Moving image: ${STUDTEMPTISSUEPRIORSIMG}.nii.gz"
        echo "-- Reference Image: ${NonLinSSTDirImg}.nii.gz"
        echo "-- Inverse Warp: ${NonLinSST_TS_InvWarp}.nii.gz"
        echo "-- Affine: ${NonLinSST_TS_Affine}.mat"
        echo "########"
        echo " "

antsApplyTransforms \
-d 3 \
-i ${STUDTEMPTISSUEPRIORSIMG}.nii.gz \
-r ${NonLinSSTDirImg}.nii.gz \
-t [${NonLinSST_TS_Affine}.mat, 1] \
-t ${NonLinSST_TS_InvWarp}.nii.gz \
-n ${TS_PriorIntepMethod} \
-o ${NLSSTPriorPreFix}_NonLinearSST.nii.gz


# change this from FAST/FSL naming convention into FSL FAST naming convention
cp ${NLSSTPriorPreFix}_NonLinearSST.nii.gz \
${TissuePriors}/sub-${SubID}_avg152T1_${PriorLabels}_${PrOrFlg}_${OPTAG}_NonLinearSST.nii.gz

        echo "####### Take the priors from Nonlinear SST into the linear median SST, use invwarp (ants)"
        echo "-- Moving Image: ${NLSSTPriorPreFix}_NonLinearSST.nii.gz"
        echo "-- Reference: ${FreeSurferVol_SubInMedian}.nii.gz"
        echo "-- Inverse Warp: ${Sub2NonLinSST_InvWarpFile}.nii.gz"
        echo "-- Affine: ${Sub2NonLinSST_AffineFile}.mat"
        echo "-- Interpolation Method: ${PriorIntepMethod}"
        echo "#######"
        echo " "
antsApplyTransforms \
-d 3 \
-i ${NLSSTPriorPreFix}_NonLinearSST.nii.gz \
-r ${FreeSurferVol_SubInMedian}.nii.gz \
-t [${Sub2NonLinSST_AffineFile}.mat, 1] \
-t ${Sub2NonLinSST_InvWarpFile}.nii.gz \
-n ${PriorIntepMethod} \
-o ${SUBSESPriorPreFix}_LinearSST.nii.gz

        echo "####### Take the priors from linear SST into the nu.mgz space, mri_vol2vol --inv"
        echo "-- Moving Image: ${FreeSurfer_Vol_FSnuImg}.nii.gz"
        echo "-- Reference Image: ${SUBSESPriorPreFix}_LinearSST.nii.gz"
        echo "-- LTA: ${LTA_FILE}"
        echo "#######"
        echo " "

mri_vol2vol \
--lta ${LTA_FILE} \
--targ ${SUBSESPriorPreFix}_LinearSST.nii.gz \
--mov ${FreeSurfer_Vol_FSnuImg}.nii.gz \
--no-resample \
--inv \
--o ${SUBSESPriorPreFix}_nu.nii.gz #>> /dev/null 2>&1

        #From nu.mgz space into the native space
        echo "####### Take the priors from nu.mgz space into the rawavg space (native space)"
        echo "-- Moving Image: ${SUBSESPriorPreFix}_nu.nii.gz"
        echo "-- Reference Image: ${UnprocessedImg}.nii.gz"
        echo "#######"
        echo " "
mri_vol2vol \
--mov ${SUBSESPriorPreFix}_nu.nii.gz \
--targ ${UnprocessedImg}.nii.gz \
--regheader \
--o ${SUBSESPriorPreFix}_rawavg.nii.gz \
--no-save-reg >> /dev/null 2>&1

cp ${SUBSESPriorPreFix}_rawavg.nii.gz \
${TissuePriors}/sub-${SubID}_ses-${SesID}_avg152T1_${PriorLabels}_${PrOrFlg}_${OPTAG}_rawavg.nii.gz

        PriorLabels=$((($PriorLabels+1)))
done

#--------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------
#----------------------------------------------- Run segmentations --------------------------------------
#--------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------

echo "==================================================================================="
echo "0000 Running ${OpDirSuffix} on: 0000"
echo "++Input Image: ${FreeSurfer_Vol_nuImg}_brain_rawavg_denoised_N4.nii.gz"
echo "++Gray Matter prior: ${TissuePriors}/avg152T1_gray_ses-${SesID}_RAS2LAS_rawavg.nii.gz"
echo "++White Matter prior: ${TissuePriors}/avg152T1_white_ses-${SesID}_RAS2LAS_rawavg.nii.gz"
echo "++Results: ${PVE_Suboutdir}"
#echo "==================================================================================="

#SegOutPrefix=${PVE_Suboutdir}/sub-${SubID}_ses-${SesID}_${OpDirSuffix}_${OPTAG}_brain_rawavg_denoised_N4_${tn}tissues
SegOutPrefix=${PVE_Suboutdir}/sub-${SubID}_ses-${SesID}_${OpDirSuffix}_${OPTAG}_brain_rawavg_${tn}tissues
#AllSegFile=${SegOutPrefix}_
AllSegFile=${SegOutPrefix}Segmentation

if [ $do_seg == 1 ]; then

	SegOutPrefix1=${PVE_Suboutdir}/S1/sub-${SubID}_ses-${SesID}_${OpDirSuffix}_${OPTAG}_brain_rawavg_${tn}tissues
	AllSegFile1=${SegOutPrefix1}Segmentation

	echo "******** FIRST STAGE *************"

	echo "" > $SEG_LOG

	mkdir -p ${PVE_Suboutdir}/S1
	mkdir -p ${PVE_Suboutdir}/S2

	if [ $do_seg1 == 1 ]; then

	if [ $use_priors == 1 ]; then
		FASTOPTS1="-p ${TissuePriors}/sub-${SubID}_ses-${SesID}_avg152T1_%02d_${PrOrFlg}_${OPTAG}_rawavg.nii.gz -w 0.25  -y 1 -y 2 "
	elif [ $use_priors == 2 ]; then
                FASTOPTS1="-p ${TissuePriors}/sub-${SubID}_ses-${SesID}_avg152T1_%02d_${PrOrFlg}_${OPTAG}_rawavg.nii.gz"
	else
		echo "XXX NO PRIORS SET ON STAGE 1."
	fi

	#-p "${TissuePriors}/sub-${SubID}_ses-${SesID}_avg152T1_%02d_${PrOrFlg}_${OPTAG}_rawavg.nii.gz" \
	antsAtroposN4.sh -d 3 \
	-a ${FreeSurfer_Vol_nuImg}_brain_rawavg.nii.gz \
	-x ${FreeSurfer_Vol_nuImg}_brain_rawavg_mask.nii.gz \
	-c ${tn} ${FASTOPTS1} \
	-g 1 \
	-m 4 -n 15 \
	-o ${SegOutPrefix1} >> ${SEG_LOG}

	# CSF
	${FSLDIR}/bin/fslmaths ${AllSegFile1}.nii.gz -uthr 1.5 -thr 0.5 ${AllSegFile1}Seg01.nii.gz
	#BRAIN
	${FSLDIR}/bin/fslmaths ${AllSegFile1}.nii.gz -uthr 2.5 -thr 1.5 ${AllSegFile1}Seg02.nii.gz

	tissuetypelist=(foo csf brain)
	for ttcount in 1 2
	do
		for segt in Posteriors Seg
		do
			cp ${AllSegFile1}${segt}0${ttcount}.nii.gz ${SegOutPrefix}_${segt}_${tissuetypelist[$ttcount]}.nii.gz
		done
	done

	echo "Stage 1: DONE. "

	fi

	SegOutPrefix2=${PVE_Suboutdir}/S2/sub-${SubID}_ses-${SesID}_${OpDirSuffix}_${OPTAG}_brain_rawavg_${tn}tissues
	AllSegFile2=${SegOutPrefix2}Segmentation

	echo "BRAINEG: ${SegOutPrefix1}_seg_1"
	echo "MASKED BRAIN: ${SegOutPrefix2}_BRAIN.nii.gz"

	BRAIN_TMP=${SegOutPrefix}_Posteriors_brain
	BRAIN_SEG=${SegOutPrefix}_Seg050_brain

	${FSLDIR}/bin/fslmaths ${BRAIN_TMP} -thr 0.50 -bin ${BRAIN_SEG}

	${FSLDIR}/bin/cluster --in=${BRAIN_SEG} --thresh=1 --connectivity=6 --osize=${BRAIN_SEG}_cluster_size > ${SegOutPrefix1}_clusterinfo.txt
	CLUSTERSIZE1=$(cat ${SegOutPrefix1}_clusterinfo.txt  | awk 'NR==2' | awk '{print $2}')
	CLUSTERSIZE2=$(cat ${SegOutPrefix1}_clusterinfo.txt  | awk 'NR==3' | awk '{print $2}')

	CLUSTERSIZE2100=$(( CLUSTERSIZE2 * 100))
	cluster1to2ratio=$(( CLUSTERSIZE2100 / CLUSTERSIZE1 ))

	echo "Largest cluster size is: ${CLUSTERSIZE1}"
	echo "2nd Largest cluster size: ${CLUSTERSIZE2}"
	echo "Ratio of the first and the second: ${cluster1to2ratio}"

	if [ $cluster1to2ratio -gt 20 ]; then
		CLUSTERSIZE=$CLUSTERSIZE2
		echo "WARNING::: THE SECOND CLUSTER IS ALSO BIG, RATIO: ${CLUSTERSIZE2100}"
	else
		CLUSTERSIZE=$CLUSTERSIZE1
	fi

	${FSLDIR}/bin/fslmaths ${BRAIN_SEG}_cluster_size -thr ${CLUSTERSIZE} -bin ${BRAIN_SEG}

	${FSLDIR}/bin/fslmaths ${AllSegFile1}0N4.nii.gz -mas ${BRAIN_SEG} ${SegOutPrefix2}_BRAIN

	echo "******** SECOND STAGE *************"
#	FASTOPTS2=" -A ${TissuePriors}/sub-${SubID}_ses-${SesID}_avg152T1_white_${SegOrFlg}_${OPTAG}_rawavg.nii.gz ${TissuePriors}/sub-${SubID}_ses-${SesID}_avg152T1_gray_${SegOrFlg}_${OPTAG}_rawavg.nii.gz"

	if [ $use_priors == 1 ]; then
		FASTOPTS2="-p ${TissuePriors}/sub-${SubID}_ses-${SesID}_avg152T1_%02d_${PrOrFlg}_${OPTAG}_rawavg.nii.gz -y 1 -y 2 -w 0.25"
	elif [ $use_priors == 2 ]; then
		FASTOPTS2="-p ${TissuePriors}/sub-${SubID}_ses-${SesID}_avg152T1_%02d_${PrOrFlg}_${OPTAG}_rawavg.nii.gz"
	else
		echo "XXX NO PRIORS SET ON STAGE 2."
	fi
	#-p "${TissuePriors}/sub-${SubID}_ses-${SesID}_avg152T1_%02d_${PrOrFlg}_${OPTAG}_rawavg.nii.gz"
        antsAtroposN4.sh -d 3 \
        -a ${SegOutPrefix2}_BRAIN.nii.gz \
        -x ${BRAIN_SEG}.nii.gz \
        -c ${tn} ${FASTOPTS2} \
        -g 1 \
        -m 4 -n 15 \
        -o ${SegOutPrefix2} >> ${SEG_LOG}

        # CSF
        ${FSLDIR}/bin/fslmaths ${AllSegFile2}.nii.gz -uthr 1.5 -thr 0.5 ${AllSegFile2}Seg01.nii.gz
        #BRAIN
        ${FSLDIR}/bin/fslmaths ${AllSegFile2}.nii.gz -uthr 2.5 -thr 1.5 ${AllSegFile2}Seg02.nii.gz

	echo "*Stage 2 is done."

	tissuetypelist=(foo gray white)
	for ttcount in 1 2
	do
		for segt in Posteriors Seg
		do
			echo "Cook: ${ttcount} -- ${segt}"
			cp ${AllSegFile2}${segt}0${ttcount}.nii.gz ${SegOutPrefix}_${segt}_${tissuetypelist[$ttcount]}.nii.gz
		done
	done

else
	echo "##### I WONT RUN SEGMENTATION"
fi

echo "Now the correlations"

for ttype in gray white csf brain
do
	RR=$(ImageMath 3 "" PearsonCorrelation ${SegOutPrefix}_Posteriors_${ttype}.nii.gz ${TissuePriors}/sub-${SubID}_ses-${SesID}_avg152T1_${ttype}_${SegOrFlg}_${OPTAG}_rawavg.nii.gz)
	echo "${ttype}: ${RR}"
	echo "${ttype}: ${RR}" >> ${PVE_Suboutdir}/Corr_PVE_Priors.txt
done

#-----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#----------------------------Take everything back into the MNI space now------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------

FS_InterpolationMethod_List=("" "--nearest")
InterpolationMethod_List=("Linear" "NearestNeighbor")
OutputFiletype_List=("Posteriors" "Seg")

#for filetype_cnt in 0 1 # move Posteriors and seg files around
#do
#        InterpMeth=${InterpolationMethod_List[$filetype_cnt]}
#        segfiletype=${OutputFiletype_List[$filetype_cnt]}
#	FSInterpMeth=${FS_InterpolationMethod_List[$filetype_cnt]}
#
#        echo "-----------------------------------------"
#        echo "Segmentation File: ${segfiletype}"
#        echo "Interpolation Method: ${InterpMeth}"
#	echo "Interpolation Method for mri_vol2vol: ${FSInterpMeth}"
#        echo "-----------------------------------------"
#
#        for tissue_cnt in 0 1 2 # loop around the $OpDirSuffix output tissues; of course for -n 3 ;; CSF: 1, GM: 2, WM: 3
#        do
#
#		SegTisFile=${AllSegFile}${segfiletype}_${tissue_cnt}
#
#                echo "#### Native Subj Space >> FS 1x1x1 256^3 ---- Tissue Count: ${tissue_cnt}, Segmentation File: ${segfiletype}, Interpolation Metho: ${InterpMeth}"
#		echo "-- Moving Image: ${SegTisFile}.nii.gz"
#		echo "-- Reference Image: ${FreeSurfer_Vol_nu}_brain.nii.gz"
#		echo "####"
#		echo " "
#mri_vol2vol \
#--mov ${SegTisFile}.nii.gz \
#--targ ${FreeSurfer_Vol_nuImg}_brain.nii.gz \
#--regheader \
#--o ${SegTisFile}_nu_brain.nii.gz --no-save-reg \
#${FSInterpMeth} #>> /dev/null 2>&1
#
#		echo "#### FS 1x1x1 256^3 >> Linear Median SST  ---- Tissue Count: ${tissue_cnt}, Segmentation File: ${segfiletype}, Interpolation Method: ${InterpMeth}"
#		echo "-- Moving Image: ${SegTisFile}_nu_brain.nii.gz"
#		echo "-- Reference Image: ${FreeSurferVol_SubInMedian}.nii.gz"
#		echo "-- LTA: ${LTA_FILE}"
#		echo "####"
#		echo " "
#
#mri_vol2vol --lta ${LTA_FILE} \
#--targ ${FreeSurferVol_SubInMedian}.nii.gz \
#--mov ${SegTisFile}_nu_brain.nii.gz \
#--no-resample \
#--o ${SegTisFile}_LinearSST.nii.gz \
#${FSInterpMeth} #>> /dev/null 2>&1
#
#		echo "#### Linear SST >> Non Linear SST  ---- Tissue Count: ${tissue_cnt}, Segmentation File: ${segfiletype}, Interpolation Method: ${InterpMeth}"
#		echo "-- Moving Image: ${SegTisFile}_LinearSST.nii.gz"
#		echo "-- Reference Image: ${NonLinSSTDirImg}.nii.gz"
#		echo "-- FWD Warp: ${Sub2NonLinSST_WarpFile}.nii.gz"
#		echo "-- Affine: ${Sub2NonLinSST_AffineFile}.mat"
#		echo "-- Intepolation Method: ${InterpMeth}"
#		echo "####"
#		echo " "
#
#antsApplyTransforms -d 3 \
#-i ${SegTisFile}_LinearSST.nii.gz \
#-r ${NonLinSSTDirImg}.nii.gz \
#-t ${Sub2NonLinSST_AffineFile}.mat \
#-t ${Sub2NonLinSST_WarpFile}.nii.gz \
#-n ${InterpMeth} \
#-o ${SegTisFile}_NonLinearSST.nii.gz
#
#                echo "#### Non Linear SST >> MNI Space (RAS)  ---- Tissue Count: ${tissue_cnt}, Segmentation File: ${segfiletype}, Interpolation Method: ${InterpMeth}"
#		echo "-- Moving Image: ${SegTisFile}_NonLinearSST.nii.gz"
#		echo "-- Reference Image: ${MNIImgBrain_RAS}.nii.gz"
#		echo "-- FWD Warp: ${NonLinSST_TS_Warp}.nii.gz"
#		echo "-- Affine: ${NonLinSST_TS_Affine}.mat"
#		echo "-- Intepolation Method: ${InterpMeth}"
#		echo "####"
#		echo " "
#
#                #Take me from NonLinear SST to the MNI
#antsApplyTransforms -d 3 \
#-i ${SegTisFile}_NonLinearSST.nii.gz \
#-r ${MNIImgBrain_RAS}.nii.gz \
#-t ${NonLinSST_TS_Affine}.mat \
#-t ${NonLinSST_TS_Warp}.nii.gz \
#-n ${InterpMeth} \
#-o ${SegTisFile}_MNI.nii.gz
#
#	done
#done
#
#-----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#--------------------------------- TAKE  THE ATLAS INTO RAWAVG SPACE ---------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------


NLSSTAtlasPreFix=${AtlasesDir}/sub-${SubID}_${AtOrFlg}_${OPTAG}_UKB-GMAtlas
SUBSESAtlasPreFix=${AtlasesDir}/sub-${SubID}_ses-${SesID}_${AtOrFlg}_${OPTAG}_UKB-GMAtlas

echo "######## Take the ATLAS from MNI into the Nonlinear SST, use inwarp (ants)"
echo "-- Moving image: ${STUDTEMPATLASIMG}.nii.gz"
echo "-- Reference Image: ${NonLinSSTDirImg}.nii.gz"
echo "-- Inverse Warp: ${NonLinSST_TS_InvWarp}.nii.gz"
echo "-- Affine: ${NonLinSST_TS_Affine}.mat"
echo "########"
echo " "

antsApplyTransforms \
-d 3 \
-i ${STUDTEMPATLASIMG}.nii.gz \
-r ${NonLinSSTDirImg}.nii.gz \
-t [${NonLinSST_TS_Affine}.mat, 1] \
-t ${NonLinSST_TS_InvWarp}.nii.gz \
-n ${TS_AtlasIntepMethod} \
-o ${NLSSTAtlasPreFix}_NonLinearSST.nii.gz

echo "####### Take the ATLAS from Nonlinear SST into the linear median SST, use invwarp (ants)"
echo "-- Moving Image: ${NLSSTAtlasPreFix}_NonLinearSST.nii.gz"
echo "-- Reference: ${FreeSurferVol_SubInMedian}.nii.gz"
echo "-- Inverse Warp: ${Sub2NonLinSST_InvWarpFile}.nii.gz"
echo "-- Affine: ${Sub2NonLinSST_AffineFile}.mat"
echo "-- Interpolation Method: ${AtlasIntepMethod}"
echo "#######"
echo " "

antsApplyTransforms \
-d 3 \
-i ${NLSSTAtlasPreFix}_NonLinearSST.nii.gz \
-r ${FreeSurferVol_SubInMedian}.nii.gz \
-t [${Sub2NonLinSST_AffineFile}.mat, 1] \
-t ${Sub2NonLinSST_InvWarpFile}.nii.gz \
-n ${AtlasIntepMethod} \
-o ${SUBSESAtlasPreFix}_LinearSST.nii.gz

echo "####### Take the ATLAS from linear SST into the nu.mgz space, mri_vol2vol --inv"
echo "-- Moving Image: ${FreeSurfer_Vol_FSnuImg}.nii.gz"
echo "-- Reference Image: ${SUBSESAtlasPreFix}_LinearSST.nii.gz"
echo "-- LTA: ${LTA_FILE}"
echo "#######"
echo " "

mri_vol2vol \
--lta ${LTA_FILE} \
--targ ${SUBSESAtlasPreFix}_LinearSST.nii.gz \
--mov ${FreeSurfer_Vol_FSnuImg}.nii.gz \
--no-resample \
--inv \
--nearest \
--o ${SUBSESAtlasPreFix}_nu.nii.gz >> /dev/null 2>&1

#From nu.mgz space into the native space
echo "####### Take the ATLAS from nu.mgz space into the rawavg space (native space)"
echo "-- Moving Image: ${SUBSESAtlasPreFix}_nu.nii.gz"
echo "-- Reference Image: ${UnprocessedImg}.nii.gz"
echo "#######"
echo " "

mri_vol2vol \
--mov ${SUBSESAtlasPreFix}_nu.nii.gz \
--targ ${UnprocessedImg}.nii.gz \
--regheader \
--o ${SUBSESAtlasPreFix}_rawavg.nii.gz \
--nearest \
--no-save-reg >> /dev/null 2>&1


#-----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#------------------------------------------------- SIENAX ON THE SEGs --------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------


#echo ""
#echo "#################################################"
#echo "SIENAX ##########################################"
#echo "#################################################"
#
#SIENAXFILENAME=${SIENAXDIRNAME}/sub-${SubID}_ses-${SesID}_${OPTAG}_Sienax
#
#T12MNIlinear_RAS=${SIENAXFILENAME}_T12MNI_${MNIOrientationFlag}
#report_sienax=${SIENAXFILENAME}_Report
#
#STUDTEMP_GMSEG=${STUDTEMPMASKSDIR}/${StudyID}_T1_${VoxRes}mm_strucseg_${TSOrientationFlag}_NoCereb_bin
#NLSST_GMSEG_PreFix=${TMPLDir}/sub-${SubID}_${AtOrFlg}_${OPTAG}_strucseg_nocereb
#SUBSES_GMSEG_PreFix=${TMPLDir}/sub-${SubID}_ses-${SesID}_${AtOrFlg}_${OPTAG}_strucseg_nocereb
#
##----------------------------------------------------------------
##------------------------------ AVSCALE -------------------------
##----------------------------------------------------------------
#
#echo "########### Calculate the Linear Transformation (rawavg >> MNI) using FSL parreg:"
#
#${FSLDIR}/bin/pairreg \
#${MNIImgBrain_RAS}.nii.gz ${FreeSurfer_Vol_nuImg}_brain_rawavg.nii.gz \
#${MNIImgSkull_RAS}.nii.gz ${FreeSurfer_Vol_nuImg}_skull_rawavg.nii.gz \
#${T12MNIlinear_RAS}.mat >> ${report_sienax} 2>&1
#
#echo "########## AVSCALE "
#
##-----------------------Get the avscale
#${FSLDIR}/bin/avscale ${T12MNIlinear_RAS}.mat ${MNIImg_RAS}.nii.gz > ${T12MNIlinear_RAS}.avscale
#xscale=`grep Scales ${T12MNIlinear_RAS}.avscale | awk '{print $4}'`
#yscale=`grep Scales ${T12MNIlinear_RAS}.avscale | awk '{print $5}'`
#zscale=`grep Scales ${T12MNIlinear_RAS}.avscale | awk '{print $6}'`
#vscale=`echo "10 k $xscale $yscale * $zscale * p"|dc -`
#echo "Volumetric Scaling (T1 > MNI; linear) & Tissue Volumes;" > ${report_sienax}
#echo "VSCALING $vscale" >> ${report_sienax}
#
##----------------------------------------------------------------
##------------------- TAKE A WHOLE MASK WITHOUT CEREB ------------
##----------------------------------------------------------------
#
#echo "############# Take the SEG VENT from MNI to RAWAVG:" 
#
#antsApplyTransforms \
#-d 3 \
#-i ${STUDTEMP_GMSEG}.nii.gz \
#-r ${NonLinSSTDirImg}.nii.gz \
#-t [${NonLinSST_TS_Affine}.mat, 1] \
#-t ${NonLinSST_TS_InvWarp}.nii.gz \
#-n ${TS_AtlasIntepMethod} \
#-o ${NLSST_GMSEG_PreFix}_NonLinearSST.nii.gz
#
#antsApplyTransforms \
#-d 3 \
#-i ${NLSST_GMSEG_PreFix}_NonLinearSST.nii.gz \
#-r ${FreeSurferVol_SubInMedian}.nii.gz \
#-t [${Sub2NonLinSST_AffineFile}.mat, 1] \
#-t ${Sub2NonLinSST_InvWarpFile}.nii.gz \
#-n ${AtlasIntepMethod} \
#-o ${SUBSES_GMSEG_PreFix}_LinearSST.nii.gz
#
#mri_vol2vol \
#--lta ${LTA_FILE} \
#--targ ${SUBSES_GMSEG_PreFix}_LinearSST.nii.gz \
#--mov ${FreeSurfer_Vol_FSnuImg}.nii.gz \
#--no-resample \
#--inv \
#--nearest \
#--o ${SUBSES_GMSEG_PreFix}_nu.nii.gz >> /dev/null 2>&1

#mri_vol2vol \
#--mov ${SUBSES_GMSEG_PreFix}_nu.nii.gz \
#--targ ${UnprocessedImg}.nii.gz \
#--regheader \
#--o ${SUBSES_GMSEG_PreFix}_rawavg.nii.gz \
#--nearest \
#--no-save-reg >> /dev/null 2>&1
#
##----------------------------------------------------------------
##-------------------- CALCULATE THE VOLUMES ---------------------
##----------------------------------------------------------------
#echo "###### Calculate the normalised/non-normalised volumes."
#echo "tissue             volume    unnormalised-volume" >> ${report_sienax}
#------------------
#segfiletype=Posteriors
#tissue_cnt=1 #CSF: 0, GM: 1, WM: 2
#SEG_FILE_RAWAVG=${AllSegFile}${segfiletype}_${tissue_cnt}
## ---------------- without cerebellum
#${FSLDIR}/bin/fslmaths ${SEG_FILE_RAWAVG}.nii.gz -mas ${SUBSES_GMSEG_PreFix}_rawavg.nii.gz ${SEG_FILE_RAWAVG}_nocereb.nii.gz -odt float
#S=`${FSLDIR}/bin/fslstats ${SEG_FILE_RAWAVG}_nocereb.nii.gz -m -v`
#xa=`echo $S | awk '{print $1}'`
#xb=`echo $S | awk '{print $3}'`
#uwhite_wc=`echo "2 k $xa $xb * 1 / p" | dc -`
#nwhite_wc=`echo "2 k $xa $xb * $vscale * 1 / p" | dc -`
#echo "BRAIN w/o Cereb    $nwhite_wc $uwhite_wc" >> ${report_sienax}
#
##--------------- with cerebellum
#S=`${FSLDIR}/bin/fslstats ${SEG_FILE_RAWAVG}.nii.gz -m -v`
#xa=`echo $S | awk '{print $1}'`
#xb=`echo $S | awk '{print $3}'`
#uwhite=`echo "2 k $xa $xb * 1 / p" | dc -`
#nwhite=`echo "2 k $xa $xb * $vscale * 1 / p" | dc -`
#echo "BRAIN              $nwhite $uwhite" >> ${report_sienax}

echo ""
echo "#################################################"
echo "SIENAX ##########################################"
echo "#################################################"
echo ""

SIENAXFILENAME=${SIENAXDIRNAME}/sub-${SubID}_ses-${SesID}_${OPTAG}_Sienax

T12MNIlinear_RAS=${SIENAXFILENAME}_T12MNI_${TSOrientationFlag}
report_sienax=${SIENAXFILENAME}_Report

STUDTEMP_GMSEG=${STUDTEMPMASKSDIR}/${StudyID}_T1_${VoxRes}mm_strucseg_${TSOrientationFlag}_NoCereb_bin
NLSST_GMSEG_PreFix=${TMPLDir}/sub-${SubID}_${AtOrFlg}_${OPTAG}_strucseg_nocereb
SUBSES_GMSEG_PreFix=${TMPLDir}/sub-${SubID}_ses-${SesID}_${AtOrFlg}_${OPTAG}_strucseg_nocereb

STUDTEMP_SEGPRIPH=${STUDTEMPMASKSDIR}/${StudyID}_T1_${VoxRes}mm_strucseg_periph_${TSOrientationFlag}
STUDTEMP_SEGVENT=${STUDTEMPMASKSDIR}/${StudyID}_T1_${VoxRes}mm_strucseg_${TSOrientationFlag}_Vent

NLSST_PRIPHSEG_PreFix=${TMPLDir}/sub-${SubID}_${AtOrFlg}_${OPTAG}_strucseg_periph
SUBSES_PRIPHSEG_PreFix=${TMPLDir}/sub-${SubID}_ses-${SesID}_${AtOrFlg}_${OPTAG}_strucseg_periph

NLSST_VENTSEG_PreFix=${TMPLDir}/sub-${SubID}_${AtOrFlg}_${OPTAG}_strucseg_vent
SUBSES_VENTSEG_PreFix=${TMPLDir}/sub-${SubID}_ses-${SesID}_${AtOrFlg}_${OPTAG}_strucseg_vent

#----------------------------------------------------------------
#------------------------------ AVSCALE -------------------------
#----------------------------------------------------------------

echo "########### Calculate the Linear Transformation (rawavg >> MNI) using FSL parreg:"

#echo "CHECKS:"
#echo "${FreeSurfer_Vol_nuImg}_brain_rawavg.nii.gz"
#echo "${MNIImgSkull_RAS}.nii.gz"
#echo "${FreeSurfer_Vol_nuImg}_skull_rawavg.nii.gz "

${FSLDIR}/bin/pairreg \
${MNIImgBrain_RAS}.nii.gz ${FreeSurfer_Vol_nuImg}_brain_rawavg.nii.gz \
${MNIImgSkull_RAS}.nii.gz ${FreeSurfer_Vol_nuImg}_skull_rawavg.nii.gz \
${T12MNIlinear_RAS}.mat >> ${report_sienax} 2>&1

echo "########## AVSCALE "

#-----------------------Get the avscale
${FSLDIR}/bin/avscale ${T12MNIlinear_RAS}.mat ${MNIImg_RAS}.nii.gz > ${T12MNIlinear_RAS}.avscale
xscale=`grep Scales ${T12MNIlinear_RAS}.avscale | awk '{print $4}'`
yscale=`grep Scales ${T12MNIlinear_RAS}.avscale | awk '{print $5}'`
zscale=`grep Scales ${T12MNIlinear_RAS}.avscale | awk '{print $6}'`
vscale=`echo "10 k $xscale $yscale * $zscale * p"|dc -`
echo "Volumetric Scaling (T1 > MNI; linear) & Tissue Volumes;" > ${report_sienax}
echo "VSCALING $vscale" >> ${report_sienax}


#----------------------------------------------------------------
#------------------- TAKE PRIPH SEG TS > AVGRAW ----------------
#----------------------------------------------------------------

echo "############# Take the SEG PRIPH from TS to RAWAVG:"

antsApplyTransforms \
-d 3 \
-i ${STUDTEMP_SEGPRIPH}.nii.gz \
-r ${NonLinSSTDirImg}.nii.gz \
-t [${NonLinSST_TS_Affine}.mat, 1] \
-t ${NonLinSST_TS_InvWarp}.nii.gz \
-n ${TS_AtlasIntepMethod} \
-o ${NLSST_PRIPHSEG_PreFix}_NonLinearSST.nii.gz

antsApplyTransforms \
-d 3 \
-i ${NLSST_PRIPHSEG_PreFix}_NonLinearSST.nii.gz \
-r ${FreeSurferVol_SubInMedian}.nii.gz \
-t [${Sub2NonLinSST_AffineFile}.mat, 1] \
-t ${Sub2NonLinSST_InvWarpFile}.nii.gz \
-n ${AtlasIntepMethod} \
-o ${SUBSES_PRIPHSEG_PreFix}_LinearSST.nii.gz

mri_vol2vol \
--lta ${LTA_FILE} \
--targ ${SUBSES_PRIPHSEG_PreFix}_LinearSST.nii.gz \
--mov ${FreeSurfer_Vol_FSnuImg}.nii.gz \
--no-resample \
--inv \
--nearest \
--o ${SUBSES_PRIPHSEG_PreFix}_nu.nii.gz >> /dev/null 2>&1

mri_vol2vol \
--mov ${SUBSES_PRIPHSEG_PreFix}_nu.nii.gz \
--targ ${UnprocessedImg}.nii.gz \
--regheader \
--o ${SUBSES_PRIPHSEG_PreFix}_rawavg.nii.gz \
--nearest \
--no-save-reg >> /dev/null 2>&1

#----------------------------------------------------------------
#------------------- TAKE VENT SEG TS > AVGRAW ----------------
#----------------------------------------------------------------

echo "############# Take the SEG VENT from TS to RAWAVG:"

antsApplyTransforms \
-d 3 \
-i ${STUDTEMP_SEGVENT}.nii.gz \
-r ${NonLinSSTDirImg}.nii.gz \
-t [${NonLinSST_TS_Affine}.mat, 1] \
-t ${NonLinSST_TS_InvWarp}.nii.gz \
-n ${TS_AtlasIntepMethod} \
-o ${NLSST_VENTSEG_PreFix}_NonLinearSST.nii.gz

antsApplyTransforms \
-d 3 \
-i ${NLSST_VENTSEG_PreFix}_NonLinearSST.nii.gz \
-r ${FreeSurferVol_SubInMedian}.nii.gz \
-t [${Sub2NonLinSST_AffineFile}.mat, 1] \
-t ${Sub2NonLinSST_InvWarpFile}.nii.gz \
-n ${AtlasIntepMethod} \
-o ${SUBSES_VENTSEG_PreFix}_LinearSST.nii.gz

mri_vol2vol \
--lta ${LTA_FILE} \
--targ ${SUBSES_VENTSEG_PreFix}_LinearSST.nii.gz \
--mov ${FreeSurfer_Vol_FSnuImg}.nii.gz \
--no-resample \
--inv \
--nearest \
--o ${SUBSES_VENTSEG_PreFix}_nu.nii.gz >> /dev/null 2>&1

mri_vol2vol \
--mov ${SUBSES_VENTSEG_PreFix}_nu.nii.gz \
--targ ${UnprocessedImg}.nii.gz \
--regheader \
--o ${SUBSES_VENTSEG_PreFix}_rawavg.nii.gz \
--nearest \
--no-save-reg >> /dev/null 2>&1


#----------------------------------------------------------------
#------------------- TAKE A WHOLE MASK WITHOUT CEREB ------------
#----------------------------------------------------------------

echo "############# Take the SEG VENT from TS to RAWAVG:"

antsApplyTransforms \
-d 3 \
-i ${STUDTEMP_GMSEG}.nii.gz \
-r ${NonLinSSTDirImg}.nii.gz \
-t [${NonLinSST_TS_Affine}.mat, 1] \
-t ${NonLinSST_TS_InvWarp}.nii.gz \
-n ${TS_AtlasIntepMethod} \
-o ${NLSST_GMSEG_PreFix}_NonLinearSST.nii.gz

antsApplyTransforms \
-d 3 \
-i ${NLSST_GMSEG_PreFix}_NonLinearSST.nii.gz \
-r ${FreeSurferVol_SubInMedian}.nii.gz \
-t [${Sub2NonLinSST_AffineFile}.mat, 1] \
-t ${Sub2NonLinSST_InvWarpFile}.nii.gz \
-n ${AtlasIntepMethod} \
-o ${SUBSES_GMSEG_PreFix}_LinearSST.nii.gz

mri_vol2vol \
--lta ${LTA_FILE} \
--targ ${SUBSES_GMSEG_PreFix}_LinearSST.nii.gz \
--mov ${FreeSurfer_Vol_FSnuImg}.nii.gz \
--no-resample \
--inv \
--nearest \
--o ${SUBSES_GMSEG_PreFix}_nu.nii.gz >> /dev/null 2>&1

mri_vol2vol \
--mov ${SUBSES_GMSEG_PreFix}_nu.nii.gz \
--targ ${UnprocessedImg}.nii.gz \
--regheader \
--o ${SUBSES_GMSEG_PreFix}_rawavg.nii.gz \
--nearest \
--no-save-reg >> /dev/null 2>&1

#----------------------------------------------------------------
#-------------------- CALCULATE THE VOLUMES ---------------------
#----------------------------------------------------------------

echo "###### Calculate the normalised/non-normalised volumes."

echo "tissue             volume    unnormalised-volume" >> ${report_sienax}

#----------------------------------------------------------------
# GRAY MATTER ---------------------------------------------------
#----------------------------------------------------------------

segfiletype=Posteriors
#tissue_cnt=1 #CSF: 0, GM: 1, WM: 2
#_Posteriors_gray.nii.gz
tissue_cnt=gray
SEG_FILE_RAWAVG=${SegOutPrefix}_${segfiletype}_${tissue_cnt}

# mask the Posteriors with priph in native space
${FSLDIR}/bin/fslmaths ${SEG_FILE_RAWAVG}.nii.gz -mas ${SUBSES_PRIPHSEG_PreFix}_rawavg.nii.gz ${SEG_FILE_RAWAVG}_segpriph.nii.gz -odt float

S=`${FSLDIR}/bin/fslstats ${SEG_FILE_RAWAVG}_segpriph.nii.gz -m -v`
xa=`echo $S | awk '{print $1}'`
xb=`echo $S | awk '{print $3}'`
uxg=`echo "2 k $xa $xb * 1 / p" | dc -`
xg=`echo "2 k $xa $xb * $vscale * 1 / p" | dc -`
echo "pgrey              $xg $uxg (peripheral grey)" >> ${report_sienax}

#----------------------------------------------------------------
# CSF -----------------------------------------------------------
#----------------------------------------------------------------

segfiletype=Posteriors
#tissue_cnt=0 #CSF: 0, GM: 1, WM: 2
tissue_cnt=csf
SEG_FILE_RAWAVG=${SegOutPrefix}_${segfiletype}_${tissue_cnt}
${FSLDIR}/bin/fslmaths ${SEG_FILE_RAWAVG}.nii.gz -mas ${SUBSES_VENTSEG_PreFix}_rawavg.nii.gz ${SEG_FILE_RAWAVG}_segvent.nii.gz -odt float

S=`${FSLDIR}/bin/fslstats ${SEG_FILE_RAWAVG}_segvent.nii.gz -m -v`
xa=`echo $S | awk '{print $1}'`
xb=`echo $S | awk '{print $3}'`
uxg=`echo "2 k $xa $xb * 1 / p" | dc -`
xg=`echo "2 k $xa $xb * $vscale * 1 / p" | dc -`
echo "vcsf               $xg $uxg (ventricular CSF)" >> ${report_sienax}

#----------------------------------------------------------------
# WHOLE GRAY MATTER ---------------------------------------------
#----------------------------------------------------------------

segfiletype=Posteriors
#tissue_cnt=1 #CSF: 0, GM: 1, WM: 2
tissue_cnt=gray
SEG_FILE_RAWAVG=${SegOutPrefix}_${segfiletype}_${tissue_cnt}

# ---------------- without cerebellum
${FSLDIR}/bin/fslmaths ${SEG_FILE_RAWAVG}.nii.gz -mas ${SUBSES_GMSEG_PreFix}_rawavg.nii.gz ${SEG_FILE_RAWAVG}_nocereb.nii.gz -odt float

S=`${FSLDIR}/bin/fslstats ${SEG_FILE_RAWAVG}_nocereb.nii.gz -m -v`
xa=`echo $S | awk '{print $1}'`
xb=`echo $S | awk '{print $3}'`
ugrey_wc=`echo "2 k $xa $xb * 1 / p" | dc -`
ngrey_wc=`echo "2 k $xa $xb * $vscale * 1 / p" | dc -`
echo "GREY w/o Cereb     $ngrey_wc $ugrey_wc" >> ${report_sienax}

#--------------- with cerebellum
S=`${FSLDIR}/bin/fslstats ${SEG_FILE_RAWAVG}.nii.gz -m -v`
xa=`echo $S | awk '{print $1}'`
xb=`echo $S | awk '{print $3}'`
ugrey=`echo "2 k $xa $xb * 1 / p" | dc -`
ngrey=`echo "2 k $xa $xb * $vscale * 1 / p" | dc -`
echo "GREY               $ngrey $ugrey" >> ${report_sienax}

#----------------------------------------------------------------
# WHITE MATTER --------------------------------------------------
#----------------------------------------------------------------

segfiletype=Posteriors
#tissue_cnt=2 #CSF: 0, GM: 1, WM: 2
tissue_cnt=white
SEG_FILE_RAWAVG=${SegOutPrefix}_${segfiletype}_${tissue_cnt}

# ---------------- without cerebellum
${FSLDIR}/bin/fslmaths ${SEG_FILE_RAWAVG}.nii.gz -mas ${SUBSES_GMSEG_PreFix}_rawavg.nii.gz ${SEG_FILE_RAWAVG}_nocereb.nii.gz -odt float

S=`${FSLDIR}/bin/fslstats ${SEG_FILE_RAWAVG}_nocereb.nii.gz -m -v`
xa=`echo $S | awk '{print $1}'`
xb=`echo $S | awk '{print $3}'`
uwhite_wc=`echo "2 k $xa $xb * 1 / p" | dc -`
nwhite_wc=`echo "2 k $xa $xb * $vscale * 1 / p" | dc -`
echo "WHITE w/o Cereb    $nwhite_wc $uwhite_wc" >> ${report_sienax}

#--------------- with cerebellum
S=`${FSLDIR}/bin/fslstats ${SEG_FILE_RAWAVG}.nii.gz -m -v`
xa=`echo $S | awk '{print $1}'`
xb=`echo $S | awk '{print $3}'`
uwhite=`echo "2 k $xa $xb * 1 / p" | dc -`
nwhite=`echo "2 k $xa $xb * $vscale * 1 / p" | dc -`
echo "WHITE              $nwhite $uwhite" >> ${report_sienax}

#----------------------------------------------------------------
# WHOLE BRAIN ---------------------------------------------------
#----------------------------------------------------------------

# ---------------- without cerebellum
ubrain_wc=`echo "2 k $uwhite_wc $ugrey_wc + 1 / p" | dc -`
nbrain_wc=`echo "2 k $nwhite_wc $ngrey_wc + 1 / p" | dc -`
echo "BRAIN w/o Cereb    $nbrain_wc $ubrain_wc" >> ${report_sienax}

# ---------------- without cerebellum
ubrain=`echo "2 k $uwhite $ugrey + 1 / p" | dc -`
nbrain=`echo "2 k $nwhite $ngrey + 1 / p" | dc -`
echo "BRAIN              $nbrain $ubrain" >> ${report_sienax}


echo "=============================="
echo "DONE-DONE-DONE-DONE-DONE-DONE"
echo "ENDS @" $(date)
echo "=============================="
