# syntax=docker/dockerfile:1

FROM tomcat:9-jdk11-temurin-jammy

RUN apt-get update \
    && apt-get upgrade -y
RUN apt-get install -y \
	aapt \
	wget \
	sed \
        postgresql-client \
	&& rm -rf /var/lib/apt/lists/*
RUN mkdir -p /usr/local/tomcat/conf/Catalina/localhost
RUN mkdir -p /usr/local/tomcat/ssl

ENV FORCE_RECONFIGURE=
ENV INSTALL_LANGUAGE=en

ENV SHARED_SECRET=changeme-C3z9vi54

ENV HMDM_VARIANT=os
ENV DOWNLOAD_CREDENTIALS=
ENV HMDM_URL=https://h-mdm.com/files/hmdm-5.40.1-$HMDM_VARIANT.war
ENV CLIENT_VERSION=6.37

ENV SQL_HOST=localhost
ENV SQL_PORT=5432
ENV SQL_BASE=hmdm
ENV SQL_USER=hmdm
ENV SQL_PASS=Ch@nGeMe

# PROTOCOL controls Tomcat transport. BASE_URL, when supplied, is the externally
# visible application URL and allows HTTPS to terminate at a reverse proxy.
ENV PROTOCOL=https
ENV BASE_URL=
#ENV BASE_DOMAIN=your-domain.com

# Set this parameter to your local IP address if your server is behind NAT.
#ENV LOCAL_IP=172.31.91.82

# Used only when Tomcat itself terminates HTTPS.
ENV HTTPS_LETSENCRYPT=true
#ENV HTTPS_CERT_PATH=/cert
ENV HTTPS_CERT=cert.pem
ENV HTTPS_FULLCHAIN=fullchain.pem
ENV HTTPS_PRIVKEY=privkey.pem

EXPOSE 8080
EXPOSE 8443
EXPOSE 31000

COPY docker-entrypoint.sh /
COPY update-web-app-docker.sh /opt/hmdm/
COPY tomcat_conf/server.xml /usr/local/tomcat/conf/server.xml
ADD templates /opt/hmdm/templates/

ENTRYPOINT ["/docker-entrypoint.sh"]
