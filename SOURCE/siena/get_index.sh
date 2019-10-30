function get_index() {
# fine me element(s) in the input array which contains the second input
# SA, Ox, 2019
arrgs=("$@")
mmmval=${arrgs[-1]}
NUMSES0=${#arrgs[@]}
for i in $(seq 0 $((NUMSES0-2)) )
do
	if [[ ${arrgs[i]} =~ $mmmval ]]; then
		echo "${i}";
	fi
done
}

A=(V10x20080624 V1x20070524 V501x20090925 V777x20090612 V8x20071204)

get_index "${A[@]}" "V1x"
