#!/bin/bash
#SBATCH --partition=main
#SBATCH --job-name=GOV_MKTMP_XXXX
#SBATCH --mem-per-cpu=7500M
#SBATCH --time=8-23:59:00
#SBATCH --cpus-per-task=1
#SBATCH --output=/home/XXXX/XXXX/NVROXBOX/EXE/studytemp/logs/MKTMPXXX_%A.out
#SBATCH --error=/home/XXXXX/XXXX/NVROXBOX/EXE/studytemp/logs/MKTMPXXXX_%A.err

ml ANTs

StudyID=XXXXXXXX

NRNDSST=50
JOBID=$SLURM_JOB_ID

REGTYPE="GR"
ITERATIONS=4
GRADSTEPS="0.2"
MAXITR="70x40x10x2"

PROC_DIR=/XXXXXX/XXXXX/XXXXX/XXXX
TMPLT_DIR=${PROC_DIR}/TEMPLATES/
RNDSST_DIR=${TMPLT_DIR}/${StudyID}/${StudyID}_${NRNDSST}_RNDSST_$JOBID

rm -rf ${RNDSST_DIR}
mkdir -p ${RNDSST_DIR}

SSTTXTLIST=${RNDSST_DIR}/${StudyID}_SSTlist.txt

ls ${PROC_DIR}/${StudyID}/sub-*/T12D.autorecon12ws.nuws_mrirobusttemplate/*_ants_temp_med_nutemplate0.nii.gz | sort -R |tail -$NRNDSST | while read SSTFILENAME; do
	cp ${SSTFILENAME} ${RNDSST_DIR}
	echo ${SSTFILENAME} >> $SSTTXTLIST
done

chmod 777 $RNDSST_DIR/*

BTLOG=${StudyID}_${JOBID}_buildtemplateparallel.log

cd $RNDSST_DIR

# TO RUN IT INDEPENDENTLY -------------------------------------------------
#NUMCORE=4
#buildtemplateparallel.sh \
#-d 3 \
#-m 30x50x20 \
#-t ${REGTYPE} \
#-i ${ITERATIONS} \
#-s CC \
#-c 2 \
#-j ${NUMCORE} \
#-o ${StudyID} \
#*_ants_temp_med_nutemplate0.nii.gz >> $BTLOG
# -------------------------------------------------------------------------

buildtemplateparallel_slurm.sh \
-d 3 \
-m ${MAXITR} \
-t ${REGTYPE} \
-i ${ITERATIONS} \
-g ${GRADSTEPS} \
-r 1 \
-s CC \
-c 5 \
-o ${StudyID} \
*_ants_temp_med_nutemplate0.nii.gz
