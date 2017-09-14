#
# Dockerfile for tor
# 

FROM alpine
MAINTAINER Christian chriswayg@gmail.com

# update TOR_VER and MD5 for new version 
# (verify download with gpg signature & create md5)
ENV TOR_ENV production
ENV TOR_VER 0.2.6.10
ENV TOR_MD5 04f919e7882d1ca80f835545af562bad

ENV TOR_URL https://www.torproject.org/dist/tor-$TOR_VER.tar.gz
ENV TOR_FILE tor.tar.gz
ENV TOR_TEMP tor-$TOR_VER

RUN apk add -U build-base \
               gmp-dev \
               libevent \
               libevent-dev \
               libgmpxx \
               openssl \
               openssl-dev \
               python \
               python-dev \
    && wget -O $TOR_FILE $TOR_URL \
        && echo "$TOR_MD5  $TOR_FILE" | md5sum -c \
        && tar xzf $TOR_FILE \
        && cd $TOR_TEMP \
        && ./configure --prefix=/ --exec-prefix=/usr \
        && make install \
        && cd .. \
        && rm -rf $TOR_FILE $TOR_TEMP \
    && wget -O- https://bootstrap.pypa.io/get-pip.py | python \
        && pip install --trusted-host fteproxy \
                                     obfsproxy \
    && rm -rf /root/.cache/pip/* \
    && apk del build-base \
               git \
               gmp-dev \
               go \
               python-dev \
    && rm -rf /var/cache/apk/*

# create an unprivileged tor user
RUN addgroup -g 19001 -S tord && adduser -u 19001 -G tord -S tord

COPY ./torrc /etc/tor/torrc
COPY ./docker-entrypoint /docker-entrypoint

VOLUME /etc/tor /home/tord/.tor

# ORPort, DirPort, SocksPort, ObfsproxyPort
EXPOSE 9001 9030 9050 54444

ENTRYPOINT ["/docker-entrypoint"]
