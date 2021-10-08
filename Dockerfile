# Dockerfile for Tor Relay Server with obfs4proxy (Multi-Stage build)
FROM golang:alpine AS go-build

# Build /go/bin/obfs4proxy & /go/bin/meek-server
RUN apk --no-cache add --update git \
 && go get -v gitlab.com/yawning/obfs4.git/obfs4proxy \
 && go get -v git.torproject.org/pluggable-transports/meek.git/meek-server \
 && cp -rv /go/bin /usr/local/

FROM alpine:latest AS tor-build
ARG TOR_GPG_KEY=0x6AFEE6D49E92B601

# Install prerequisites
RUN apk --no-cache add --update \
        gnupg \
        build-base \
        libevent \
        libevent-dev \
        libressl \
        libressl-dev \
        xz-libs \
        xz-dev \
        zlib \
        zlib-dev \
        zstd \
        zstd-libs \
        zstd-dev \
      # Install Tor from source, incl. GeoIP files (get latest release version number from Tor ReleaseNotes)
      && TOR_VERSION=$(wget -q https://gitweb.torproject.org/tor.git/plain/ReleaseNotes -O - | grep -E -m1 '^Changes in version\s[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\s' | sed 's/^.*[^0-9]\([0-9]*\.[0-9]*\.[0-9]*\.[0-9][\s]*\).*$/\1/') \
      && TOR_TARBALL_NAME="tor-${TOR_VERSION}.tar.gz" \
      && TOR_TARBALL_LINK="https://dist.torproject.org/${TOR_TARBALL_NAME}" \
      && wget -q $TOR_TARBALL_LINK \
      && wget $TOR_TARBALL_LINK.asc \
    # Reliably fetch the TOR_GPG_KEY
        && found=''; \
         	for server in \
           		ha.pool.sks-keyservers.net \
           		hkp://keyserver.ubuntu.com:80 \
           		hkp://p80.pool.sks-keyservers.net:80 \
               ipv4.pool.sks-keyservers.net \
               keys.gnupg.net \
           		pgp.mit.edu \
         	; do \
         		echo "Fetching GPG key $TOR_GPG_KEY from $server"; \
         		gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$TOR_GPG_KEY" && found=yes && break; \
         	done; \
         	test -z "$found" && echo >&2 "error: failed to fetch GPG key $TOR_GPG_KEY" && exit 1; \
        gpg --verify $TOR_TARBALL_NAME.asc \
      && tar xf $TOR_TARBALL_NAME \
      && cd tor-$TOR_VERSION \
      && ./configure \
      && make install \
      && ls -R /usr/local/
      # Main files created (plus docs):
        # /usr/local/bin/tor
        # /usr/local/bin/tor-gencert
        # /usr/local/bin/tor-resolve
        # /usr/local/bin/torify
        # /usr/local/share/tor/geoip
        # /usr/local/share/tor/geoip6
        # /usr/local/etc/tor/torrc.sample

FROM alpine:latest
MAINTAINER Christian chriswayg@gmail.com

# If no Nickname is set, a random string will be added to 'Tor4'
ENV TOR_USER=tord \
    TOR_NICKNAME=Tor4

# Installing dependencies of Tor and pwgen
RUN apk --no-cache add --update \
      libevent \
      libressl \
      xz-libs \
      zstd-libs \
      zlib \
      zstd \
      pwgen

# Copy obfs4proxy & meek-server
COPY --from=go-build /usr/local/bin/ /usr/local/bin/

# Copy Tor
COPY --from=tor-build /usr/local/ /usr/local/

# Create an unprivileged tor user
RUN addgroup -g 19001 -S $TOR_USER && adduser -u 19001 -G $TOR_USER -S $TOR_USER

# Copy Tor configuration file
COPY ./torrc /etc/tor/torrc

# Copy docker-entrypoint
COPY ./scripts/ /usr/local/bin/

# Persist data
VOLUME /etc/tor /var/lib/tor

# ORPort, DirPort, SocksPort, ObfsproxyPort, MeekPort
EXPOSE 9001 9030 9050 54444 7002

ENTRYPOINT ["docker-entrypoint"]
CMD ["tor", "-f", "/etc/tor/torrc"]
