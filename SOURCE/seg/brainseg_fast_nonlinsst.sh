set -e

#+++++++= What are we going to use, here?
module load freesurfer
module load ANTs
module load fsl

do_seg=1

#--------- SubID, StudyID, info from ANTs SST -----------------------------------------
# comes from the user:
#StudyID=CFTY720D2324
#SubID=CFTY720D2324.0217.00001
#SubTag=sub-${StudyID} #this is what the antsMultivariateTemplate uses

StudyID=$1
SubID=$2

echo "StudyID: ${StudyID}, SubID: ${SubID}"

NonLinTempImgName=sub-${SubID}_ants_temp_med_nutemplate0

#--------------------------------------------------------------------

VoxRes=2
DataDir=/well/nvs-mri-temp/data/ms/processed/MetaData
SessionsFileName=${DataDir}/${StudyID}/T12D/Sessions/${StudyID}_sub-${SubID}_T12D.txt
while read SessionPathsFiles
do
	ses_SesID_tmp=$(echo $SessionPathsFiles | awk -F"/" '{print $9}')
	SesID_tmp=$(echo $ses_SesID_tmp | awk -F"-" '{print $2}')
	SesIDList="${SesIDList} $SesID_tmp"
	echo ${SesIDList}
done<${SessionsFileName}

echo ${SesIDList}

SesIDList=(${SesIDList})
NumSes=${#SesIDList[@]}

echo "# of sessions available: ${NumSes}"

#-----------------------------------------------
OpDirSuffix=fast # Name of the Segmentation operation

SegOrFlg=LIA #Segmentation Orientations
MNIOrientationFlag=LIA #MNI Template Orientation
AtOrFlg=LIA # Atlas Orientation
PrOrFlg=LIA # Prior Orientation

PriorIntepMethod=Linear # prior interpolation method
AtlasIntepMethod=NearestNeighbor # atlas interpolation method

NVSHOME=/well/nvs-mri-temp/users/scf915
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

# strucseg priph/vent
GMSEG_MNI=${MNITMP_DIR}/MNI152_T1_2mm_strucseg_${MNIOrientationFlag}_NoCereb_bin
SEGPRIPH_MNI=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_strucseg_periph_${MNIOrientationFlag}
SEGVENT_MNI=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_strucseg_${MNIOrientationFlag}_Vent

NVSHOME=/well/nvs-mri-temp/users/scf915
#++++++++= Harvard Oxford Atlas
ATLASMNI_RAS=${NVSHOME}/NVROXBOX/AUX/atlas/GMatlas/${MNIOrientationFlag}/GMatlas_${VoxRes}mm_${MNIOrientationFlag}

#--------------------------------------------------------------------------------------
ImgTyp=T12D
XSectionalDirSuffix=autorecon12ws
LogitudinalDirSuffix=nuws_mrirobusttemplate
# ------

#------------= Main paths
PRSD_DIR="/well/nvs-mri-temp/data/ms/processed"
PRSD_SUBDIR=${PRSD_DIR}/${StudyID}/sub-${SubID}

#-------------= X Sectional paths
SST_Dir=${PRSD_SUBDIR}/${ImgTyp}.${XSectionalDirSuffix}.${LogitudinalDirSuffix}

#--------------= Unprocessed paths
UPRSD_DIR="/well/nvs-mri-temp/data/ms/unprocessed"
UnprocessedDir=${UPRSD_DIR}/${StudyID}

#+++++++++++++++++++++++++++++++++++++= PROCESSED DATA ++++

NonLinSSTDirImg=${SST_Dir}/${NonLinTempImgName}
NonLinSSTDirImg_brain=${SST_Dir}/${NonLinTempImgName}_brain

#+++++++++= Seg RESULTS
PVE_SSToutDir=${PRSD_SUBDIR}/sub-${SubID}_${OpDirSuffix}_brain_NonLinearSST
TissuePriors=${PVE_SSToutDir}/tissuepriors_sst
AtlasesDir=${PVE_SSToutDir}/atlases
TMPLDir=${PVE_SSToutDir}/templates

if [ $do_seg == 1 ]; then
	rm -rf ${PVE_SSToutDir}
fi

mkdir -p ${TissuePriors}
mkdir -p ${AtlasesDir}
mkdir -p ${TMPLDir}

SEG_LOG=${PVE_SSToutDir}/sub-${SubID}_${OpDirSuffix}_brain_NonLinearSST.log

#++++++++++= IDPs Results
GMPTXTDIRNAME=${PVE_SSToutDir}/IDPs/GMVols
SIENAXDIRNAME=${PVE_SSToutDir}/IDPs/SIENAX

mkdir -p ${GMPTXTDIRNAME}
mkdir -p ${SIENAXDIRNAME}

#-----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#------------------------------------- Take the priors back into the native space --------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------

#++++++++++= Registration to MNI Results
antsRegOutputPrefix=${NonLinSSTDirImg}_MNI-${VoxRes}mm-
NonLinSST_MNI=${antsRegOutputPrefix}Warped
NonLinSST_MNI_Warp=${antsRegOutputPrefix}1Warp
NonLinSST_MNI_InvWarp=${antsRegOutputPrefix}1InverseWarp
NonLinSST_MNI_Affine=${antsRegOutputPrefix}0GenericAffine

PriorLabels=1
for TissueType in gray white csf brain
do
	echo "-- Convert the gray matter prior from LAS orientation (FSL) to ${MNIOrientationFlag} orientation (FS)."
	mri_convert --in_orientation LAS --out_orientation ${MNIOrientationFlag} ${MNI_tissuep}/avg152T1_${TissueType}.nii.gz ${TissuePriors}/avg152T1_${TissueType}_${PrOrFlg}.nii.gz

	PriorRASMNI=${TissuePriors}/avg152T1_${TissueType}_${PrOrFlg}
	NLSSTPriorPreFix=${TissuePriors}/sub-${SubID}_avg152T1_${TissueType}_${PrOrFlg}

	# From MNI to Nonlinear SST
	echo "######## Take the priors from MNI into the Nonlinear SST, use inwarp (ants)"
	echo "-- Moving image: ${PriorRASMNI}.nii.gz"
	echo "-- Reference Image: ${NonLinSSTDirImg}.nii.gz"
	echo "-- Inverse Warp: ${NonLinSST_MNI_InvWarp}.nii.gz"
	echo "-- Affine: ${NonLinSST_MNI_Affine}.mat"
	echo "########"
	echo " "

	antsApplyTransforms \
	-d 3 \
	-i ${PriorRASMNI}.nii.gz \
	-r ${NonLinSSTDirImg}.nii.gz \
	-t [${NonLinSST_MNI_Affine}.mat, 1] \
	-t ${NonLinSST_MNI_InvWarp}.nii.gz \
	-n ${PriorIntepMethod} \
	-o ${NLSSTPriorPreFix}_NonLinearSST.nii.gz

	# change this from FAST/FSL naming convention into ANTs Atropos naming convention
	cp ${NLSSTPriorPreFix}_NonLinearSST.nii.gz \
	${TissuePriors}/sub-${SubID}_avg152T1_${PriorLabels}_${PrOrFlg}_NonLinearSST.nii.gz

        PriorLabels=$((($PriorLabels+1)))
done

#--------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------
#----------------------------------------------- Run segmentations --------------------------------------
#--------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------

echo "==================================================================================="
echo "********* Running ${OpDirSuffix} on: ********"
echo "++Input Image: ${NonLinSSTDirImg}_brain.nii.gz"
echo "++Priors: "
echo "${TissuePriors}/sub-${SubID}_avg152T1_*_${PrOrFlg}_NonLinearSST.nii.gz"
echo "++Results: ${PVE_SSToutDir}"
echo "++Mask: ${SST_Dir}/sub-${SubID}_NonLinearSST_BrainMask.nii.gz"
echo "==================================================================================="

SegOutPrefix=${PVE_SSToutDir}/sub-${SubID}_${OpDirSuffix}_brain_NonLinearSST
NonLinSSTAllSegFile=${SegOutPrefix}_

if [ $do_seg == 1 ]; then

	echo " " > ${SEG_LOG}


	${FSLDIR}/bin/fast -n 3 \
	-A ${SSTTissuePriors}/sub-${SubID}_avg152T1_gray_${PrOrFlg}_NonLinearSST.nii.gz \
	${SSTTissuePriors}/sub-${SubID}_avg152T1_white_${PrOrFlg}_NonLinearSST.nii.gz \
	${SSTTissuePriors}/sub-${SubID}_avg152T1_csf_${PrOrFlg}_NonLinearSST.nii.gz \
	-I 4 \
	-p \
	-b \
	-B \
	-g \
	-v \
	-o ${SegOutPrefix} \
	${NonLinSSTDirImg}_brain.nii.gz >> ${SEG_LOG}

else
	echo "##### I WONT RUN SEGMENTATION"
fi

#-----------------------------------------------------------------------------------------------------------------------
#----------------------------Take everything into MNI or into Linear SST -----------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------

InterpolationMethod_List=("Linear" "NearestNeighbor")
OutputFiletype_List=("pve" "seg")

#for filetype_cnt in 0 1 # move Posteriors and Seg files around
#do
#        InterpMeth=${InterpolationMethod_List[$filetype_cnt]}
#        segfiletype=${OutputFiletype_List[$filetype_cnt]}
#
#        echo "-----------------------------------------"
#        echo "Segmentation File: ${segfiletype}"
#        echo "Interpolation Method: ${InterpMeth}"
#        echo "-----------------------------------------"
#
#        for tissue_cnt in 0 1 2 # loop around the $OpDirSuffix output tissues; of course for -n 3 ;; CSF: 0, GM: 1, WM: 2
#        do
#		NLSST_SegTisFile=${NonLinSSTAllSegFile}${segfiletype}_${tissue_cnt}
#
#                echo "#### Non Linear SST >> MNI Space (${MNIOrientationFlag})  ---- Tissue Count: ${tissue_cnt}, Segmentation File: ${segfiletype}, Interpolation Method: ${InterpMeth}"
#		echo "-- Moving Image: ${NLSST_SegTisFile}.nii.gz"
#		echo "-- Reference Image: ${MNIImgBrain_RAS}.nii.gz"
#		echo "-- FWD Warp: ${NonLinSST_MNI_Warp}.nii.gz"
#		echo "-- Affine: ${NonLinSST_MNI_Affine}.mat"
#		echo "-- Intepolation Method: ${InterpMeth}"
#		echo "####"
#		echo " "
#
#               #Take me from NonLinear SST to the MNI
#		antsApplyTransforms -d 3 \
#		-i ${NLSST_SegTisFile}.nii.gz \
#		-r ${MNIImgBrain_RAS}.nii.gz \
#		-t ${NonLinSST_MNI_Affine}.mat \
#		-t ${NonLinSST_MNI_Warp}.nii.gz \
#		-n ${InterpMeth} \
#		-o ${NLSST_SegTisFile}_MNI.nii.gz
#
#	done
#done


#--------------------------------- TAKE  THE ATLAS INTO THE NON-LINEAR SST -------------------------------------------------

NLSSTAtlasPreFix=${AtlasesDir}/sub-${SubID}_${AtOrFlg}_UKB-GMAtlas
echo "######## Take the ATLAS from MNI into the Nonlinear SST, use inwarp (ants)"
echo "-- Moving image: ${ATLASMNI_RAS}.nii.gz"
echo "-- Reference Image: ${NonLinSSTDirImg}.nii.gz"
echo "-- Inverse Warp: ${NonLinSST_MNI_InvWarp}.nii.gz"
echo "-- Affine: ${NonLinSST_MNI_Affine}.mat"
echo "########"
echo " "

antsApplyTransforms \
-d 3 \
-i ${ATLASMNI_RAS}.nii.gz \
-r ${NonLinSSTDirImg}.nii.gz \
-t [${NonLinSST_MNI_Affine}.mat, 1] \
-t ${NonLinSST_MNI_InvWarp}.nii.gz \
-n ${AtlasIntepMethod} \
-o ${NLSSTAtlasPreFix}_NonLinearSST.nii.gz


#--------------------------------- TAKE THE BRAIN MASKS INTO THE NON-LINEAR SST --------------------------------------------
#---------------------------------
#---------------------------------

NLSST_GMSEG_PreFix=${TMPLDir}/sub-${SubID}_${AtOrFlg}_strucseg_nocereb
NLSST_PRIPHSEG_PreFix=${TMPLDir}/sub-${SubID}_${AtOrFlg}_strucseg_periph
NLSST_VENTSEG_PreFix=${TMPLDir}/sub-${SubID}_${AtOrFlg}_strucseg_vent

echo "#GM PRIPH SEG-----------------------------"
antsApplyTransforms \
-d 3 \
-i ${SEGPRIPH_MNI}.nii.gz \
-r ${NonLinSSTDirImg}.nii.gz \
-t [${NonLinSST_MNI_Affine}.mat, 1] \
-t ${NonLinSST_MNI_InvWarp}.nii.gz \
-n ${AtlasIntepMethod} \
-o ${NLSST_PRIPHSEG_PreFix}_NonLinearSST.nii.gz

echo "# VENTSEG -----------------------------"
antsApplyTransforms \
-d 3 \
-i ${SEGVENT_MNI}.nii.gz \
-r ${NonLinSSTDirImg}.nii.gz \
-t [${NonLinSST_MNI_Affine}.mat, 1] \
-t ${NonLinSST_MNI_InvWarp}.nii.gz \
-n ${AtlasIntepMethod} \
-o ${NLSST_VENTSEG_PreFix}_NonLinearSST.nii.gz

echo "#GMSEG -----------------------------"
antsApplyTransforms \
-d 3 \
-i ${GMSEG_MNI}.nii.gz \
-r ${NonLinSSTDirImg}.nii.gz \
-t [${NonLinSST_MNI_Affine}.mat, 1] \
-t ${NonLinSST_MNI_InvWarp}.nii.gz \
-n ${AtlasIntepMethod} \
-o ${NLSST_GMSEG_PreFix}_NonLinearSST.nii.gz


v_cnt=0
for SesID in ${SesIDList[@]}
do
#	SesID=${SesIDList[$v_cnt]}

echo " "
echo "                ========================================================================"
echo "We are on Study ${StudyID}, Subject ${SubID}, Session ${SesID}, Session count ${v_cnt}. "
echo "                ========================================================================"

	FreeSurfer_Dir=${PRSD_SUBDIR}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_run-1_T1w.${XSectionalDirSuffix}
	FreeSurfer_Vol_Dir=${FreeSurfer_Dir}/sub-${SubID}_ses-${SesID}_run-1_T1w/mri
	FreeSurfer_Vol_nuImg=${FreeSurfer_Vol_Dir}/nu

	FreeSurferVol_SubInMedian=${SST_Dir}/sub-${SubID}_ses-${SesID}_nu_2_median_nu

	Sub2NonLinSST_InvWarpFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nusub-${SubID}_ses-${SesID}_nu_2_median_nu${v_cnt}1InverseWarp
	Sub2NonLinSST_AffineFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nusub-${SubID}_ses-${SesID}_nu_2_median_nu${v_cnt}0GenericAffine
	Sub2NonLinSST_WarpFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nusub-${SubID}_ses-${SesID}_nu_2_median_nu${v_cnt}1Warp

#	Sub2NonLinSST_WarpFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nu${SubTag}${v_cnt}1Warp
#	Sub2NonLinSST_InvWarpFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nu${SubTag}${v_cnt}1InverseWarp
#	Sub2NonLinSST_AffineFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nu${SubTag}${v_cnt}0GenericAffine

	#-----------------------------------------------------------------------------------------------------------------------
	# Take Segmentation files from Nonlinear SST >> Linear SST -------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------------------------------

	for filetype_cnt in 0 1 # move pve and seg files around
	do
        	InterpMeth=${InterpolationMethod_List[$filetype_cnt]}
        	segfiletype=${OutputFiletype_List[$filetype_cnt]}

        	echo "-----------------------------------------"
        	echo "Segmentation File: ${segfiletype}"
        	echo "Interpolation Method: ${InterpMeth}"
        	echo "-----------------------------------------"

        	for tissue_cnt in 0 1 2 # loop around the $OpDirSuffix output tissues; of course for -n 3 ; CSF: 0, GM: 1, WM: 2
        	do
			NLSST_SegTisFile=${NonLinSSTAllSegFile}${segfiletype}_${tissue_cnt}

			SUBSESSegDIR=${PVE_SSToutDir}/sub-${SubID}_ses-${SesID}_${OpDirSuffix}_brain_NonLinearSST_Segmentation
			mkdir -p ${SUBSESSegDIR}

			SUBSESSegPreFix=${SUBSESSegDIR}/sub-${SubID}_ses-${SesID}_${OpDirSuffix}_brain_NonLinearSST_Segmentation
	                SUBSESSegFile=${SUBSESSegPreFix}${segfiletype}_${tissue_cnt}

			# Nonlinear SST > Linear SST -------------------------------------------------------------------------------------------
        		echo "####### Take the segmentation files from Nonlinear SST into the linear median SST, use invwarp (ants)"
        		echo "-- Moving Image: ${SUBSESSegFile}.nii.gz"
        		echo "-- Reference: ${FreeSurferVol_SubInMedian}.nii.gz"
        		echo "-- Inverse Warp: ${Sub2NonLinSST_InvWarpFile}.nii.gz"
        		echo "-- Affine: ${Sub2NonLinSST_AffineFile}.mat"
        		echo "-- Interpolation Method: ${InterpMeth}"
        		echo "#######"
        		echo " "

			antsApplyTransforms -d 3 \
			-i ${NLSST_SegTisFile}.nii.gz \
			-r ${FreeSurferVol_SubInMedian}.nii.gz \
			-t [${Sub2NonLinSST_AffineFile}.mat, 1] \
			-t ${Sub2NonLinSST_InvWarpFile}.nii.gz \
			-n ${InterpMeth} \
			-o ${SUBSESSegFile}_LinearSST.nii.gz

		done
	done


	# Take the atlas into the Linear space --------------------------------------------------------------------------------
	echo "####### Take the ATLAS from Nonlinear SST into the linear median SST, use invwarp (ants)"
	echo "-- Moving Image: ${NLSSTAtlasPreFix}_NonLinearSST.nii.gz"
	echo "-- Reference: ${FreeSurferVol_SubInMedian}.nii.gz"
	echo "-- Inverse Warp: ${Sub2NonLinSST_InvWarpFile}.nii.gz"
	echo "-- Affine: ${Sub2NonLinSST_AffineFile}.mat"
	echo "-- Interpolation Method: ${AtlasIntepMethod}"
	echo "#######"
	echo " "

	SUBSESAtlasPreFix=${AtlasesDir}/sub-${SubID}_ses-${SesID}_${AtOrFlg}_UKB-GMAtlas

	antsApplyTransforms \
	-d 3 \
	-i ${NLSSTAtlasPreFix}_NonLinearSST.nii.gz \
	-r ${FreeSurferVol_SubInMedian}.nii.gz \
	-t [${Sub2NonLinSST_AffineFile}.mat, 1] \
	-t ${Sub2NonLinSST_InvWarpFile}.nii.gz \
	-n ${AtlasIntepMethod} \
	-o ${SUBSESAtlasPreFix}_LinearSST.nii.gz

	#-----------------------------------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------------------------------
	#------------------------------------------------- APPLY ATLAS ON THE SEGs ---------------------------------------------
	#-----------------------------------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------------------------------

	GMSegTisFile=${SUBSESSegPreFix}pve_1
	GMPTXTFILENAME=${GMPTXTDIRNAME}/sub-${SubID}_ses-${SesID}_UKB-GMAtlas_GMVols

	#----------------------------------------------------------------
	#-------------- On the Linear SST -------------------------------
	#----------------------------------------------------------------

	echo ""
	echo "#### Apply Linear SST atlas on Linear SST gray matter:"
	echo "-- Atlas: ${SUBSESAtlasPreFix}_LinearSST.nii.gz"
	echo "-- PVE: ${GMSegTisFile}_LinearSST.nii.gz"
	echo "-- Results: ${GMPTXTFILENAME}_LinearSST.txt"
	echo ""

	echo "" > ${GMPTXTFILENAME}_LinearSST.txt

	${FSLDIR}/bin/fslstats -K ${SUBSESAtlasPreFix}_LinearSST.nii.gz \
	${GMSegTisFile}_LinearSST.nii.gz -m -v | xargs -n 3 | awk '{print "("$1"*"$2")"}' | bc >> ${GMPTXTFILENAME}_LinearSST.txt

	#-----------------------------------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------------------------------
	#------------------------------------------------- SIENAX ON THE SEGs --------------------------------------------------
	#-----------------------------------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------------------------------

	echo ""
	echo "=======================#################################################"
	echo "SIENAX on Study ${StudyID}, Subject ${SubID}, Session ${SesID}, Session count ${v_cnt}."
	echo "=======================#################################################"
	echo ""

	SIENAXFILENAME=${SIENAXDIRNAME}/sub-${SubID}_ses-${SesID}_Sienax

	T12MNIlinear_RAS=${SIENAXFILENAME}_T12MNI_${MNIOrientationFlag}
	report_sienax=${SIENAXFILENAME}_Report

	SUBSES_GMSEG_PreFix=${TMPLDir}/sub-${SubID}_ses-${SesID}_${AtOrFlg}_strucseg_nocereb
	SUBSES_PRIPHSEG_PreFix=${TMPLDir}/sub-${SubID}_ses-${SesID}_${AtOrFlg}_strucseg_periph
	SUBSES_VENTSEG_PreFix=${TMPLDir}/sub-${SubID}_ses-${SesID}_${AtOrFlg}_strucseg_vent

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

	antsApplyTransforms \
	-d 3 \
	-i ${NLSST_PRIPHSEG_PreFix}_NonLinearSST.nii.gz \
	-r ${FreeSurferVol_SubInMedian}.nii.gz \
	-t [${Sub2NonLinSST_AffineFile}.mat, 1] \
	-t ${Sub2NonLinSST_InvWarpFile}.nii.gz \
	-n ${AtlasIntepMethod} \
	-o ${SUBSES_PRIPHSEG_PreFix}_LinearSST.nii.gz

	#----------------------------------------------------------------
	#------------------- TAKE VENT SEG MNI > AVGRAW ----------------
	#----------------------------------------------------------------

	echo "############# Take the SEG VENT from MNI to RAWAVG:"

	antsApplyTransforms \
	-d 3 \
	-i ${NLSST_VENTSEG_PreFix}_NonLinearSST.nii.gz \
	-r ${FreeSurferVol_SubInMedian}.nii.gz \
	-t [${Sub2NonLinSST_AffineFile}.mat, 1] \
	-t ${Sub2NonLinSST_InvWarpFile}.nii.gz \
	-n ${AtlasIntepMethod} \
	-o ${SUBSES_VENTSEG_PreFix}_LinearSST.nii.gz

	#----------------------------------------------------------------
	#------------------- TAKE A WHOLE MASK WITHOUT CEREB ------------
	#----------------------------------------------------------------

	echo "############# Take the SEG VENT from MNI to RAWAVG:"

	antsApplyTransforms \
	-d 3 \
	-i ${NLSST_GMSEG_PreFix}_NonLinearSST.nii.gz \
	-r ${FreeSurferVol_SubInMedian}.nii.gz \
	-t [${Sub2NonLinSST_AffineFile}.mat, 1] \
	-t ${Sub2NonLinSST_InvWarpFile}.nii.gz \
	-n ${AtlasIntepMethod} \
	-o ${SUBSES_GMSEG_PreFix}_LinearSST.nii.gz

	#----------------------------------------------------------------
	#-------------------- CALCULATE THE VOLUMES ---------------------
	#----------------------------------------------------------------

	echo "###### Calculate the normalised/non-normalised volumes."

	echo "tissue             volume    unnormalised-volume" >> ${report_sienax}

	#----------------------------------------------------------------
	# GRAY MATTER ---------------------------------------------------
	#----------------------------------------------------------------

	segfiletype=pve
	tissue_cnt=1 #CSF: 0, GM: 1, WM: 2
	SEG_FILE_RAWAVG=${SUBSESSegPreFix}${segfiletype}_${tissue_cnt}_LinearSST

	# mask the pve with priph in native space
	${FSLDIR}/bin/fslmaths ${SEG_FILE_RAWAVG}.nii.gz -mas ${SUBSES_PRIPHSEG_PreFix}_LinearSST.nii.gz ${SEG_FILE_RAWAVG}_segpriph.nii.gz -odt float

	S=`${FSLDIR}/bin/fslstats ${SEG_FILE_RAWAVG}_segpriph.nii.gz -m -v`
	xa=`echo $S | awk '{print $1}'`
	xb=`echo $S | awk '{print $3}'`
	uxg=`echo "2 k $xa $xb * 1 / p" | dc -`
	xg=`echo "2 k $xa $xb * $vscale * 1 / p" | dc -`
	echo "pgrey              $xg $uxg (peripheral grey)" >> ${report_sienax}

	#----------------------------------------------------------------
	# CSF -----------------------------------------------------------
	#----------------------------------------------------------------

	segfiletype=pve
	tissue_cnt=0 #CSF: 0, GM: 1, WM: 2
	SEG_FILE_RAWAVG=${SUBSESSegPreFix}${segfiletype}_${tissue_cnt}_LinearSST

	${FSLDIR}/bin/fslmaths ${SEG_FILE_RAWAVG}.nii.gz -mas ${SUBSES_VENTSEG_PreFix}_LinearSST.nii.gz ${SEG_FILE_RAWAVG}_segvent.nii.gz -odt float

	S=`${FSLDIR}/bin/fslstats ${SEG_FILE_RAWAVG}_segvent.nii.gz -m -v`
	xa=`echo $S | awk '{print $1}'`
	xb=`echo $S | awk '{print $3}'`
	uxg=`echo "2 k $xa $xb * 1 / p" | dc -`
	xg=`echo "2 k $xa $xb * $vscale * 1 / p" | dc -`
	echo "vcsf               $xg $uxg (ventricular CSF)" >> ${report_sienax}

	#----------------------------------------------------------------
	# WHOLE GRAY MATTER ---------------------------------------------
	#----------------------------------------------------------------

	segfiletype=pve
	tissue_cnt=1 #CSF: 0, GM: 1, WM: 2
	SEG_FILE_RAWAVG=${SUBSESSegPreFix}${segfiletype}_${tissue_cnt}_LinearSST

	# ---------------- without cerebellum
	${FSLDIR}/bin/fslmaths ${SEG_FILE_RAWAVG}.nii.gz -mas ${SUBSES_GMSEG_PreFix}_LinearSST.nii.gz ${SEG_FILE_RAWAVG}_nocereb.nii.gz -odt float

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

	segfiletype=pve
	tissue_cnt=2 #CSF: 0, GM: 1, WM: 2
	SEG_FILE_RAWAVG=${SUBSESSegPreFix}${segfiletype}_${tissue_cnt}_LinearSST

	# ---------------- without cerebellum
	${FSLDIR}/bin/fslmaths ${SEG_FILE_RAWAVG}.nii.gz -mas ${SUBSES_GMSEG_PreFix}_LinearSST.nii.gz ${SEG_FILE_RAWAVG}_nocereb.nii.gz -odt float

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

	# ---------------- with cerebellum
	ubrain=`echo "2 k $uwhite $ugrey + 1 / p" | dc -`
	nbrain=`echo "2 k $nwhite $ngrey + 1 / p" | dc -`
	echo "BRAIN              $nbrain $ubrain" >> ${report_sienax}

	v_cnt=$((v_cnt+1))

done

echo "=============================="
echo "DONE-DONE-DONE-DONE-DONE-DONE"
echo "ENDS @" $(date)
echo "=============================="
