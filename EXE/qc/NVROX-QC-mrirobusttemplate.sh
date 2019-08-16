
slicesdir2imghtm () {
SOURCEFILES=${HOME}/NVROXBOX/SOURCE
mkdir -p $1/slicesdir/pngfiles
cp $1/slicesdir/*sub*.png $1/slicesdir/pngfiles
python3 ${SOURCEFILES}/img_htm_mri.py \
-i "$1/slicesdir/pngfiles/" \
-o "$1/" \
-sn $2 \
-nc 1 \
-nf $(ls $1/slicesdir/pngfiles/ | wc -l)
}

################

DataDir="/data/ms/processed/mri"

ml Python 

CS_DirSuffix=ants
LT_DirSuffix=mrirobusttemplate
ImgTyp=T12D

ImageName="*_mean"

while read StudyID
do

	echo ${StudyID}

	StudyID_Date=$(ls ${DataDir} | grep "${StudyID}.anon") #because the damn Study names has inconsistant dates in them!
	ProcessedPath="${DataDir}/${StudyID_Date}"
	QC_Results=${DataDir}/QC/${StudyID}

	TargetDir=${QC_Results}/${CS_DirSuffix}${LT_DirSuffix}

	mkdir -p $TargetDir
	cd $TargetDir

	Data2ShowDir=${ProcessedPath}/sub-*/$ImgTyp.$CS_DirSuffix.$LT_DirSuffix/${ImageName}.nii.gz

	ls $Data2ShowDir | wc -l

	slicesdir $Data2ShowDir

	slicesdir2imghtm ${TargetDir} ${StudyID}_${CS_DirSuffix}${LT_DirSuffix}

done</home/bdivdi.local/dfgtyk/NVROXBOX/EXE/getinfo/StudyIDs_Clean.txt
