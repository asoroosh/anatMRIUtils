#the numbers should still be such that better registration results in a smaller cost-function value.

in_image=$1
ref_image=$2

#in_image=~/NVROXBOX/EXE/FSL/fnirt/tests/out_fnirt/sub-CFTY720D2201.0064.00007_ses-V2_run-1_T1w_T1_biascorr/T1_to_MNI_nonlin_FLIRT-DOF12-3D_FNIRT-subsmp1-1-1-lambda300-75-30.nii.gz
#T1_to_MNI_nonlin_FLIRT-DOF12-3D_FNIRT-FNIRTCHECK-infwhm4300-reffwhm4300-lambda50302010-sbsmpl1111-T1-2-MNI152-2mm-cnf.nii.gz
#ref_image=$FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz

flirt -in $in_image -ref $ref_image -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -cost corratio | head -1 | cut -f1 -d' '

#echo "COST FUNCTION BTWN 2 IMAGES:"
#echo "REF IMAGE: $ref_image"
#echo "INPUT IMAGE: $in_image"

#You can also select the similarity metric you want with -cost ...
#The measurecost1.sch file has been posted on the list before, but
#I'm attaching another copy here.  Just save it (as plain text)
#somewhere and give the full path in the command above.
#The cost value is the first number printed.  If you want to
#automatically
#select only this then you can do:
#    flirt .... | head -1 | cut -f1 -d' '

