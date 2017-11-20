#!/bin/bash
IMAGE_NAME=$1
CTSPATH=$2
pcPassword=123
FILE=$CTSPATH/TestHistory/TestHistory.txt
echo ${pcPassword} | sudo -S mkdir $CTSPATH/TestHistory
echo ${pcPassword} | sudo -S mkdir $CTSPATH/TestHistory/$IMAGE_NAME
cd $CTSPATH/TestHistory
echo ${pcPassword} | sudo -S touch TestHistory.txt
echo ${pcPassword} | sudo -S chmod 777 TestHistory.txt
#export CTSPATH=~/android-cts/7.1r5/android-cts
export CTStool=$CTSPATH/tools/
export CTSresult=$CTSPATH/results
#export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
#export JRE_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
#export CLASSPATH=.:$JAVA_HOME/lib:$JRE_HOME/lib:$CLASSPATH
#export PATH=$HOME/bin:$JAVA_HOME/bin:$JRE_HOME/bin:$PATH
#export ANDROID_JAVA_HOME=$JAVA_HOME
echo BuildNumber:$IMAGE_NAME >> $FILE
echo | $CTStool/cts-tradefed l r | awk '/Pass/{print}' >> $FILE
echo | $CTStool/cts-tradefed l r | awk '/of/{print}' >> $FILE
echo '----------------------------------------------------------------------------------------------------------' >> $FILE
echo ${pcPassword} | sudo -S mv $CTSresult/* $CTSPATH/TestHistory/$IMAGE_NAME/

exit 0
