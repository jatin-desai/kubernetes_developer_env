#!/bin/sh

exec java -javaagent:/appdynamics/javaagent.jar ${JAVA_OPTS} -Djava.security.egd=file:/dev/./urandom -Djavax.net.ssl.keyStore=keystore.jks -Djavax.net.ssl.keyStorePassword=${KEYSTORE_PASSWORD} -jar /app.jar
