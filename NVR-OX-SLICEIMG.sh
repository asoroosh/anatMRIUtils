set -e


Take_a_Pic(){
  A=`${FSLDIR}/bin/remove_ext $1`
  echo "Will be read from:  $A"
  FileName=${A##*/}
  echo $FileName

  outputpath=$2

  echo "The picture will be saved in: $outputpath"

  sliceropts="-x 0.4 tmp_a.png -x 0.5 tmp_b.png -x 0.6 tmp_c.png -y 0.4 tmp_d.png -y 0.5 tmp_e.png -y 0.6 tmp_f.png -z 0.4 tmp_g.png -z 0.5 tmp_h.png -z 0.6 tmp_i.png"
  convertopts="tmp_a.png + tmp_b.png + tmp_c.png + tmp_d.png + tmp_e.png + tmp_f.png + tmp_g.png + tmp_h.png + tmp_i.png"

  ${FSLDIR}/bin/slicer $A -s 1 $sliceropts
  ${FSLDIR}/bin/pngappend $convertopts $outputpath/${FileName}.png
  rm tmp_*.png
}

Take_a_Pic $1 `pwd`
