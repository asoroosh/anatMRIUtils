#!/bin/bash


set -e

#+++++++= What are we going to use, here?
source ${HOME}/NVROXBOX/SOURCE/seg/nvr-ox-tune-path-setup

do_seg=1

ImgTyp=T12D

# ATROPOS SPECIFIC PARAMS

ATROPOSPARAMS="-w 1 -m 3 -n 10 -y 1 -y 2 -y 3"

#++++++++= Subject/Session Information

StudyID=$1
SubID=$2
SesID=$3

OPTAG=$4

if [ -z $OPTAG ]; then
        OPTAG=BETsREG
fi

if [ $OPTAG == "BETsREG" ]; then
        MNI_PriorIntepMethod=Linear
        MNI_AtlasIntepMethod=NearestNeighbor
elif [ $OPTAG == "BETFNIRT" ]; then
        MNI_PriorIntepMethod=Linear
        MNI_AtlasIntepMethod=nn
else
        echo "$OPTAG IS AN UNKNOWN OPTION. "
        exit 1
fi

PriorIntepMethod=Linear
AtlasIntepMethod=NearestNeighbor

#---------------------------------

VoxRes=2

echo "======================================="
echo "STARTED @" $(date)
echo "======================================="
echo ""
echo "============================================================"
echo "============================================================"
echo "** StudyID: ${StudyID}, SubID: ${SubID}, SesID: ${SesID}, ON: ${OPTAG}"
echo "============================================================"
echo "============================================================"


SessionsFileName=${DataDir}/${StudyID}/T12D/Sessions/${StudyID}_sub-${SubID}_${ImgTyp}.txt
echo "Session files: ${SessionsFileName}"
echo "Number of sessions: $(cat ${SessionsFileName} | wc -l)"

# some of the images have two runs {1,2}, but we only take the first run
tmptextsession=session$RANDOM

awk '!/run-2/' ${SessionsFileName} > ${tmptextsession}

echo "Number of sessions: $(cat ${tmptextsession} | wc -l)"

echo "From here: ${UnprocessedPath}"

AA=$(echo "${UnprocessedPath}" | awk -F"/" '{print NF-1}'); AA=$((AA+1))
echo $AA
SesIDList=""
while read SessionPathsFiles
do
#	echo $SessionPathsFiles
	ses_SesID_tmp=$(echo $SessionPathsFiles | awk -F"/" -v xx=$((AA+2)) '{print $xx}')
	echo $ses_SesID_tmp
	SesID_tmp=$(echo $ses_SesID_tmp | awk -F"-" '{print $2}')
	SesIDList="${SesIDList} $SesID_tmp"
	echo ${SesIDList}
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
OpDirSuffix=atropos # Name of the Segmentation operation

SegOrFlg=LIA #Segmentation Orientations
MNIOrientationFlag=LIA #MNI Template Orientation
AtOrFlg=LIA # Atlas Orientation
PrOrFlg=LIA # Prior Orientation

PriorIntepMethod=Linear # prior interpolation method
AtlasIntepMethod=NearestNeighbor # atlas interpolation method


#++++++++= MNI TISSUE PRIORS
MNI_tissuep=${NVSHOME}/NVROXBOX/AUX/tissuepriors/${MNIOrientationFlag}
#+++++++++= MNI TEMPLATE
MNITMP_DIR=${NVSHOME}/NVROXBOX/AUX/MNItemplates/${MNIOrientationFlag}
# head --
MNIImg_RAS=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_${MNIOrientationFlag}
# brain --
MNIImgBrain_RAS=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_brain_${MNIOrientationFlag}
# skull --
MNIImgSkull_RAS=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_skull_${MNIOrientationFlag}

#++++++++= Harvard Oxford Atlas
ATLASMNI_RAS=${NVSHOME}/NVROXBOX/AUX/atlas/GMatlas/${MNIOrientationFlag}/GMatlas_${VoxRes}mm_${MNIOrientationFlag}

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
PVE_Suboutdir=${PRSD_SUBDIR}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_${OpDirSuffix}_${OPTAG}_brain_rawavg_TUNE
TissuePriors=${PVE_Suboutdir}/tissuepriors_sst
AtlasesDir=${PVE_Suboutdir}/atlases
TMPLDir=${PVE_Suboutdir}/templates

if [ $do_seg == 1 ]; then
	rm -rf ${PVE_Suboutdir}
fi

mkdir -p ${TissuePriors}
mkdir -p ${AtlasesDir}
mkdir -p ${TMPLDir}

SEG_LOG=${PVE_Suboutdir}/sub-${SubID}_ses-${SesID}_${OpDirSuffix}_brain_rawavg.log

#++++++++++= IDPs Results
GMPTXTDIRNAME=${PVE_Suboutdir}/IDPs/GMVols
SIENAXDIRNAME=${PVE_Suboutdir}/IDPs/SIENAX

mkdir -p ${GMPTXTDIRNAME}
mkdir -p ${SIENAXDIRNAME}


echo "++++ Sort out the ITK bug ++++"

fslreorient2std ${FreeSurfer_Vol_nuImg}_brain_rawavg.nii.gz ${FreeSurfer_Vol_nuImg}_brain_rawavg.nii.gz
fslreorient2std ${FreeSurfer_Vol_nuImg}_brain_rawavg_mask.nii.gz ${FreeSurfer_Vol_nuImg}_brain_rawavg_mask.nii.gz

echo "+++ Copy headers ++++"

CopyImageHeaderInformation ${FreeSurfer_Vol_nuImg}_brain_rawavg.nii.gz ${FreeSurfer_Vol_nuImg}_brain_rawavg_mask.nii.gz ${FreeSurfer_Vol_nuImg}_brain_rawavg_mask.nii.gz 1 1 1

echo "bug fix done."

#-----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#------------------------------------- Take the priors back into the native space --------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------

#++++++++++= Registration to MNI Results
if [ ${OPTAG} == "BETsREG" ]; then
        RegOutputPrefix=${NonLinSSTDirImg}_MNI-${VoxRes}mm-${OPTAG}-
        NonLinSST_MNI=${RegOutputPrefix}Warped
        NonLinSST_MNI_Warp=${RegOutputPrefix}1Warp
        NonLinSST_MNI_InvWarp=${RegOutputPrefix}1InverseWarp
        NonLinSST_MNI_Affine=${RegOutputPrefix}0GenericAffine
elif [ ${OPTAG} == "BETFNIRT" ]; then
        RegOutputPrefix=${SST_Dir}/${NonLinTempImgName}_MNI-FNIRT-${VoxRes}mm-
        NonLinSST_MNI=${RegOutputPrefix}warped
        NonLinSST_MNI_InvWarp=${RegOutputPrefix}invwarp
        NonLinSST_MNI_Affine=${RegOutputPrefix}affine.mat
else
        echo "${OPTAG} IS UNKNOWN OPTIONS!"
        exit 1
fi


#+++++++++= Registration to NonLinear SST Results
#FreeSurferVol_SubInMedian=${SST_Dir}/sub-${SubID}_ses-${SesID}_nu_2_median_nu
#Sub2NonLinSST_WarpFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nu${SubTag}${v_cnt}1Warp
#Sub2NonLinSST_InvWarpFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nu${SubTag}${v_cnt}1InverseWarp
#Sub2NonLinSST_AffineFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nu${SubTag}${v_cnt}0GenericAffine

#+++++++++= Resampling to the Linear SST Results
LTA_FILE=${SST_Dir}/sub-${SubID}_ses-${SesID}_norm_xforms.lta
INV_LTA_FILE=${SST_Dir}/sub-${SubID}_ses-${SesID}_norm_xforms_inv.lta

FreeSurferVol_SubInMedian=${SST_Dir}/sub-${SubID}_ses-${SesID}_nu_2_median_nu
#nu_template_pathname=${SST_Dir}/sub-${SubID}_norm_nu_median.nii.gz

PriorLabels=1
for TissueType in gray white csf brain
do
	echo "-- Convert the gray matter prior from LAS orientation (FSL) to ${MNIOrientationFlag} orientation (FS)."

	PriorRASMNI=${TissuePriors}/avg152T1_${TissueType}_${PrOrFlg}_${OPTAG}

	mri_convert --in_orientation LAS --out_orientation ${MNIOrientationFlag} ${MNI_tissuep}/avg152T1_${TissueType}.nii.gz ${PriorRASMNI}.nii.gz

	NLSSTPriorPreFix=${TissuePriors}/sub-${SubID}_avg152T1_${TissueType}_${PrOrFlg}_${OPTAG}
	SUBSESPriorPreFix=${TissuePriors}/sub-${SubID}_ses-${SesID}_avg152T1_${TissueType}_${PrOrFlg}_${OPTAG}

	# From MNI to Nonlinear SST
	echo "######## Take the priors from MNI into the Nonlinear SST, use inwarp (ants)"
	echo "-- Moving image: ${PriorRASMNI}.nii.gz"
	echo "-- Reference Image: ${NonLinSSTDirImg}.nii.gz"
	echo "-- Inverse Warp: ${NonLinSST_MNI_InvWarp}.nii.gz"
	echo "-- Affine: ${NonLinSST_MNI_Affine}.mat"
	echo "########"
	echo " "

#antsApplyTransforms \
#-d 3 \
#-i ${PriorRASMNI}.nii.gz \
#-r ${NonLinSSTDirImg}.nii.gz \
#-t [${NonLinSST_MNI_Affine}.mat, 1] \
#-t ${NonLinSST_MNI_InvWarp}.nii.gz \
#-n ${PriorIntepMethod} \
#-o ${NLSSTPriorPreFix}_NonLinearSST.nii.gz

if [ ${OPTAG} == "BETsREG" ]; then

antsApplyTransforms \
-d 3 \
-i ${PriorRASMNI}.nii.gz \
-r ${NonLinSSTDirImg}.nii.gz \
-t [${NonLinSST_MNI_Affine}.mat, 1] \
-t ${NonLinSST_MNI_InvWarp}.nii.gz \
-n ${MNI_PriorIntepMethod} \
-o ${NLSSTPriorPreFix}_NonLinearSST.nii.gz

elif [ ${OPTAG} == "BETFNIRT" ]; then

${FSLDIR}/bin/applywarp \
--in=${PriorRASMNI}.nii.gz \
--ref=${NonLinSSTDirImg}.nii.gz \
-w ${NonLinSST_MNI_InvWarp}.nii.gz \
-o ${NLSSTPriorPreFix}_NonLinearSST.nii.gz

else
        echo "${OPTAG} IS UNKNOWN OPTIONS!"
        exit 1
fi


# change this from FAST/FSL naming convention into ANTs Atropos naming convention
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
--o ${SUBSESPriorPreFix}_nu.nii.gz

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
--no-save-reg

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
echo "++CSF prior: ${TissuePriors}/avg152T1_csf_ses-${SesID}_RAS2LAS_rawavg.nii.gz"
echo "++Results: ${PVE_Suboutdir}"
#echo "==================================================================================="

SegOutPrefix=${PVE_Suboutdir}/sub-${SubID}_ses-${SesID}_${OpDirSuffix}_${OPTAG}_brain_rawavg_
AllSegFile=${SegOutPrefix}Segmentation

if [ $do_seg == 1 ]; then


	echo "" > $SEG_LOG

#	CopyImageHeaderInformation ${FreeSurfer_Vol_nuImg}_brain_rawavg.nii.gz ${FreeSurfer_Vol_nuImg}_brain_rawavg_mask.nii.gz ${FreeSurfer_Vol_nuImg}_brain_rawavg_mask.nii.gz

	antsAtroposN4.sh -d 3 \
	-a ${FreeSurfer_Vol_nuImg}_brain_rawavg.nii.gz \
	-x ${FreeSurfer_Vol_nuImg}_brain_rawavg_mask.nii.gz \
	-p "${TissuePriors}/sub-${SubID}_ses-${SesID}_avg152T1_%02d_${PrOrFlg}_${OPTAG}_rawavg.nii.gz" \
	-c 3 \
        ${ATROPOSPARAMS} \
	-g 1 \
	-o ${SegOutPrefix} >> ${SEG_LOG}

	echo "Break the segmentation file..."

	# CSF (1)
	${FSLDIR}/bin/fslmaths ${AllSegFile}.nii.gz -uthr 1.5 -thr 0.5 ${AllSegFile}Seg01.nii.gz
	# Gray Matter (2)
	${FSLDIR}/bin/fslmaths ${AllSegFile}.nii.gz -uthr 2.5 -thr 1.5 ${AllSegFile}Seg02.nii.gz
	#White Matter (3)
	${FSLDIR}/bin/fslmaths ${AllSegFile}.nii.gz -uthr 3.5 -thr 2.5 ${AllSegFile}Seg03.nii.gz

else
	echo "##### I WONT RUN SEGMENTATION"
fi

#-----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#----------------------------Take everything back into the MNI space now------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------

FS_InterpolationMethod_List=("" "--nearest")
InterpolationMethod_List=("Linear" "NearestNeighbor")
AtroposOutputFiletype_List=("Posteriors" "Seg")


#
#for filetype_cnt in 0 1 # move Posteriors and Seg files around
#do
#        InterpMeth=${InterpolationMethod_List[$filetype_cnt]}
#        segfiletype=${AtroposOutputFiletype_List[$filetype_cnt]}
#	FSInterpMeth=${FS_InterpolationMethod_List[$filetype_cnt]}
#
#        echo "-----------------------------------------"
#        echo "Segmentation File: ${segfiletype}"
#        echo "Interpolation Method: ${InterpMeth}"
#	echo "Interpolation Method for mri_vol2vol: ${FSInterpMeth}"
#        echo "-----------------------------------------"
#
#        for tissue_cnt in 1 2 3 # loop around the $OpDirSuffix output tissues; of course for -n 3 ;; CSF: 1, GM: 2, WM: 3
#        do
#
#		SegTisFile=${AllSegFile}${segfiletype}0${tissue_cnt}
#
#               echo "#### Native Subj Space >> FS 1x1x1 256^3 ---- Tissue Count: ${tissue_cnt}, Segmentation File: ${segfiletype}, Interpolation Metho: ${InterpMeth}"
#		echo "-- Moving Image: ${SegTisFile}.nii.gz"
#		echo "-- Reference Image: ${FreeSurfer_Vol_nuImg}_brain.nii.gz"
#		echo "####"
#		echo " "
#mri_vol2vol \
#--mov ${SegTisFile}.nii.gz \
#--targ ${FreeSurfer_Vol_nuImg}_brain.nii.gz \
#--regheader \
#--o ${SegTisFile}_nu_brain.nii.gz --no-save-reg \
#${FSInterpMeth} >> /dev/null 2>&1
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
#${FSInterpMeth} >> /dev/null 2>&1
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

#                echo "#### Non Linear SST >> MNI Space (RAS)  ---- Tissue Count: ${tissue_cnt}, Segmentation File: ${segfiletype}, Interpolation Method: ${InterpMeth}"
#		echo "-- Moving Image: ${SegTisFile}_NonLinearSST.nii.gz"
#		echo "-- Reference Image: ${MNIImgBrain_RAS}.nii.gz"
#		echo "-- FWD Warp: ${NonLinSST_MNI_Warp}.nii.gz"
#		echo "-- Affine: ${NonLinSST_MNI_Affine}.mat"
#		echo "-- Intepolation Method: ${InterpMeth}"
#		echo "####"
#		echo " "
#
#               #Take me from NonLinear SST to the MNI
#antsApplyTransforms -d 3 \
#-i ${SegTisFile}_NonLinearSST.nii.gz \
#-r ${MNIImgBrain_RAS}.nii.gz \
#-t ${NonLinSST_MNI_Affine}.mat \
#-t ${NonLinSST_MNI_Warp}.nii.gz \
#-n ${InterpMeth} \
#-o ${SegTisFile}_MNI.nii.gz
#
#	done
#done

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
echo "-- Moving image: ${ATLASMNI_RAS}.nii.gz"
echo "-- Reference Image: ${NonLinSSTDirImg}.nii.gz"
echo "-- Inverse Warp: ${NonLinSST_MNI_InvWarp}.nii.gz"
echo "-- Affine: ${NonLinSST_MNI_Affine}.mat"
echo "########"
echo " "

#antsApplyTransforms \
#-d 3 \
#-i ${ATLASMNI_RAS}.nii.gz \
#-r ${NonLinSSTDirImg}.nii.gz \
#-t [${NonLinSST_MNI_Affine}.mat, 1] \
#-t ${NonLinSST_MNI_InvWarp}.nii.gz \
#-n ${AtlasIntepMethod} \
#-o ${NLSSTAtlasPreFix}_NonLinearSST.nii.gz

if [ ${OPTAG} == "BETsREG" ]; then

antsApplyTransforms \
-d 3 \
-i ${ATLASMNI_RAS}.nii.gz \
-r ${NonLinSSTDirImg}.nii.gz \
-t [${NonLinSST_MNI_Affine}.mat, 1] \
-t ${NonLinSST_MNI_InvWarp}.nii.gz \
-n ${MNI_AtlasIntepMethod} \
-o ${NLSSTAtlasPreFix}_NonLinearSST.nii.gz

elif [ ${OPTAG} == "BETFNIRT" ]; then

${FSLDIR}/bin/applywarp \
--in=${ATLASMNI_RAS}.nii.gz \
--ref=${NonLinSSTDirImg}.nii.gz \
--interp=${MNI_AtlasIntepMethod} \
-w ${NonLinSST_MNI_InvWarp}.nii.gz \
-o ${NLSSTAtlasPreFix}_NonLinearSST.nii.gz

else
        echo "${OPTAG} IS UNKNOWN OPTIONS!"
        exit 1
fi

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
#-----------------------------------------------------------------------------------------------------------------------
#------------------------------------------------- APPLY ATLAS ON THE SEGs ---------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------

GMSegTisFile=${AllSegFile}Posteriors02

GMPTXTFILENAME=${GMPTXTDIRNAME}/sub-${SubID}_ses-${SesID}_${OPTAG}_UKB-GMAtlas_GMVols

#----------------------------------------------------------------
#-------------- On the rawavg -----------------------------------
#----------------------------------------------------------------

echo ""
echo "#### Apply rawavg atlas on rawavg gray matter:"
echo "-- Atlas: ${SUBSESAtlasPreFix}_rawavg.nii.gz"
echo "-- PVE: ${GMSegTisFile}.nii.gz"
echo "-- Results: ${GMPTXTFILENAME}_rawavg.txt"
echo ""

echo "" > ${GMPTXTFILENAME}_rawavg.txt

${FSLDIR}/bin/fslstats -K ${SUBSESAtlasPreFix}_rawavg.nii.gz \
${GMSegTisFile}.nii.gz -m -v | xargs -n 3 | awk '{print "("$1"*"$2")"}' | bc >> ${GMPTXTFILENAME}_rawavg.txt

#----------------------------------------------------------------
#-------------- On the nu ---------------------------------------
#----------------------------------------------------------------
#
#echo ""
#echo "#### Apply nu atlas on nu gray matter:"
#echo "-- Atlas: ${SUBSESAtlasPreFix}_nu.nii.gz"
#echo "-- PVE: ${GMSegTisFile}_nu_brain.nii.gz"
#echo "-- Results: ${GMPTXTFILENAME}_nu.txt"
#echo ""
#
#echo "" > ${GMPTXTFILENAME}_nu.txt
#
#${FSLDIR}/bin/fslstats -K ${SUBSESAtlasPreFix}_nu.nii.gz \
#${GMSegTisFile}_nu_brain.nii.gz -m -v | xargs -n 3 | awk '{print "("$1"*"$2")"}' | bc >> ${GMPTXTFILENAME}_nu.txt
#
#----------------------------------------------------------------
#-------------- On the Linear SST -------------------------------
#----------------------------------------------------------------
#
#echo ""
#echo "#### Apply Linear SST atlas on Linear SST gray matter:"
#echo "-- Atlas: ${SUBSESAtlasPreFix}_LinearSST.nii.gz"
#echo "-- PVE: ${GMSegTisFile}_LinearSST.nii.gz"
#echo "-- Results: ${GMPTXTFILENAME}_LinearSST.txt"
#echo ""
#
#echo "" > ${GMPTXTFILENAME}_LinearSST.txt
#
#${FSLDIR}/bin/fslstats -K ${SUBSESAtlasPreFix}_LinearSST.nii.gz \
#${GMSegTisFile}_LinearSST.nii.gz -m -v | xargs -n 3 | awk '{print "("$1"*"$2")"}' | bc >> ${GMPTXTFILENAME}_LinearSST.txt
#
#----------------------------------------------------------------
#-------------- On the NonLinear SST ----------------------------
#----------------------------------------------------------------
#
#echo ""
#echo "#### Apply NonLinear SST atlas on NonLinear SST gray matter:"
#echo "-- Atlas: ${NLSSTAtlasPreFix}_NonLinearSST.nii.gz"
#echo "-- PVE: ${GMSegTisFile}_NonLinearSST.nii.gz"
#echo "-- Results: ${GMPTXTFILENAME}_NonLinearSST.txt"
#echo ""
#
#echo "" > ${GMPTXTFILENAME}_NonLinearSST.txt
#
#${FSLDIR}/bin/fslstats -K ${NLSSTAtlasPreFix}_NonLinearSST.nii.gz \
#${GMSegTisFile}_NonLinearSST.nii.gz -m -v | xargs -n 3 | awk '{print "("$1"*"$2")"}' | bc >> ${GMPTXTFILENAME}_NonLinearSST.txt
#
#----------------------------------------------------------------
#-------------- On the MNI --------------------------------------
#----------------------------------------------------------------
#
#echo ""
#echo "#### Apply MNI atlas on MNI gray matter:"
#echo "-- Atlas: ${ATLASMNI_RAS}.nii.gz"
#echo "-- PVE: ${GMSegTisFile}_MNI.nii.gz"
#echo "-- Results: ${GMPTXTFILENAME}_MNI.txt"
#echo ""
#
#echo "" > ${GMPTXTFILENAME}_MNI.txt
#
#${FSLDIR}/bin/fslstats -K ${ATLASMNI_RAS}.nii.gz \
#${GMSegTisFile}_MNI.nii.gz -m -v | xargs -n 3 | awk '{print "("$1"*"$2")"}' | bc >> ${GMPTXTFILENAME}_MNI.txt

#-----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#------------------------------------------------- SIENAX ON THE SEGs --------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------


echo ""
echo "#################################################"
echo "SIENAX ##########################################"
echo "#################################################"

SIENAXFILENAME=${SIENAXDIRNAME}/sub-${SubID}_ses-${SesID}_${OPTAG}_Sienax

T12MNIlinear_RAS=${SIENAXFILENAME}_T12MNI_${MNIOrientationFlag}
report_sienax=${SIENAXFILENAME}_Report

GMSEG_MNI=${MNITMP_DIR}/MNI152_T1_2mm_strucseg_${MNIOrientationFlag}_NoCereb_bin
NLSST_GMSEG_PreFix=${TMPLDir}/sub-${SubID}_${AtOrFlg}_${OPTAG}_strucseg_nocereb
SUBSES_GMSEG_PreFix=${TMPLDir}/sub-${SubID}_ses-${SesID}_${AtOrFlg}_${OPTAG}_strucseg_nocereb

SEGPRIPH_MNI=${MNITMP_DIR}/MNI152_T1_2mm_strucseg_periph_${MNIOrientationFlag}
SEGVENT_MNI=${MNITMP_DIR}/MNI152_T1_2mm_strucseg_${MNIOrientationFlag}_Vent

NLSST_PRIPHSEG_PreFix=${TMPLDir}/sub-${SubID}_${AtOrFlg}_${OPTAG}_strucseg_periph
SUBSES_PRIPHSEG_PreFix=${TMPLDir}/sub-${SubID}_ses-${SesID}_${AtOrFlg}_${OPTAG}_strucseg_periph

NLSST_VENTSEG_PreFix=${TMPLDir}/sub-${SubID}_${AtOrFlg}_${OPTAG}_strucseg_vent
SUBSES_VENTSEG_PreFix=${TMPLDir}/sub-${SubID}_ses-${SesID}_${AtOrFlg}_${OPTAG}_strucseg_vent

#----------------------------------------------------------------
#------------------------------ AVSCALE -------------------------
#----------------------------------------------------------------

echo "########### Calculate the Linear Transformation (rawavg >> MNI) using FSL parreg:"

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
#------------------- TAKE PRIPH SEG MNI > AVGRAW ----------------
#----------------------------------------------------------------

echo "############# Take the SEG PRIPH from MNI to RAWAVG:" 

#antsApplyTransforms \
#-d 3 \
#-i ${SEGPRIPH_MNI}.nii.gz \
#-r ${NonLinSSTDirImg}.nii.gz \
#-t [${NonLinSST_MNI_Affine}.mat, 1] \
#-t ${NonLinSST_MNI_InvWarp}.nii.gz \
#-n ${AtlasIntepMethod} \
#-o ${NLSST_PRIPHSEG_PreFix}_NonLinearSST.nii.gz


if [ ${OPTAG} == "BETsREG" ]; then

antsApplyTransforms \
-d 3 \
-i ${SEGPRIPH_MNI}.nii.gz \
-r ${NonLinSSTDirImg}.nii.gz \
-t [${NonLinSST_MNI_Affine}.mat, 1] \
-t ${NonLinSST_MNI_InvWarp}.nii.gz \
-n ${MNI_AtlasIntepMethod} \
-o ${NLSST_PRIPHSEG_PreFix}_NonLinearSST.nii.gz

elif [ ${OPTAG} == "BETFNIRT" ]; then

${FSLDIR}/bin/applywarp \
--in=${SEGPRIPH_MNI}.nii.gz \
--ref=${NonLinSSTDirImg}.nii.gz \
--interp=${MNI_AtlasIntepMethod} \
-w ${NonLinSST_MNI_InvWarp}.nii.gz \
-o ${NLSST_PRIPHSEG_PreFix}_NonLinearSST.nii.gz

else
        echo "${OPTAG} IS UNKNOWN OPTIONS!"
        exit 1
fi


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
#------------------- TAKE VENT SEG MNI > AVGRAW ----------------
#----------------------------------------------------------------


echo "############# Take the SEG VENT from MNI to RAWAVG:" 

#antsApplyTransforms \
#-d 3 \
#-i ${SEGVENT_MNI}.nii.gz \
#-r ${NonLinSSTDirImg}.nii.gz \
#-t [${NonLinSST_MNI_Affine}.mat, 1] \
#-t ${NonLinSST_MNI_InvWarp}.nii.gz \
#-n ${AtlasIntepMethod} \
#-o ${NLSST_VENTSEG_PreFix}_NonLinearSST.nii.gz

if [ ${OPTAG} == "BETsREG" ]; then

antsApplyTransforms \
-d 3 \
-i ${SEGVENT_MNI}.nii.gz \
-r ${NonLinSSTDirImg}.nii.gz \
-t [${NonLinSST_MNI_Affine}.mat, 1] \
-t ${NonLinSST_MNI_InvWarp}.nii.gz \
-n ${MNI_AtlasIntepMethod} \
-o ${NLSST_VENTSEG_PreFix}_NonLinearSST.nii.gz

elif [ ${OPTAG} == "BETFNIRT" ]; then

${FSLDIR}/bin/applywarp \
--in=${SEGVENT_MNI}.nii.gz \
--ref=${NonLinSSTDirImg}.nii.gz \
--interp=${MNI_AtlasIntepMethod} \
-w ${NonLinSST_MNI_InvWarp}.nii.gz \
-o ${NLSST_VENTSEG_PreFix}_NonLinearSST.nii.gz

else
        echo "${OPTAG} IS UNKNOWN OPTIONS!"
        exit 1
fi

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

echo "############# Take the SEG VENT from MNI to RAWAVG:" 

#antsApplyTransforms \
#-d 3 \
#-i ${GMSEG_MNI}.nii.gz \
#-r ${NonLinSSTDirImg}.nii.gz \
#-t [${NonLinSST_MNI_Affine}.mat, 1] \
#-t ${NonLinSST_MNI_InvWarp}.nii.gz \
#-n ${AtlasIntepMethod} \
#-o ${NLSST_GMSEG_PreFix}_NonLinearSST.nii.gz

if [ ${OPTAG} == "BETsREG" ]; then

antsApplyTransforms \
-d 3 \
-i ${GMSEG_MNI}.nii.gz \
-r ${NonLinSSTDirImg}.nii.gz \
-t [${NonLinSST_MNI_Affine}.mat, 1] \
-t ${NonLinSST_MNI_InvWarp}.nii.gz \
-n ${MNI_AtlasIntepMethod} \
-o ${NLSST_GMSEG_PreFix}_NonLinearSST.nii.gz

elif [ ${OPTAG} == "BETFNIRT" ]; then

${FSLDIR}/bin/applywarp \
--in=${GMSEG_MNI}.nii.gz \
--ref=${NonLinSSTDirImg}.nii.gz \
--interp=${MNI_AtlasIntepMethod} \
-w ${NonLinSST_MNI_InvWarp}.nii.gz \
-o ${NLSST_GMSEG_PreFix}_NonLinearSST.nii.gz

else
        echo "${OPTAG} IS UNKNOWN OPTIONS!"
        exit 1
fi

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
tissue_cnt=2 #CSF: 1, GM: 2, WM: 3
SEG_FILE_RAWAVG=${AllSegFile}${segfiletype}0${tissue_cnt}

# mask the pve with priph in native space
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
tissue_cnt=1 #CSF: 1, GM: 2, WM: 3
SEG_FILE_RAWAVG=${AllSegFile}${segfiletype}0${tissue_cnt}
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
tissue_cnt=2 #CSF: 1, GM: 2, WM: 3
SEG_FILE_RAWAVG=${AllSegFile}${segfiletype}0${tissue_cnt}

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
tissue_cnt=3 #CSF: 1, GM: 2, WM: 3
SEG_FILE_RAWAVG=${AllSegFile}${segfiletype}0${tissue_cnt}

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

# ---------------- without cerebellum

echo "=============================="
echo "DONE-DONE-DONE-DONE-DONE-DONE"
echo "ENDS @" $(date)
echo "=============================="
