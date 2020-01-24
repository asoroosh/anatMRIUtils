StudyID=COMB157G2301
ImageType=T12D

PATH2EXE="${HOME}/NVROXBOX/EXE/proc50"
STUDYSTAT="${PATH2EXE}/NVR-OX-GET-STUDYSTATs.sh"
AUTORECON="${PATH2EXE}/NVR-OX-AUTORECON12-proc50.sh"
SSTCON="${PATH2EXE}/NVR-OX-SST-proc50.sh"
MASK_FNIRT="${PATH2EXE}/NVR-OX-RegSegSST_FNIRT_proc50.sh"
MASK_ANTS="${PATH2EXE}/NVR-OX-RegSegSST_BETREG_proc50.sh"
SEG_FAST="${PATH2EXE}/NVR-OX-RegSegSST_fast_proc50.sh"
SEG_ATROPOS="${PATH2EXE}/NVR-OX-RegSegSST_atropos_proc50.sh"

### Get info from data-set. The data-set should be fully BIDS-complaint.
sh ${STUDYSTAT} ${StudyID} ${ImageType} > /dev/null
### Submit AUTORECON12 on session level
FS1_SubmitFile=$(sh ${AUTORECON} ${StudyID} ${ImageType})
### Submit SST construction -- with only 5 evenly paced sessions; register the remaining to the SST
SST1_SubmitFile=$(sh ${SSTCON} ${StudyID} ${ImageType})

### Register to MNI and mask
	##USING FNIRT
MASK1_SubmitFile=$(sh ${MASK_FNIRT} ${StudyID} ${ImageType})
	##USING antsReg
MASK2_SubmitFile=$(sh ${MASK_ANTS} ${StudyID} ${ImageType})

### Segmentation & IDP extraction

	## Run FAST on Session level/SST level & Extract the IDPs
SEG1_SubmitFile=$(sh ${SEG_FAST} ${StudyID} ${ImageType})
	## Run ATROPOS on session level/SST level & Extract the IDPs
SEG2_SubmitFile=$(sh ${SEG_ATROPOS} ${StudyID} ${ImageType})

############## SUBMIT w/ Dependencies

echo "Submit AUTORECONN -- SESSION LEVEL :::::::::"
echo "Submitter file:"
echo $FS1_SubmitFile
FS1jid=$(sbatch --parsable $FS1_SubmitFile)
echo "JobID submitted: ${FS1jid}"

echo "Submit SST CONSTRUCTION -- SUBJECT LEVEL :::::::::"
echo "Submitter file:"
echo $SST1_SubmitFile
SSTjid=$(sbatch --parsable --dependency=afterok:${FS1jid} ${SST1_SubmitFile})
echo "JobID submitted: SSTjid"
