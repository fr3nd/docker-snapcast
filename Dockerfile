FROM debian:buster-slim

# Latest version is v0.17.1 requires libboost 1.70.0 and it's not yet in buster
# see https://github.com/badaix/snapcast/issues/488
ENV SNAPCAST_VERSION v0.15.0

WORKDIR /src
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
      alsa-utils \
      avahi-daemon \
      build-essential \
      git \
      libasound2-dev \
      libavahi-client-dev \
      libboost-all-dev  \
      libflac-dev \
      libopus-dev \
      libvorbis-dev \
      libvorbisidec-dev \
    && \
    git clone --recursive https://github.com/badaix/snapcast.git && \
    cd snapcast && \
    git checkout $SNAPCAST_VERSION && \
    git submodule update && \
    make && \
    install -D -g root -o root server/snapserver /usr/bin/snapclient && \
    install -D -g root -o root client/snapclient /usr/bin/snapserver && \
    apt-get -y purge \
      build-essential \
      git \
      $(dpkg -l|grep -- -dev |awk '{print $2}'|grep ^lib|awk -F: '{print $1}' ) \
    && \
    apt-get clean all && \
    rm -rf /usr/share/doc/* && \
    rm -rf /usr/share/info/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /src/snapcast && \
    cd ..

RUN useradd --system --uid 666 -M --shell /usr/sbin/nologin snapcast && \
    mkdir -p /home/snapcast/.config && \
    chown snapcast:snapcast -R /home/snapcast
USER snapcast

EXPOSE 1704

WORKDIR /home/snapcast
