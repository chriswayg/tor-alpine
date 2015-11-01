## Tor server

*This docker image will run Tor as an unprivileged regular user, as recommended by torproject.org*

![](https://badge.imagelayers.io/vimagick/tor:latest.svg)

[`Tor`][1] is free software and an open network that helps you defend against
traffic analysis, a form of network surveillance that threatens personal
freedom and privacy, confidential business activities and relationships, and
state security.

- Tor prevents people from learning your location or browsing habits.
- Tor is for web browsers, instant messaging clients, and more.
- Tor is free and open source for Windows, Mac, Linux/Unix, and Android

<<<<<<< HEAD
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
DataDirectory /home/tord/.tor

# Set limits
#RelayBandwidthRate 1024 KB  # Throttle traffic to
#RelayBandwidthBurst 2048 KB # But allow bursts up to
#MaxMemInQueues 512 MB # Limit Memory usage to

# Run as obfuscated bridge
#ServerTransportPlugin obfs3 exec /usr/bin/obfsproxy managed
#ServerTransportListenAddr obfs3  0.0.0.0:54444
#BridgeRelay 1
=======
ServerTransportPlugin:

- [x] fte
- [x] meek
- [x] obfs3
- [x] obfs4

## docker-compose.yml

```
tor:
  image: vimagick/tor
  ports:
#   - "7002:7002"
    - "9001:9001"
# volumes:
#   - ./torrc:/etc/tor/torrc
#   - ./cert.pem:/var/lib/tor/cert.pem
#   - ./key.pem:/var/lib/tor/key.pem
  restart: always
```

> Default `torrc` is for `obfs4`.
> Uncomment lines to use `meek`.

## torrc (server)

```
BridgeRelay 1
ContactInfo noreply@datageek.info
DataDirectory /var/lib/tor
Exitpolicy reject *:*
Nickname datageek
ORPort 9001
PublishServerDescriptor 0
SocksPort 0
#ServerTransportPlugin fte exec /usr/bin/fteproxy --mode server --managed
#ServerTransportPlugin meek exec /usr/bin/meek-server --port 7002 --cert cert.pem --key key.pem
#ServerTransportPlugin obfs3 exec /usr/bin/obfsproxy managed
ServerTransportPlugin obfs4 exec /usr/bin/obfs4proxy
>>>>>>> upstream/master
```

### Tor docker run example

You can reuse the secret_id_key from a previous tor server installation by mounting it as a volume ```-v ./secret_id_key:/home/tord/.tor/keys/secret_id_key```, to continue with the same ID. 

```
<<<<<<< HEAD
docker run -d --name=tor_server_1 \
-p 9001:9001 \
-v ./torrc:/etc/tor/torrc \
--restart=always \
chriswayg/tor
```

Check with ```docker logs tor_server_1```. If you see the message ```[notice] Self-testing indicates your ORPort is reachable from the outside. Excellent. Publishing server descriptor.``` at the bottom after quite a while, your server started successfully.
=======
#Socks5Proxy 127.0.0.1:1080
UseBridges 1
#Bridge fte 1.2.3.4:9001 F24BF4DE74649E205A8A3621C84F97FF623B2083
#Bridge meek 1.2.3.4:9001 url=https://meek.datageek.info:7002/
#Bridge obfs3 1.2.3.4:9001 F24BF4DE74649E205A8A3621C84F97FF623B2083
Bridge obfs4 1.2.3.4:9001 F24BF4DE74649E205A8A3621C84F97FF623B2083
#ClientTransportPlugin fte exec /usr/local/bin/fteproxy
#ClientTransportPlugin meek exec /usr/local/bin/meek-client
#ClientTransportPlugin obfs3 exec /usr/local/bin/obfsproxy
ClientTransportPlugin obfs4 exec /usr/local/bin/obfs4proxy
```

> Please connect via `HTTPProxy`/`HTTPSProxy`/`Socks5Proxy` if you're blocked!
>>>>>>> upstream/master

### Tor docker-compose.yml example

```
<<<<<<< HEAD
server:
  image: chriswayg/tor
  ports:
    - "9001:9001"
  volumes:
    - ./torrc:/etc/tor/torrc
  restart: always
=======
$ openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/C=JP/ST=Tokyo/L=Heiwajima/O=DataGeek/OU=Org/CN=meek.datageek.info"
$ docker-compose up -d
$ docker-compose logs
$ docker exec -it tor_tor_1 tor --quiet --list-fingerprint
datageek F24B F4DE 7464 9E20 5A8A 3621 C84F 97FF 623B 2083
>>>>>>> upstream/master
```

##### start the Tor server

```
<<<<<<< HEAD
docker-compose up -d
docker-compose logs
docker exec tor_server_1 cat /home/tord/.tor/fingerprint
=======
$ tor -f /etc/tor/torrc
$ curl -x socks5h://127.0.0.1:9050 ifconfig.ovh
>>>>>>> upstream/master
```

### References

- https://www.torproject.org/projects/obfsproxy-debian-instructions.html.en
- https://blog.torproject.org/blog/how-use-%E2%80%9Cmeek%E2%80%9D-pluggable-transport
- https://fteproxy.org/help-server-with-tor
- https://github.com/Yawning/obfs4

[1]: https://www.torproject.org/
