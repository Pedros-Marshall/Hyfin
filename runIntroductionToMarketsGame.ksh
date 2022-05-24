#!/bin/bash

# Run the Hyfin Simulator for Introduction to Markets

. ./.profile

# Variables for the simulation 

userID=$1

# Module 1 - Video variables
videoDuration=$2
videoStatus=$3

# Start the simulation

# check if user exists

./snowsql -q "select uid from uidtable where uid = $userID;" > result
eval=`cat result | grep "Row(s) produced" | awk '{print $1}'`

if [[ $eval == 1 ]]
then
	echo "User exists!"
	userExist=1
fi

if [[ $eval == 0 ]]
then
	userExist=0
	echo "New User!"
fi


# add user to the DB if a new user 

if [[ $userExist == 0 ]]
then
echo "Adding user :$userID to the UIDTABLE"	
./snowsql -q "INSERT INTO UIDTABLE (UID,CLIENTTYPE) VALUES ($userID,'MVP');"
fi

# Discover the module to run for the relevant learning journey

./snowsql -q "select moduleid from learningjourneys where moduleposition = '1' and classification = 'MVP';"  > result

moduleID=`cat result |  grep -v '-' | grep -v "MODULE" | grep -v SQL | grep -v Row | grep -v Good   | awk '{print $2}'`

echo "Module id is $moduleID"

# Discover the next (third) element ID to run for the relevant module 
./snowsql -q "select elementid from modules where elementposition = '3' and moduleid = $moduleID;"  > result

elementIDToRun=`cat result |  grep -v '-' | grep -v "ELEMENTID" | grep -v SQL | grep -v Row | grep -v Good   | awk '{print $2}'`

echo "Third elementID to run is $elementIDToRun"

# Discover the elementID type so we know what to run 

./snowsql -q "select elementtype from elements where elementid = $elementIDToRun;"  > result

elementIDType=`cat result |  grep -v '-' | grep -v "ELEMENTTYPE" | grep -v SQL | grep -v Row | grep -v Good   | awk '{print $2$3$4}'`

echo "Element to run is a $elementIDType"

# Discover where to retrieve the media from 

./snowsql -q "select medialocation from elements where elementid = $elementIDToRun;"  > result

mediaLocationForElementID=`cat result |  grep -v '+' | grep -v "MEDIALOCATION" | grep -v SQL | grep -v Row | grep -v 'Good' | grep -v '\-\-'`

echo "Media location for element $elementIDToRun is $mediaLocationForElementID"

echo "Launching element $elementIDToRun from module $moduleID of type $elementIDType"

echo ">"
echo " >"
echo "  >"

# Completion of element 1 from the Intro to markets module, update UID Audit

# Determine where this user has played this game before 



# Completion of element 1 from the Intro to markets module, update UID Audit

# Determine where this user has played this game before 

./snowsql -q "select count(QUIDNUMBER) from uidaudit where uid=$userID and elementid=$elementIDToRun"  > result

hasGameBeenPlayedForUser=`cat result |  grep -v '+' | grep -v "QUIDNUMBER" | grep -v SQL | grep -v Row | grep -v 'Good' | grep -v '\-\-' | awk '{print $2}' | awk '{print $1}'`

if [[ $hasGameBeenPlayedForUser -gt 0 ]]
then
echo "User $userID has played the in module game with an element ID of $elementIDToRun before..."
userHasPlayedGameBefore=1
else
echo "User $userID is a new player for the in module game with an element ID of $elementIDToRun..."
userHasPlayedGameBefore=0
fi

if [[ $userHasPlayedGameBefore == 0 ]]
then
# Select the min and max **ref** numbers to use to pick some random questions
./snowsql -q "select min(quidnumber) from gamequestions where difficulty='L01' and elementid=$elementIDToRun;"  > result
minQuidNumber=`cat result |  grep -v '+' | grep -v "QUIDNUMBER" | grep -v SQL | grep -v Row | grep -v 'Good' | grep -v '\-\-' | awk '{print $2}'`

echo "min quid number is $minQuidNumber"

./snowsql -q "select max(quidnumber) from gamequestions where difficulty='L01' and elementid=$elementIDToRun;"  > result

maxQuidNumber=`cat result |  grep -v '+' | grep -v "QUIDNUMBER" | grep -v SQL | grep -v Row | grep -v 'Good' | grep -v '\-\-' | awk '{print $2}'`
echo "max quid number is $maxQuidNumber"

# Generate the 5 Random question numbers

shuf -n 5 <(seq $maxQuidNumber | grep -Fxv -e{51}) > out

# ask the 5 questions and update the DB

export LIST=`cat out`
for each_question in $LIST
do
echo "Asking question $each_question"
./snowsql -q "INSERT INTO UIDAUDIT (UID,MEDIATYPE,MODULE,LEARNINGJOURNEY,LEARNINGJOURNEYID,MODULEID,ELEMENTID,QUIDNUMBER,QUIDNUMBEROUTCOME) VALUES ($userID,'$elementIDType','Introduction to Markets','MVP',1,$moduleID,$elementIDToRun,$each_question,'CORRECT');"
done




fi
exit

# Completion of element 1 from the Intro to markets module, update UID Audit 
echo "Updating audit table with results of element $elementIDToRun"
completionTime=`date`
./snowsql -q "INSERT INTO UIDAUDIT (UID,MEDIATYPE,MODULE,LEARNINGJOURNEY,LEARNINGJOURNEYID,MODULEID,ELEMENTID,ELEMENTSTATUS,COMPLETIONTIME,MEDIADURATION) VALUES ($userID,'$elementIDType','Introduction to Markets','MVP',1,$moduleID,$elementIDToRun,'$videoStatus','$completionTime','$videoDuration');"


