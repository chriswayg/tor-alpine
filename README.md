## Tor Relay Server

### A small, efficient and secure Tor relay server Docker image based on Alpine Linux
*This docker image will run Tor as an unprivileged regular user, as recommended by torproject.org*

* For a similar image based on Debian use `tor-server`:*
- https://hub.docker.com/r/chriswayg/tor-server/
- https://github.com/chriswayg/tor-server

The Tor network relies on volunteers to donate bandwidth. The more people who run relays, the faster the Tor network will be. If you have at least 2 megabits/s for both upload and download, please help out Tor by configuring your Tor to be a relay too.

![Tor](https://www.torproject.org/images/tor-logo.jpg "Tor logo")

[`Tor`][1] is free software and an open network that helps you defend against
traffic analysis, a form of network surveillance that threatens personal
freedom and privacy, confidential business activities and relationships, and
state security.

- Tor prevents people from learning your location or browsing habits.
- Tor is for web browsers, instant messaging clients, and more.
- Tor is free and open source for Windows, Mac, Linux/Unix, and Android

### Tor configuration

First edit ```./torrc``` on the host to the intended settings:

```
### /etc/torrc ###
# https://www.torproject.org/docs/tor-manual.html.en

# CONFIGURE THIS BEFORE RUNNING TOR!

Nickname I_DID_NOT_SET_A_VALID_NICKNAME
#ContactInfo email@example.com

# Server's public IP Address
#Address 10.10.10.10

SocksPort 0
ORPort 9001

ExitPolicy reject *:* # no exits allowed

# run tor as a regular user
User tord
DataDirectory /var/lib/tor

# Set limits
#RelayBandwidthRate 1024 KB  # Throttle traffic to
#RelayBandwidthBurst 2048 KB # But allow bursts up to
#MaxMemInQueues 512 MB # Limit Memory usage to

# Run as obfuscated bridge
#ServerTransportPlugin obfs3 exec /usr/bin/obfsproxy managed
#ServerTransportListenAddr obfs3  0.0.0.0:54444
#BridgeRelay 1
```

### Tor docker run example

You can reuse the secret_id_key from a previous tor server installation by mounting it as a volume ```-v ./secret_id_key:/var/lib/tor/keys/secret_id_key```, to continue with the same ID.

```
docker run -d --init --name=tor-server_relay_1 \
--net=host -v $PWD/torrc:/etc/tor/torrc \
--restart=always chriswayg/tor-alpine
```

Check with ```docker logs tor_server_1```. If you see the message ```[notice] Self-testing indicates your ORPort is reachable from the outside. Excellent. Publishing server descriptor.``` at the bottom after quite a while, your server started successfully.

### Tor docker-compose.yml example

```
version: '2.2'
services:
  relay:
    image: chriswayg/tor-alpine
    init: true
    restart: always
    network_mode: host
    volumes:
      ## mount custom `torrc` and DataDirectory here
      - ./torrc:/etc/tor/torrc
      - ./data/:/var/lib/tor/
```

##### start the Tor server
This will start a new instance of the Tor relay server, show the current fingerprint and display the logs:
```
docker-compose up -d
docker exec tor_server_1 cat /var/lib/tor/fingerprint
docker-compose logs
```

### License:
 - MIT

### Guides
- [Tor Relay Guide](https://trac.torproject.org/projects/tor/wiki/TorRelayGuide)
- [Tor on Debian Installation Instructions](https://www.torproject.org/docs/debian.html.en)
- [Torproject - git repo](https://github.com/torproject/tor)
- [obfs4proxy on Debian - Guide to run an obfuscated bridge to help censored users connect to the Tor network.](https://trac.torproject.org/projects/tor/wiki/doc/PluggableTransports/obfs4proxy)
- [obfs4 - The obfourscator - Github](https://github.com/Yawning/obfs4)
- [How to use the “meek” pluggable transport](https://blog.torproject.org/how-use-meek-pluggable-transport)
- [meek-server for Tor meek bridge](https://github.com/arlolra/meek/tree/master/meek-server)
- Originally based on: https://github.com/vimagick/dockerfiles/tree/master/tor

[1]: https://www.torproject.org/
