FROM debian:buster-slim as librespot-builder


ENV LIBRESPOT_VERSION v0.1.0

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
      alsa-utils \
      build-essential \
      libasound2-dev \
      libsdl2-dev \
      curl \
      git
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin/:${PATH}"
RUN git clone https://github.com/librespot-org/librespot.git && \
    cd librespot && \
    git checkout $LIBRESPOT_VERSION && \
    cargo build --release --no-default-features --features alsa-backend

FROM debian:buster-slim

ENV SNAPCAST_VERSION v0.17.1

WORKDIR /src
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
      alsa-utils \
      avahi-daemon \
      build-essential \
      git \
      libasound2-dev \
      libavahi-client-dev \
      libflac-dev \
      libopus-dev \
      libvorbis-dev \
      libvorbisidec-dev \
      wget \
  && \
    wget https://dl.bintray.com/boostorg/release/1.72.0/source/boost_1_72_0.tar.gz && \
    tar xvzf boost_1_72_0.tar.gz && \
    cd boost_1_72_0 && \
    ./bootstrap.sh && \
    ./b2 install && \
    cd .. \
  && \
    git clone --recursive https://github.com/badaix/snapcast.git && \
    cd snapcast && \
    git checkout $SNAPCAST_VERSION && \
    git submodule update && \
    make && \
    install -D -g root -o root server/snapserver /usr/bin/snapserver && \
    install -D -g root -o root client/snapclient /usr/bin/snapclient \
  && \
    apt-get -y purge \
      build-essential \
      git \
      wget \
      $(dpkg -l|grep -- -dev |awk '{print $2}'|grep ^lib|awk -F: '{print $1}' ) \
  && \
    apt-get clean all && \
    rm -rf /usr/share/doc/* && \
    rm -rf /usr/share/info/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /src && \
    mkdir /src && \
    rm -rf /usr/local/include/boost && \
    rm -rf /usr/local/lib/libboost* && \
    rm -rf /usr/local/lib/cmake

COPY --from=librespot-builder /librespot/target/release/librespot /usr/local/bin

RUN useradd --system --uid 666 -M --shell /usr/sbin/nologin snapcast && \
    usermod -G audio,sudo snapcast && \
    mkdir -p /home/snapcast/.config && \
    chown snapcast:snapcast -R /home/snapcast
USER snapcast

EXPOSE 1704

WORKDIR /home/snapcast

CMD /usr/bin/snapserver
