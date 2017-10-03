# IONIC DOCKER
# perfect envirronment to build your latest ionic app on android with the latest SDK
#
# DEPENDENCIES (to reuse this Dockerfile):
# - apt-packages.txt at /requirements
# - font-libs.txt at /requirements

FROM debian:jessie

LABEL maintainer="gregunz <contact@gregunz.io>"

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm \
    LANG=en_US.UTF-8 \
    ANDROID_HOME=/opt/android-sdk-linux \
    GRADLE_HOME=/opt/gradle \
    GRADLE_VERSION=4.2 \
    NPM_VERSION=5.4.2 \
    IONIC_VERSION=3.12.0 \
    CORDOVA_VERSION=7.0.1 \
    # Fix for the issue with Selenium, as described here:
    # https://github.com/SeleniumHQ/docker-selenium/issues/87
    DBUS_SESSION_BUS_ADDRESS=/dev/null

ADD /requirements /tmp/requirements

# INSTALL REQUIREMENTS
RUN set -x \
    && apt-get update -y \
    && xargs -a /tmp/requirements/apt-packages.txt apt-get install -y

# FONT LIBRARIES
RUN xargs -a /tmp/requirements/font-libs.txt apt-get install -y

# INSTALL CHROME (for e2e test, headless use)
RUN set -x \
    && wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && dpkg --unpack google-chrome-stable_current_amd64.deb \
    && apt-get install -f -y \
    && apt-get clean \
    && rm google-chrome-stable_current_amd64.deb

# INSTALL JAVA8 (with use of python-software-properties and hence add-apt-repository)
RUN set -x \
    && add-apt-repository "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" -y \
    && echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections \
    && apt-get update && apt-get -y install \
        oracle-java8-installer

# INSTALL GRADLE
RUN set -x \
    && wget --output-document=gradle-bin.zip https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
    && mkdir ${GRADLE_HOME} \
    && unzip -d ${GRADLE_HOME} gradle-bin.zip \
    && ls ${GRADLE_HOME} \
    && ls ${GRADLE_HOME}/gradle-${GRADLE_VERSION}

# ADD GRADLE TO PATH
ENV PATH=${GRADLE_HOME}/gradle-${GRADLE_VERSION}/bin:${PATH}

# INSTALL NODEJS 6.X
RUN set -x \
    && curl -sL https://deb.nodesource.com/setup_6.x | bash - \
    && apt-get update &&  apt-get install -y \
        nodejs

# INSTALL NPM & IONIC & CORDOVA
RUN set -x \
    && npm install -g \
        npm@"$NPM_VERSION" \
        cordova@"$CORDOVA_VERSION" \
        ionic@"$IONIC_VERSION"

# SET CORDOVA TELEMETRY TO OFF
RUN cordova telemetry off

# INSTALL SASS & SCSS_LINT
RUN set -x \
    && gem install \
        sass \
        scss_lint

# ANDROID
# System libs for Android enviroment
RUN set -x \
    && echo ANDROID_HOME="${ANDROID_HOME}" >> /etc/environment \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --force-yes expect ant wget libc6-i386 lib32stdc++6 lib32gcc1 lib32ncurses5 lib32z1 qemu-kvm kmod \
    && apt-get clean \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
# Android Tools
    && mkdir /opt/android-sdk-linux && cd /opt/android-sdk-linux \
    && wget --output-document=android-tools-sdk.zip --quiet https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip \
    && unzip -q android-tools-sdk.zip \
    && rm -f android-tools-sdk.zip \
    && chown -R root. /opt

# ADD ANDROID TO PATH
ENV PATH=${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools::${PATH}

# INSTALL ANDROID SDK
RUN yes Y | ${ANDROID_HOME}/tools/bin/sdkmanager "build-tools;26.0.1" "platforms;android-26" "platform-tools"

WORKDIR /build

EXPOSE 8100 35729

CMD ["/bin/bash"]