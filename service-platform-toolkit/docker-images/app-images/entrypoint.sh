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

exec java -javaagent:/appdynamics/javaagent.jar -Dappdynamics.http.proxyHost=uk-proxy-01.systems.uk.hsbc -Dappdynamics.http.proxyPort=80 -Dappdynamics.http.proxyUser=43174502 -Dappdynamics.http.proxyPasswordFile=/appdynamics/pp.txt -Djava.security.egd=file:/dev/./urandom -jar /app.jar
