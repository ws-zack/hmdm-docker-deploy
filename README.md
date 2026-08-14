# Headwind MDM Docker deployment

This repository packages Headwind MDM for Docker and includes a deployment profile for installations where HTTPS is terminated by an external reverse proxy such as nginx, Apache, HAProxy, Traefik, Caddy, or a cloud load balancer.

Headwind MDM project: https://h-mdm.com

## Why this deployment profile exists

The upstream Docker configuration assumes Headwind/Tomcat owns HTTPS and certificate handling. On shared application hosts it is common to run one host-level reverse proxy and certificate manager for multiple services.

This repository supports that model by separating:

- `BASE_URL`: the externally visible Headwind URL, for example `https://mdm.example.com`
- `PROTOCOL`: the transport used by Tomcat itself, normally `http` behind a reverse proxy

When `BASE_URL` is unset, the original behavior is preserved and Headwind uses `PROTOCOL://BASE_DOMAIN`.

## Default Docker Compose topology

The provided `docker-compose.yaml` runs two services:

- `hmdm`: Headwind MDM/Tomcat
- `postgresql`: private PostgreSQL database

The defaults are deliberately suitable for a shared reverse-proxy host:

- Headwind HTTP binds to `127.0.0.1:18080`
- PostgreSQL is not published on a host port
- the stack uses a dedicated `hmdm-backend` Docker network
- MQTT remains published on TCP 31000 for managed devices
- TLS certificates remain outside this Compose stack

Copy `.env.example` to `.env` and replace the example credentials and domain:

```sh
cp .env.example .env
$EDITOR .env
docker compose up -d
```

A typical reverse-proxy deployment uses:

```dotenv
BASE_DOMAIN=mdm.example.com
BASE_URL=https://mdm.example.com
PROTOCOL=http
HMDM_BIND_ADDRESS=127.0.0.1
HMDM_HTTP_PORT=18080
HMDM_NETWORK_NAME=hmdm-backend
```

The reverse proxy should forward public HTTPS requests to `http://127.0.0.1:18080` and pass at least `Host`, `X-Real-IP`, `X-Forwarded-For`, and `X-Forwarded-Proto` headers. See `examples/nginx.conf` for a working nginx example.

## Ports

| Port | Default exposure | Purpose |
|---|---|---|
| 18080/tcp | loopback only | Headwind HTTP backend for the external reverse proxy |
| 31000/tcp | host/public | Headwind MQTT device notifications |
| 5432/tcp | Docker network only | PostgreSQL |

If MQTT is not required, or is proxied separately, adjust the Compose publishing accordingly.

## Configuration variables

The image supports the upstream Headwind variables plus `BASE_URL`.

`BASE_URL` is optional. When set, it becomes the Headwind `base.url` and is also used when generating initial application URLs. This allows:

```text
Internet client -> HTTPS reverse proxy -> HTTP Tomcat
```

without causing Headwind to generate `http://` URLs for its public address.

`FORCE_RECONFIGURE=true` regenerates the Headwind configuration from the environment. Leave it unset during normal operation.

## Building the image

```sh
docker build -t headwindmdm/hmdm:0.1.9 .
```

The Dockerfile remains compatible with Headwind's normal direct-HTTPS deployment. If `BASE_URL` is not supplied, the entrypoint falls back to the original `PROTOCOL://BASE_DOMAIN` behavior.

## Updating Headwind

Headwind can update its web panel through the administration interface. After downloading an update, restart the container:

```sh
docker compose restart hmdm
```

To update the container image or WAR defaults, compare this repository with the current upstream `h-mdm/hmdm-docker` project before deploying the new version.

## Persistent data

The Compose deployment stores persistent state under `./volumes`:

```text
volumes/db
volumes/work
volumes/hmdm-config
volumes/webapps
```

Do not delete these paths during normal upgrades.

The generated Headwind Tomcat context is stored under `volumes/hmdm-config/ROOT.xml`. Manual changes to that file are preserved unless `FORCE_RECONFIGURE=true` is used.

## Reverse-proxy security

The Headwind server has separate device-facing and administrative REST paths and supports application-level IP restrictions in its context configuration. A reverse proxy may add another security boundary around the administrative UI, but device enrollment, synchronization, notifications, downloads, and enabled plugin endpoints must remain reachable by managed devices.

For installations exposed to the Internet, use strong Headwind credentials, MQTT authentication, HTTPS at the public edge, and review Headwind's secure-enrollment and IP-filter options before production enrollment.

## License

This repository retains the upstream Headwind MDM licensing and attribution. See `LICENSE`.
