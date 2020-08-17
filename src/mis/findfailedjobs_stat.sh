

STAT_WC=$1

grep -l ": 0" $STAT_WC | while read FILENAME; do
#	echo $FILENAME
	FAILEDSUB=$(cat $FILENAME | awk -F"_" '{print $2}' | awk -F":" '{print $1}' | awk -F"-" '{print $2}')
	echo $FAILEDSUB
done

#cat $STAT_WC | awk '{sum+=$2 ; print $0} END{print "sum=",sum}'
