#!/bin/sh
# $Id: java_api.sh 627 2011-07-11 00:16:11Z andre $
# Starter script for SciteJavaApi.bsh

# Assuming the BeanShell jar file is in the current directory.
for f in *.jar
do
  LCP="$LCP:$f"
done

$JAVA_HOME/bin/java -XX:MaxPermSize=128m -cp $LCP bsh.Interpreter SciteJavaApi.bsh
