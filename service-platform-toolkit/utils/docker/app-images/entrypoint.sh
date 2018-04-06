#!/bin/sh

set -e

if [[ -z ${FLUENT_ELASTICSEARCH_USER} ]] ; then
   sed -i  '/FLUENT_ELASTICSEARCH_USER/d' /fluentd/etc/${FLUENTD_CONF}
fi

if [[ -z ${FLUENT_ELASTICSEARCH_PASSWORD} ]] ; then
   sed -i  '/FLUENT_ELASTICSEARCH_PASSWORD/d' /fluentd/etc/${FLUENTD_CONF}
fi

exec fluentd -c /fluentd/etc/${FLUENTD_CONF} -p /fluentd/plugins ${FLUENTD_OPT}

exec java -javaagent:/appdynamics/javaagent.jar ${JAVA_OPTS} -Djava.security.egd=file:/dev/./urandom -jar /app.jar

exec java -javaagent:/appdynamics/javaagent.jar -Dappdynamics.http.proxyHost=192.168.99.1 -Dappdynamics.http.proxyPort=3128 -Djava.security.egd=file:/dev/./urandom -jar /app.jar
