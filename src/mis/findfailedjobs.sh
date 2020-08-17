# Find failed arrays given the jobid
# Only for Slurm

JJIID=$1

BB=""
for JID in $(sacct -u $USER -j $JJIID -s F | grep main | awk '{ print $1}')
do
	B=$(echo $JID | awk -F"_" '{print $2}')
	BB="${BB},${B}"
done

[ -z $BB ] && echo "NO FAILED JOBS FOR ${JJIID}"

BB=${BB:1}
echo "${BB}"
