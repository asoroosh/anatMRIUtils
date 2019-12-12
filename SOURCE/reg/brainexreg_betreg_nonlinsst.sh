#Ecample sub
#CFTY720D2201 CFTY720D2201x0001x00001

source ${HOME}/NVROXBOX/SOURCE/reg/setpathinanalytics

echo $PRSD_DIR
echo $UPRSD_DIR
echo $DataDir
echo $NVSHOME

set -e

do_reg=0
do_bex=0

#_BETsREG_
#_BE${seglab}-REG${reglab}_

#seglab=BET
#reglab=2SyN
#BETREGOP=BE${seglab}-REG${reglab}

BETREGOP=BETsREG

#--------- SubID, StudyID, info from ANTs SST -----------------------------------------
# comes from the user:
#e.g.
#sh brainexreg_ants_nonlinsst.sh CFTY720D2301E1.anon.2019.07.16 CFTY720D2301.0105.00001

StudyID=$1
SubID=$2

NonLinTempImgName=sub-${SubID}_ants_temp_med_nutemplate0

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

SessionsFileName=${DataDir}/${StudyID}/T12D/Sessions/${StudyID}_sub-${SubID}_T12D.txt

while read SessionPathsFiles
do
	ses_SesID_tmp=$(echo $SessionPathsFiles | awk -F"/" -v i=$VisitIDX '{print $i}')
	SesID_tmp=$(echo $ses_SesID_tmp | awk -F"-" '{print $2}');
	SesIDList="${SesIDList} $SesID_tmp"
	echo ${SesIDList}
done<${SessionsFileName}

SesIDList=(${SesIDList})
NumSes=${#SesIDList[@]}
#--------------------------------------------------------------------------------------
ImgTyp=T12D
XSectionalDirSuffix=autorecon12ws
LogitudinalDirSuffix=nuws_mrirobusttemplate
# ------

#------------= Main paths
PRSD_SUBDIR=${PRSD_DIR}/${StudyID}/sub-${SubID}

#-------------= X Sectional paths
SST_Dir=${PRSD_SUBDIR}/${ImgTyp}.${XSectionalDirSuffix}.${LogitudinalDirSuffix}

#--------------= Unprocessed paths
UnprocessedDir=${UPRSD_DIR}/${StudyID}

#--------------= Path to SST templates
# Nonlinear Template
NonLinSSTDirImg=${SST_Dir}/${NonLinTempImgName}
# Linear Template
LinSST=${SST_Dir}/sub-${SubID}_norm_nu_median.nii.gz # this should be moved

# -------- Application initialisations ------------------------------------------------
VoxRes=2
MaskThr=0.5
OrFlag=LIA

#NVSHOME=/well/nvs-mri-temp/users/scf915
MNITMP_DIR=${NVSHOME}/NVROXBOX/AUX/MNItemplates/${OrFlag}
MNIImg_FS=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_${OrFlag}
MaskInMNI_FS=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_brain_mask_${OrFlag}

MNIImg_RAS_Brain=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_brain_${OrFlag}
MNIImg_RAS_Skull=${MNITMP_DIR}/MNI152_T1_${VoxRes}mm_skull_${OrFlag}

echo "*************************************************************"
echo "=== BRING THE MNI TEMPLATE & MASK INTO RAS ORIENTATION:"
echo "MNI RAS: ${MNIImg_FS}"
echo "BrainMask RAS: ${MaskInMNI_FS}"
echo "*************************************************************"

# ------- Path inistialisations --------------------------------------------------------

#register to MNI
antsRegOutputPrefix=${NonLinSSTDirImg}_MNI-${VoxRes}mm-${BETREGOP}-
NonLinSST_MNI=${antsRegOutputPrefix}Warped_brain
NonLinSST_MNI_InvWarp=${antsRegOutputPrefix}1InverseWarp
#NonLinSST_MNI_InvWarp=${antsRegOutputPrefix}InverseWarp
NonLinSST_MNI_Affine=${antsRegOutputPrefix}0GenericAffine.mat
REG_LOG=${NonLinSSTDirImg}_${BETREGOP}_Brain_MNI.log


if [ $do_reg == 1 ] || [ $do_reg == 10 ]; then
#	rm -f ${NonLinSST_MNI_InvWarp} ${NonLinSST_MNI_Affine} ${NonLinSST_MNI}
		echo "TEST"
	else
		echo "############# No Registration will be done..."
fi


#------ ANTs Brain Extraction --------------------------------------------------------------

if [ $do_bex == 1 ]; then

	echo "Doing brain extraction..."
	bet ${NonLinSSTDirImg}.nii.gz ${NonLinSSTDirImg}_${BETREGOP}_brain.nii.gz -R -m -S

	echo "Brain extraction done; "
	echo "check: ${NonLinSSTDirImg}_${BETREGOP}_brain.nii.gz"

else
	echo "****No Brain Extraction is done!"

fi

# ------- Do the job ---------------------------------------------------------------------

## REGISTRATION ######

echo "*************************************************************"
echo "REGISTER NONLINEAR SST > MNI RAS"
echo "MOVING: ${MNIImg_RAS_Brain}.nii.gz"
echo "FIXED: ${MNIImg_FS}.nii.gz"
echo "LOG FILE: ${REG_LOG}"
echo "*************************************************************"

if [ $do_reg == 1 ]; then

	echo "Registration has started:"
	echo ""
	echo "${reglab}"

${FSLDIR}/bin/fslmaths ${NonLinSSTDirImg}_${BETREGOP}_brain_mask.nii.gz -dilM ${NonLinSSTDirImg}_${BETREGOP}_brain_mask_dil1.nii.gz

#-------------------------------
ShrnkFctrs="8x4x2x1"
SmthFctrs="3x2x1x0vox"
ItrNum="2000x500x250x0"
#-------------------------------
#ShrnkFctrs="6x4x2x1"
#SmthFctrs="3x2x1x0vox"
#ItrNum="50x50x20x0"

	echo " " > ${REG_LOG}

antsRegistration \
--verbose 1 \
--dimensionality 3 \
--float 0 \
--collapse-output-transforms 1 \
--output [${antsRegOutputPrefix},${antsRegOutputPrefix}Warped_brain.nii.gz,${antsRegOutputPrefix}InverseWarped.nii.gz] \
--interpolation Linear \
--use-histogram-matching 1 \
--winsorize-image-intensities [0.005,0.995] \
--initial-moving-transform [${MNIImg_RAS_Brain}.nii.gz,${NonLinSSTDirImg}_${BETREGOP}_brain.nii.gz,1] \
--transform Rigid[0.1] \
--metric MI[${MNIImg_RAS_Brain}.nii.gz,${NonLinSSTDirImg}_${BETREGOP}_brain.nii.gz,1,32,Regular,0.25] \
--convergence [1000x500x250x100,1e-6,10] \
--shrink-factors 12x8x4x2 \
--smoothing-sigmas ${SmthFctrs} \
--transform Affine[0.1] \
--metric MI[${MNIImg_RAS_Brain}.nii.gz,${NonLinSSTDirImg}_${BETREGOP}_brain.nii.gz,1,32,Regular,0.25] \
--convergence [1000x500x250x100,1e-6,10] \
--shrink-factors 12x8x4x2 \
--smoothing-sigmas ${SmthFctrs} \
--transform SyN[0.1,3,0] \
--metric CC[${MNIImg_RAS_Brain}.nii.gz,${NonLinSSTDirImg}_${BETREGOP}_brain.nii.gz,1,10] \
--convergence [100x100x70x50x20,1e-6,10] \
--shrink-factors 10x6x4x2x1 \
--smoothing-sigmas 6x4x2x1x0vox \
--transform SyN[0.1,3,1] \
--metric CC[${MNIImg_RAS_Brain}.nii.gz,${NonLinSSTDirImg}_${BETREGOP}_brain.nii.gz,1,10] \
--convergence [100x100x70x50x20,1e-6,10] \
--shrink-factors 10x6x4x2x1 \
--smoothing-sigmas 6x4x2x1x0vox \
--masks [NULL,${NonLinSSTDirImg}_${BETREGOP}_brain_mask_dil1.nii.gz] #>> ${REG_LOG}

#--transform SyN[0.1,3,0] \
#--metric CC[${MNIImg_RAS_Brain}.nii.gz,${NonLinSSTDirImg}_${BETREGOP}_brain.nii.gz,1,4] \
#--convergence [${ItrNum},1e-6,10] \
#--shrink-factors ${ShrnkFctrs} \
#--smoothing-sigmas ${SmthFctrs} \
#--masks [NULL,${NonLinSSTDirImg}_${BETREGOP}_brain_mask_dil1.nii.gz] \

# extract the brain of nonlinear template in MNI
${FSLDIR}/bin/fslmaths ${antsRegOutputPrefix}Warped_brain.nii.gz -mas ${MaskInMNI_FS}.nii.gz ${antsRegOutputPrefix}Warped_brain_brain.nii.gz # brain in MNI space
#Skull in MNI
#${FSLDIR}/bin/fslmaths ${NonLinSST_MNI}.nii.gz -sub ${NonLinSST_MNI}_brain.nii.gz ${NonLinSST_MNI}_skull.nii.gz
#cp ${MNIImg_RAS_Skull}.nii.gz ${NonLinSST_MNI}_skull.nii.gz

	echo "*************************************************************"
	echo "********** Registration is DONE! ****************************"
	echo "*************************************************************"

elif [ $do_reg == 10 ]; then

echo "--Run antsRegistrationSyN"

${FSLDIR}/bin/fslmaths ${NonLinSSTDirImg}_${BETREGOP}_brain_mask.nii.gz -dilM ${NonLinSSTDirImg}_${BETREGOP}_brain_mask_dil1.nii.gz

antsRegistrationSyN.sh -d 3 \
-f ${MNIImg_RAS_Brain}.nii.gz \
-m ${NonLinSSTDirImg}_${BETREGOP}_brain.nii.gz \
-t s \
-x ${NonLinSSTDirImg}_${BETREGOP}_brain_mask_dil1.nii.gz \
-o ${antsRegOutputPrefix} >> ${REG_LOG}

mv ${antsRegOutputPrefix}Warped.nii.gz ${antsRegOutputPrefix}Warped_brain.nii.gz

# extract the brain of nonlinear template in MNI
${FSLDIR}/bin/fslmaths ${antsRegOutputPrefix}Warped_brain.nii.gz -mas ${MaskInMNI_FS}.nii.gz ${antsRegOutputPrefix}Warped_brain_brain.nii.gz # brain in MNI space
#Skull in MNI
#${FSLDIR}/bin/fslmaths ${NonLinSST_MNI}.nii.gz -sub ${NonLinSST_MNI}_brain.nii.gz ${NonLinSST_MNI}_skull.nii.gz

else
	echo "############# No Registration will be done..."

fi

######################

echo "*************************************************************"
NonLinSST_BrainMask=${SST_Dir}/sub-${SubID}_NonLinearSST_${BETREGOP}_BrainMask

#${FSLDIR}/bin/fslmaths $MaskInMNI_FS -dilM ${MaskInMNI_FS}_dil1

if [ $do_reg == 1 ]; then
echo "flag: $do_reg"

antsApplyTransforms -d 3 \
-i ${MaskInMNI_FS}.nii.gz \
-r ${NonLinSSTDirImg}.nii.gz \
-t [${NonLinSST_MNI_Affine}, 1] \
-t ${NonLinSST_MNI_InvWarp}.nii.gz \
-o ${NonLinSST_BrainMask}.nii.gz

else
echo "flag: $do_reg"

antsApplyTransforms -d 3 \
-i ${MaskInMNI_FS}.nii.gz \
-r ${NonLinSSTDirImg}.nii.gz \
-t [${NonLinSST_MNI_Affine}, 1] \
-t ${NonLinSST_MNI_InvWarp}.nii.gz \
-o ${NonLinSST_BrainMask}.nii.gz

fi

${FSLDIR}/bin/fslmaths ${NonLinSST_BrainMask}.nii.gz -fillh ${NonLinSST_BrainMask}.nii.gz

# brain extracted
${FSLDIR}/bin/fslmaths ${NonLinSSTDirImg}.nii.gz -mas ${NonLinSST_BrainMask}.nii.gz ${NonLinSSTDirImg}_${BETREGOP}_brain.nii.gz
# get the skull out
${FSLDIR}/bin/fslmaths ${NonLinSSTDirImg}.nii.gz -sub ${NonLinSSTDirImg}_${BETREGOP}_brain.nii.gz ${NonLinSSTDirImg}_${BETREGOP}_skull.nii.gz

####
echo "++++++Now sort out the masks...."
echo ""

v_cnt=0;
# Get subject specific brain masks
for SesID in ${SesIDList[@]}
do
#	SesID=${SesIDList[v_cnt]}

	echo "============================================================"
	echo "** StudyID: ${StudyID}, SubID: ${SubID}, SesID: ${SesID}"
	echo "============================================================"

	echo " ------------------------------------------------- SESSION: ${SesID} -------------"

	FreeSurfer_Dir=${PRSD_SUBDIR}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_run-1_T1w.${XSectionalDirSuffix}
	FreeSurfer_Vol_Dir=${FreeSurfer_Dir}/sub-${SubID}_ses-${SesID}_run-1_T1w/mri
	FreeSurfer_Vol_nuImg=${FreeSurfer_Vol_Dir}/nu

	#Moving Image
	FreeSurferVol_SubInMedian=${SST_Dir}/sub-${SubID}_ses-${SesID}_nu_2_median_nu

	Sub2NonLinSST_InvWarpFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nusub-${SubID}_ses-${SesID}_nu_2_median_nu${v_cnt}1InverseWarp
	Sub2NonLinSST_AffineFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nusub-${SubID}_ses-${SesID}_nu_2_median_nu${v_cnt}0GenericAffine
	#Sub2NonLinSST_InvWarpFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nu${SubTag}${v_cnt}1InverseWarp
	#Sub2NonLinSST_AffineFile=${SST_Dir}/sub-${SubID}_ants_temp_med_nu${SubTag}${v_cnt}0GenericAffine

	LinearSSTBrainMask=${SST_Dir}/sub-${SubID}_ses-${SesID}_${BETREGOP}_BrainMaskLinearSST

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
	-o ${LinearSSTBrainMask}.nii.gz

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

	# Get inverse of LTA
	LTA_FILE=${SST_Dir}/sub-${SubID}_ses-${SesID}_norm_xforms.lta
	INV_LTA_FILE=${SST_Dir}/sub-${SubID}_ses-${SesID}_norm_xforms_inv.lta # Inverse LTA
	lta_convert --inlta ${LTA_FILE} --outlta ${INV_LTA_FILE} --invert # Convert the LTAs


	SubjBrainMaskFS=${SST_Dir}/sub-${SubID}_ses-${SesID}_${BETREGOP}_BrainMaskFS

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
	mri_convert ${FreeSurfer_Vol_nuImg}.mgz ${FreeSurfer_Vol_nuImg}.nii.gz
	${FSLDIR}/bin/fslmaths ${FreeSurfer_Vol_nuImg}.nii.gz -mas ${SubjBrainMaskFS}.nii.gz ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain.nii.gz
	#skull
	${FSLDIR}/bin/fslmaths ${FreeSurfer_Vol_nuImg}.nii.gz -sub ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain.nii.gz ${FreeSurfer_Vol_nuImg}_${BETREGOP}_skull.nii.gz
	echo "*************************************************************"

	echo ""
	echo ""
	echo "*************************************************************"
	echo "Take the brains from FreeSurfer brain images to the rawavg space."
	echo "Make a mask of the rawavg."
	echo "*************************************************************"
	echo ""
	echo ""

	UnprocessedImg=${UnprocessedDir}/sub-${SubID}/ses-${SesID}/anat/sub-${SubID}_ses-${SesID}_run-1_T1w

#	# Now take me from 1x1x1 256^3 to the subject space
#	mri_vol2vol --mov ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain.nii.gz --targ ${UnprocessedImg}.nii.gz --regheader \
#	--o ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg.nii.gz --no-save-reg
#
#	${FSLDIR}/bin/fslmaths ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg.nii.gz -bin ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg_mask.nii.gz
#	${FSLDIR}/bin/fslmaths ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg_mask.nii.gz -fillh ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg_mask.nii.gz

	#skull
	mri_vol2vol --mov ${FreeSurfer_Vol_nuImg}_${BETREGOP}_skull.nii.gz --targ ${UnprocessedImg}.nii.gz --regheader \
	--o ${FreeSurfer_Vol_nuImg}_${BETREGOP}_skull_rawavg.nii.gz --no-save-reg

	#-- BRAIN MASKS
	mri_vol2vol --mov ${SubjBrainMaskFS}.nii.gz --targ ${UnprocessedImg}.nii.gz --regheader \
	--o ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg_mask.nii.gz --nearest --no-save-reg

	${FSLDIR}/bin/fslmaths ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg_mask.nii.gz -fillh ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg_mask.nii.gz
	${FSLDIR}/bin/fslmaths ${UnprocessedImg}.nii.gz -mas ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg_mask.nii.gz ${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg.nii.gz

	echo "+_+_+_+_+__CHECK THIS:"
	echo "${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg.nii.gz"
	echo "${FreeSurfer_Vol_nuImg}_${BETREGOP}_brain_rawavg_mask.nii.gz"

	v_cnt=$((v_cnt+1))
done

echo "==================================="
echo "DONE-DONE-DONE-DONE-DONE-DONE-DONE"
echo "STARTED @" $(date)
echo "==================================="
