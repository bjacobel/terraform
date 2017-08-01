Manages my shit in ECS

- `./`: common AWS infra like my hosted zone for `bjacobel.com` and a VPC, etc
    - `./ecs`: sets up an ECS cluster
    - `./klaxon`: [Klaxon](https://newsklaxon.org)
    - `./ipsec`: sets up an IPSEC VPN
    - `./webserver`: a caddy webserver to proxy requests to these services and future ones

