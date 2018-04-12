#!/bin/sh

exec java -javaagent:/appdynamics/javaagent.jar ${JAVA_OPTS} -Djava.security.egd=file:/dev/./urandom -jar /app.jar

# exec java -javaagent:/appdynamics/javaagent.jar -Dappdynamics.http.proxyHost=uk-proxy-01.systems.uk.hsbc -Dappdynamics.http.proxyPort=80 -Dappdynamics.http.proxyUser=43174502 -Dappdynamics.http.proxyPasswordFile=/appdynamics/pp.txt -Djava.security.egd=file:/dev/./urandom -jar /app.jar
