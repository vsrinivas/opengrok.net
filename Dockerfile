
# docker run -d -v /home/vsrinivas/xsrc:/src:ro -v /home/vsrinivas/xdata:/data -p 8080:8080 opengrok
FROM debian:testing-slim as fetcher

RUN apt-get -y update && apt-get install -y curl jq wget
RUN ["/bin/bash", "-c", "set -o pipefail \
     && curl -sS https://api.github.com/repos/oracle/opengrok/releases \
     | jq -er '.[0].assets[]|select(.name|startswith(\"opengrok-1.6.0\"))|.browser_download_url' \
     | wget --no-verbose -i - -O opengrok.tar.gz"]

#FROM tomcat:9-jdk14-openjdk-buster
FROM tomcat:10-jdk15-openjdk-slim-buster
MAINTAINER OpenGrok developers "opengrok-dev@yahoogroups.com"

#PREPARING OPENGROK BINARIES AND FOLDERS
COPY --from=fetcher opengrok.tar.gz /opengrok.tar.gz
RUN mkdir /opengrok && tar -zxvf /opengrok.tar.gz -C /opengrok --strip-components 1 && rm -f /opengrok.tar.gz && \
    mkdir /src && \
    mkdir /data && \
    mkdir -p /var/opengrok/etc/ && \
    ln -s /data /var/opengrok && \
    ln -s /src /var/opengrok/src

#INSTALLING DEPENDENCIES
RUN echo "deb http://deb.debian.org/debian buster-backports main" > /etc/apt/sources.list.d/backports.list
RUN apt-get update && apt-get install -y git subversion mercurial unzip inotify-tools python3 python3-pip && \
    python3 -m pip install /opengrok/tools/opengrok-tools*
# compile and install universal-ctags
RUN apt-get install -y pkg-config autoconf build-essential && git clone https://github.com/universal-ctags/ctags /root/ctags && \
    cd /root/ctags && ./autogen.sh && ./configure && make && make install && \
    apt-get remove -y autoconf build-essential && apt-get -y autoremove && apt-get -y autoclean && \
    cd /root && rm -rf /root/ctags

RUN apt-get install -y git/buster-backports
RUN git config --global core.commitGraph true
RUN git config --global gc.writeCommitGraph true

#ENVIRONMENT VARIABLES CONFIGURATION
ENV SRC_ROOT /src
ENV DATA_ROOT /data
ENV OPENGROK_WEBAPP_CONTEXT /
ENV OPENGROK_TOMCAT_BASE /usr/local/tomcat
ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
ENV CATALINA_BASE /usr/local/tomcat
ENV CATALINA_HOME /usr/local/tomcat
ENV CATALINA_TMPDIR /usr/local/tomcat/temp
ENV CLASSPATH /usr/local/tomcat/bin/bootstrap.jar:/usr/local/tomcat/bin/tomcat-juli.jar
RUN cat /usr/local/tomcat/bin/catalina.sh

# custom deployment to / with redirect from /source
RUN rm -rf /usr/local/tomcat/webapps/* && \
    opengrok-deploy /opengrok/lib/source.war /usr/local/tomcat/webapps/ROOT.war && \
    mkdir "/usr/local/tomcat/webapps/source" && \
    echo '<% response.sendRedirect("/"); %>' > "/usr/local/tomcat/webapps/source/index.jsp"

# disable all file logging
ADD logging.properties /usr/local/tomcat/conf/logging.properties
RUN sed -i -e 's/Valve/Disabled/' /usr/local/tomcat/conf/server.xml

# add our scripts
ADD scripts /scripts
RUN chmod -R +x /scripts

RUN mkdir -p /var/opengrok/etc
ADD read_only.xml /var/opengrok/etc/read_only.xml

# run
WORKDIR $CATALINA_HOME
EXPOSE 8080
CMD ["/scripts/start.sh"]
