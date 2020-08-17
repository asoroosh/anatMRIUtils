set -e

# Make a template with FSL!
# Soroosh Afyouni, University of Oxford, 2020

sestxt=ses.txt
NSes=$(cat $sestxt | wc -l)

FSLFLIRTout=/xxxx/xxxx
FSLFLIRTin=/xxxx/xxxx

tol=0.0000001

FIRSTVISIT=$(sed "1q;d" ${sestxt})
cp ${FIRSTVISIT}.nii.gz ${FSLFLIRTout}/median1.nii.gz

for (( i=0; i < 50 ; i++ ))
do
	echo "Iteration: ${i}"
	cp ${FSLFLIRTout}/median1.nii.gz ${FSLFLIRTout}/median0.nii.gz

	for (( j = 1; j <= $NSes; j++ ))
	do
		MOVINGVISIT=$(sed "${j}q;d" ${sestxt})

#		echo "$j, $MOVINGVISIT, linear reg to the median."
#		echo "ref: ${FSLFLIRTout}/median.nii.gz"
#		echo "mov: ${MOVINGVISIT}.nii.gz"
#		echo "image out: ${FSLFLIRTout}/${j}_2_med.nii.gz"
#		echo "affine out: ${FSLFLIRTout}/${j}_2_med.mat"

		$FSLDIR/bin/flirt -dof 12 -in ${MOVINGVISIT}.nii.gz -ref ${FSLFLIRTout}/median0.nii.gz -omat ${FSLFLIRTout}/${j}_2_med.mat -out ${FSLFLIRTout}/${j}_2_med.nii.gz
		echo ${j}_2_med.nii.gz
	done

	fslmerge -t ${FSLFLIRTout}/medians.nii.gz ${FSLFLIRTout}/*_2_med.nii.gz
	fslmaths ${FSLFLIRTout}/medians.nii.gz -Tmedian ${FSLFLIRTout}/median1.nii.gz
	ImgMean1=$(fslstats R/median1.nii.gz -m)
	ImgMean0=$(fslstats R/median0.nii.gz -m)

	echo "ImageMean: $ImgMean1, $ImgMean0"

#	MeanDiff=$(($ImgMean0-$ImgMean1))

	MeanDiff=$(echo "scale=4;$ImgMean0-$ImgMean1" | bc)

	MeanDiff=$(echo "scale=4;sqrt($MeanDiff*$MeanDiff)" | bc)

	if (( $(echo "$MeanDiff < $tol" |bc -l) )); then
		echo "Converged on iteration ${i}, the difference is mean: ${MeanDiff}"
		break
	fi

	echo "Difference in mean: $MeanDiff"
done
