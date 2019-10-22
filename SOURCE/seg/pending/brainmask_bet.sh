NonLinTempImg=sub-CFTY720D2324.0217.00001_ants_temp_med_nutemplate0

CWDD=/home/bdivdi.local/dfgtyk/NVROXBOX/EXE/brainmasks
RawImageInputDir=/data/ms/unprocessed/mri/CFTY720D2324.anon.2019.07.15/sub-CFTY720D2324.0217.00001
TmpltInputDir=/data/ms/processed/mri/CFTY720D2324.anon.2019.07.15/sub-CFTY720D2324.0217.00001/T12D.autorecon12ws.nuws_mrirobusttemplate

cp -r ${TmpltInputDir} ${CWDD}/brainimg/
cp -r ${RawImageInputDir} ${CWDD}/brainimg/

NonLinTempDirImg=${CWDD}/brainimg/T12D.autorecon12ws.nuws_mrirobusttemplate/${NonLinTempImg}.nii.gz

BETOutput=${CWDD}/brainimg/
BETOutputDirImg=${BETOutput}/${NonLinTempImg}_brain.nii.gz


# BET
echo "Run BET:"
echo "Input: ${NonLinTempDirImg}"
echo "Output: ${BETOutputDirImg}"

${FSLDIR}/bin/bet ${NonLinTempDirImg} ${BETOutputDirImg} -R -S -f 0.25



