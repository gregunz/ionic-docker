FROM debian:jessie
LABEL maintainer="gregunz <contact@gregunz.io>"

ENV DEBIAN_FRONTEND=noninteractive \
    ANDROID_HOME=/opt/android-sdk-linux \
    NPM_VERSION=5.4.2 \
    IONIC_VERSION=3.12.0 \
    CORDOVA_VERSION=7.0.1 \
    SDKMAN_DIR=/usr/local/sdkman \
    # Fix for the issue with Selenium, as described here:
    # https://github.com/SeleniumHQ/docker-selenium/issues/87
    DBUS_SESSION_BUS_ADDRESS=/dev/null

# Install basics
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    python-software-properties \
    ruby \
    ruby-dev \
    software-properties-common \
    unzip \
    wget

# NODEJS
# Install nodejs
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - \
    && apt-get update &&  apt-get install -y \
        nodejs

# IONIC & CORDOVA
# Install depencies (npm, cordova, ionic, yarn, sass, scss_lint)
RUN set -x \
    && npm install -g \
        npm@"$NPM_VERSION" \
        cordova@"$CORDOVA_VERSION" \
        ionic@"$IONIC_VERSION" \

    && gem install \
        sass \
        scss_lint

# Install SDKMAN
RUN curl -s get.sdkman.io | bash \
    && set -x \
    && echo "sdkman_auto_answer=true" > $SDKMAN_DIR/etc/config \
    && echo "sdkman_auto_selfupdate=false" >> $SDKMAN_DIR/etc/config \
    && echo "sdkman_insecure_ssl=false" >> $SDKMAN_DIR/etc/config

# Install Gradle
RUN sdk install gradle 4.2

# Install chrome (for e2e test, headless use)
RUN set -x \
    && wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && dpkg --unpack google-chrome-stable_current_amd64.deb \
    && apt-get install -f -y \
    && apt-get clean \
    && rm google-chrome-stable_current_amd64.deb

# Font libraries
RUN apt-get -qqy install fonts-ipafont-gothic xfonts-100dpi xfonts-75dpi xfonts-cyrillic xfonts-scalable libfreetype6 libfontconfig

# Install Java8 (with use of python-software-properties to do add-apt-repository)
RUN set -x \
    && add-apt-repository "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" -y \
    && echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections \
    && apt-get update && apt-get -y install \
        oracle-java8-installer

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
# Install Android Tools
    && mkdir /opt/android-sdk-linux && cd /opt/android-sdk-linux \
    && wget --output-document=android-tools-sdk.zip --quiet https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip \
    && unzip -q android-tools-sdk.zip \
    && rm -f android-tools-sdk.zip \
    && chown -R root. /opt

# Setup environment
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools

# Install Android SDK
RUN yes Y | ${ANDROID_HOME}/tools/bin/sdkmanager "build-tools;26.0.1" "platforms;android-26" "platform-tools"
RUN cordova telemetry off

WORKDIR Sources
EXPOSE 8100 35729
CMD ["ionic", "serve"]
