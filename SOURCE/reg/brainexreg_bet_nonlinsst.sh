#ml ANTs
#ml FreeSurfer
#ml Perl
#source /apps/eb/software/FreeSurfer/6.0.1-centos6_x86_64/FreeSurferEnv.sh

module load fsl
module load freesurfer
module load ANTs

set -e

#do_reg=10
#do_bex=1

do_reg=0
do_bex=0

#--------- SubID, StudyID, info from ANTs SST -----------------------------------------
# comes from the user:
#e.g.
#sh brainexreg_ants_nonlinsst.sh CFTY720D2301E1.anon.2019.07.16 CFTY720D2301.0105.00001

StudyID=$1
SubID=$2

#StudyID=$(echo ${StudyID_Date} | awk -F"." '{print $1}')
#StudyIDwoE=$(echo ${StudyID} | awk -F"E" '{print $1}')
#SubTag=sub-${StudyID}

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

DataDir=/well/nvs-mri-temp/data/ms/processed/MetaData
SessionsFileName=${DataDir}/${StudyID}/T12D/Sessions/${StudyID}_sub-${SubID}_T12D.txt

while read SessionPathsFiles
do
	ses_SesID_tmp=$(echo $SessionPathsFiles | awk -F"/" '{print $9}')
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
PRSD_DIR="/well/nvs-mri-temp/data/ms/processed"
PRSD_SUBDIR=${PRSD_DIR}/${StudyID}/sub-${SubID}

#-------------= X Sectional paths
SST_Dir=${PRSD_SUBDIR}/${ImgTyp}.${XSectionalDirSuffix}.${LogitudinalDirSuffix}

#--------------= Unprocessed paths
UPRSD_DIR="/well/nvs-mri-temp/data/ms/unprocessed"
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

NVSHOME=/well/nvs-mri-temp/users/scf915
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
antsRegOutputPrefix=${NonLinSSTDirImg}_MNI-${VoxRes}mm-BET-
NonLinSST_MNI=${antsRegOutputPrefix}Warped_Brain
NonLinSST_MNI_InvWarp=${antsRegOutputPrefix}1InverseWarp
NonLinSST_MNI_Affine=${antsRegOutputPrefix}0GenericAffine.mat
REG_LOG=${NonLinSSTDirImg}_BET_Brain_MNI.log


if [ $do_reg == 1 ] || [ $do_reg == 10 ]; then
#	rm -f ${NonLinSST_MNI_InvWarp} ${NonLinSST_MNI_Affine} ${NonLinSST_MNI}
		echo "TEST"
	else
		echo "############# No Registration will be done..."
fi


#------ ANTs Brain Extraction --------------------------------------------------------------

if [ $do_bex == 1 ]; then


	bet ${NonLinSSTDirImg}.nii.gz ${NonLinSSTDirImg}_BET_brain.nii.gz -R -m

	#echo "Do the Brain Extraction..."
	#${NonLinSSTDirImg}_Brain_ABE_BrainExtractionMask.nii.gz
	#${NonLinSSTDirImg}_Brain_ABE_BrainExtractionBrain.nii.gz
	#OasisTemplates=${NVSHOME}/NVROXBOX/AUX/Oasis
	#antsBrainExtraction.sh \
	#-d 3 \
	#-a ${NonLinSSTDirImg}.nii.gz \
	#-e ${OasisTemplates}/T_template0.nii.gz \
	#-m ${OasisTemplates}/T_template0_BrainCerebellumProbabilityMask.nii.gz \
	#-o ${NonLinSSTDirImg}_Brain_ABE_

else
	echo "****No Brain Extraction is done!"

fi

# copy the extracted brain
#cp ${NonLinSSTDirImg}_Brain_BET_BrainExtractionBrain.nii.gz ${NonLinSSTDirImg}_BET_brain.nii.gz

# copy the mask and fill the holes
NonLinSST_BrainMask=${SST_Dir}/sub-${SubID}_NonLinearSST_BET_BrainMask
cp ${NonLinSSTDirImg}_BET_brain_mask.nii.gz ${NonLinSST_BrainMask}.nii.gz

${FSLDIR}/bin/fslmaths ${NonLinSST_BrainMask}.nii.gz -fillh ${NonLinSST_BrainMask}.nii.gz

# get the skull out
${FSLDIR}/bin/fslmaths ${NonLinSSTDirImg}.nii.gz -sub ${NonLinSSTDirImg}_BET_brain.nii.gz ${NonLinSSTDirImg}_BET_skull.nii.gz


# ------- Do the job ---------------------------------------------------------------------

## REGISTRATION ######

echo "*************************************************************"
echo "REGISTER NONLINEAR SST > MNI RAS"
echo "MOVING: ${MNIImg_RAS_Brain}.nii.gz"
echo "FIXED: ${MNIImg_FS}.nii.gz"
echo "LOG FILE: ${REG_LOG}"
echo "*************************************************************"

if [ $do_reg == 1 ]; then

#-------------------------------
ShrnkFctrs="4x2x1x1"
SmthFctrs="3x2x1x0vox"
ItrNum="500x300x250x0"
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
--initial-moving-transform [${MNIImg_RAS_Brain}.nii.gz,${NonLinSSTDirImg}_BET_brain.nii.gz,1] \
--transform Rigid[0.1] \
--metric MI[${MNIImg_RAS_Brain}.nii.gz,${NonLinSSTDirImg}_BET_brain.nii.gz,1,32,Regular,0.25] \
--convergence [${ItrNum},1e-6,10] \
--shrink-factors ${ShrnkFctrs} \
--smoothing-sigmas ${SmthFctrs} \
--transform Affine[0.1] \
--metric MI[${MNIImg_RAS_Brain}.nii.gz,${NonLinSSTDirImg}_BET_brain.nii.gz,1,32,Regular,0.25] \
--convergence [${ItrNum},1e-6,10] \
--shrink-factors ${ShrnkFctrs} \
--smoothing-sigmas ${SmthFctrs} \
--transform SyN[0.1,3,0] \
--metric CC[${MNIImg_RAS_Brain}.nii.gz,${NonLinSSTDirImg}_BET_brain.nii.gz,1,4] \
--convergence [${ItrNum},1e-6,10] \
--shrink-factors ${ShrnkFctrs} \
--smoothing-sigmas ${SmthFctrs} >> ${REG_LOG}
#-x [NULL,${NonLinSST_BrainMask}.nii.gz] >> ${REG_LOG}

	echo "*************************************************************"
	echo "********** Registration is DONE! ****************************"
	echo "*************************************************************"

elif [ $do_reg == 10 ]; then

echo "--Run antsRegistrationSyN"

#------ TESTS
antsRegistrationSyN.sh -d 3 \
-f ${MNIImg_RAS_Brain}.nii.gz \
-m ${NonLinSSTDirImg}_BET_brain.nii.gz \
-t s \
-x ${NonLinSST_BrainMask}.nii.gz \
-o ${antsRegOutputPrefix}


else
	echo "############# No Registration will be done..."

fi

######################

# extract the brain of nonlinear template in MNI
#${FSLDIR}/bin/fslmaths ${NonLinSST_MNI}.nii.gz -mas ${MaskInMNI_FS}.nii.gz ${NonLinSST_MNI}_brain.nii.gz # brain in MNI space

#Skull in MNI
cp ${MNIImg_RAS_Skull}.nii.gz ${NonLinSST_MNI}_skull.nii.gz


echo "*************************************************************"


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

	LinearSSTBrainMask=${SST_Dir}/sub-${SubID}_ses-${SesID}_BET_BrainMaskLinearSST

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
	${FSLDIR}/bin/fslmaths ${FreeSurferVol_SubInMedian}.nii.gz -mas ${LinearSSTBrainMask}.nii.gz ${FreeSurferVol_SubInMedian}_BET_brain.nii.gz
	#skull
	${FSLDIR}/bin/fslmaths ${FreeSurferVol_SubInMedian}.nii.gz -sub ${FreeSurferVol_SubInMedian}_BET_brain.nii.gz ${FreeSurferVol_SubInMedian}_BET_skull.nii.gz
	echo "*************************************************************"

	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Nonlinear SST > Linear SST : DONE"

	# Get inverse of LTA
	LTA_FILE=${SST_Dir}/sub-${SubID}_ses-${SesID}_norm_xforms.lta
	INV_LTA_FILE=${SST_Dir}/sub-${SubID}_ses-${SesID}_norm_xforms_inv.lta # Inverse LTA
	lta_convert --inlta ${LTA_FILE} --outlta ${INV_LTA_FILE} --invert # Convert the LTAs


	SubjBrainMaskFS=${SST_Dir}/sub-${SubID}_ses-${SesID}_BET_BrainMaskFS

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
	${FSLDIR}/bin/fslmaths ${FreeSurfer_Vol_nuImg}.nii.gz -mas ${SubjBrainMaskFS}.nii.gz ${FreeSurfer_Vol_nuImg}_BET_brain.nii.gz
	#skull
	${FSLDIR}/bin/fslmaths ${FreeSurfer_Vol_nuImg}.nii.gz -sub ${FreeSurfer_Vol_nuImg}_BET_brain.nii.gz ${FreeSurfer_Vol_nuImg}_BET_skull.nii.gz
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

	# Now take me from 1x1x1 256^3 to the subject space
	mri_vol2vol --mov ${FreeSurfer_Vol_nuImg}_BET_brain.nii.gz --targ ${UnprocessedImg}.nii.gz --regheader \
	--o ${FreeSurfer_Vol_nuImg}_BET_brain_rawavg.nii.gz --no-save-reg

	${FSLDIR}/bin/fslmaths ${FreeSurfer_Vol_nuImg}_BET_brain_rawavg.nii.gz -bin ${FreeSurfer_Vol_nuImg}_BET_brain_rawavg_mask.nii.gz
	${FSLDIR}/bin/fslmaths ${FreeSurfer_Vol_nuImg}_BET_brain_rawavg_mask.nii.gz -fillh ${FreeSurfer_Vol_nuImg}_BET_brain_rawavg_mask.nii.gz

	#skull
	mri_vol2vol --mov ${FreeSurfer_Vol_nuImg}_BET_skull.nii.gz --targ ${UnprocessedImg}.nii.gz --regheader \
	--o ${FreeSurfer_Vol_nuImg}_BET_skull_rawavg.nii.gz --no-save-reg

	# Now take the mask from 1x1x1 256^3 to the raw space
	# -- BRAIN --
	mri_vol2vol --mov ${SubjBrainMaskFS}.nii.gz --targ ${UnprocessedImg}.nii.gz --regheader \
	--o ${FreeSurfer_Vol_nuImg}_BET_brain_rawavg_mask_test.nii.gz --nearest --no-save-reg

	# -- SKULL --


	v_cnt=$((v_cnt+1))
done

echo "==================================="
echo "DONE-DONE-DONE-DONE-DONE-DONE-DONE"
echo "STARTED @" $(date)
echo "==================================="
