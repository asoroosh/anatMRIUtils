#!/bin/bash

# Query
# Soroosh Afyouni, 2020, University of Oxford
#
#
#Copyright (c) 2020
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

StudyID=$1
SubID=$2
TAB=$3

ImageType=T12D

if [ -z $TAB ]; then
	DataDir=/XXX/XXX/XXX/MetaData
	TAB=${DataDir}/${StudyID}/${ImageType}/${StudyID}_${ImageType}_ImageSubSesID.table
fi

SES_LIST=""
SESID_LIST=""
ImageNameVar_List=""
RunIDList=""
ModIDList=""
SesNList=""
DateIDList=""

IFS=$'\n'
#cat $TAB | grep ${SubID} | while read SUBINFO
for SUBINFO in $(cat $TAB | grep ${SubID})
do
	SesIDVar=$(echo $SUBINFO | cut -d " " -f 2)
	SesID=$(echo $SesIDVar | awk -F"-" '{print $2}')
	DateID=$(echo $SesIDVar | awk -F"x" '{print $2}')
#	echo $DateID
	skip_flag=0
	for dd in ${DateIDList[@]}
	do
		if [ $dd == $DateID ]; then
			>&2 echo ""
			>&2 echo "XXXXXXX WARNING XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
			>&2 echo "XXX WARNING:: THERE are more than one scan in the same day!"
			>&2 echo "XXX $dd AND $DateID"
			>&2 echo "XXX We will not consider the duplicate!";
			>&2 echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
			>&2 echo ""
			skip_flag=1
		fi
	done

	[ $skip_flag == 1 ] && continue

	#SES_LIST="${SES_LIST} ${SesIDVar}"
	SES_LIST="${SES_LIST} ${SesID}"
	DateIDList=(${DateIDList} ${DateID})

	ImageNameVar=$(echo $SUBINFO | cut -d " " -f 8)
	ImageNameVar_List="${ImageNameVar_List} ${ImageNameVar}"

	RunID=$(echo $SUBINFO | cut -d " " -f 5)
	RunIDList="${RunIDList} ${RunID}"

	ModID=$(echo $SUBINFO | cut -d " " -f 4)
        ModIDList="${ModIDList} ${ModID}"

#	SesN=$(echo $SUBINFO | cut -d " " -f 9)
#        SesNList="${SesNList} ${SesN}"
done

unset IFS

SES_LIST=($SES_LIST)
SesNList=($SesNList)
DateIDList=($DateIDList)
ModIDList=($ModIDList)
RunIDList=($RunIDList)
ImageNameVar_List=($ImageNameVar_List)

#echo ${SES_LIST[@]}

# Check there are no identical dates




# SANITY CHECKS-----------------------------------------
#if [ ${#SES_LIST[@]} != ${SesN} ]
#then
#	echo "ERROR:: Number of sessions does not match the length of sessions."
#	exit 0
#fi

# This will check whether there is a missmatch in the table
for ii in ${SesNList[@]}; do
	for jj in ${SesNList[@]}; do
		if [ $ii -ne $jj ]; then
			echo "ERROR:: Session number does not match!"
		fi
	done
done



# OUTPUTS-----------------------------------------

echo ${SES_LIST[@]}
echo ${RunIDList[@]}
echo ${ImageNameVar_List[@]}
echo ${ModIDList[@]}
echo ${#SES_LIST[@]}
