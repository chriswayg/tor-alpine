# Dockerfile for Tor Relay Server with obfs4proxy
# Multi-Stage build
FROM golang:alpine AS go-build

# Build obfs4proxy & meek-server
RUN go get -v git.torproject.org/pluggable-transports/obfs4.git/obfs4proxy \
    # /go/bin/obfs4proxy
 && go get -v git.torproject.org/pluggable-transports/meek.git/meek-server \
    # /go/bin/meek-server

FROM alpine:latest
MAINTAINER Christian chriswayg@gmail.com

# Environment setting only used during build
ARG TOR_GPG_KEY=0x6AFEE6D49E92B601

# If no Nickname is set, a random string will be added to 'Tor4'
ENV TOR_USER=tord \
    TOR_NICKNAME=Tor4

# Install prerequisites
RUN apk --no-cache add --update \
      gnupg \
      build-base \
      libgmpxx \
      gmp-dev \
      libevent \
      libevent-dev \
      openssl \
      openssl-dev \
      xz-libs \
      xz-dev \
      zstd \
      zstd-dev \
      pwgen \
    # Install Tor from source, incl. GeoIP files (get latest release version number from Tor ReleaseNotes)
    && TOR_VERSION=$(wget -q https://gitweb.torproject.org/tor.git/plain/ReleaseNotes -O - | grep -m1  "Changes in version" | sed 's/^.*[^0-9]\([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\).*$/\1/') \
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
    && cd .. \
    && rm -r tor-$TOR_VERSION \
    && rm $TOR_TARBALL_NAME \
    && rm $TOR_TARBALL_NAME.asc \
    && apk del \
      gnupg \
      build-base \
      gmp-dev \
      libevent-dev \
      openssl-dev \
      xz-dev \
      zstd-dev

COPY --from=go-build /bin/obfs4proxy  /usr/local/bin/obfs4proxy
COPY --from=go-build /bin/meek-server /usr/local/bin/meek-server

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
