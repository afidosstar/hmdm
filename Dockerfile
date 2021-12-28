FROM tomcat:9-jre8-openjdk-buster

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main" 10 > /etc/apt/sources.list.d/pgdg.list

RUN apt update && apt install aapt android-tools-adb android-tools-fastboot postgresql-client-10 -y

#RUN apt apt-utils apt-transport-https ca-certificates  -y

#RUN apt install postgresql-client-9.6 -y

ENV JAVA_HOME=/usr/local/openjdk-8

ENV CATALINA_BASE   /usr/local/tomcat
ENV CATALINA_HOME   /usr/local/tomcat
ENV CATALINA_TMPDIR /usr/local/tomcat/temp

VOLUME /usr/hmdm

VOLUME /usr/local/tomcat/conf/Catalina/localhost


ENV HMDM_VERSION 4.08.2
ENV CLIENT_VERSION 4.14
ENV DB_HOST localhost
ENV DB_PORT 5432
ENV DB_BASE hmdm
ENV DB_USER hmdm
ENV DB_PASSWORD "hmdm"
ENV HOST '0.0.0.0'

ENV LANGUAGE 'fr'

ENV TOMCAT_HOME $CATALINA_HOME
ENV TOMCAT_ENGINE "Catalina"
ENV DEFAULT_TOMCAT_HOST "localhost"
ENV DEFAULT_BASE_DOMAIN  ""
ENV DEFAULT_BASE_PATH "ROOT"
ENV DEFAULT_PORT ""
ENV TEMP_DIRECTORY "/tmp"
ENV TEMP_SQL_FILE "$TEMP_DIRECTORY/hmdm_init.sql"



RUN mkdir -p /usr/hmdm
WORKDIR /usr/hmdm


ADD install.sh  .
ADD entrypoint.sh  .
ADD wait-for-it.sh  .

RUN chmod +x install.sh entrypoint.sh wait-for-it.sh

COPY install install
RUN ls -al install
COPY hmdm-$HMDM_VERSION-os.war hmdm.war 


#ENTRYPOINT [ "./run.sh"]

CMD [ "./entrypoint.sh" ]

