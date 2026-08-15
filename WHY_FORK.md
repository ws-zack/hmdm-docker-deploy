# Why this fork exists

This repository is a fork of the Headwind MDM Docker deployment project. It exists to support a deployment pattern that differs from the upstream Docker stack while keeping Headwind itself as close to upstream as practical.

## The deployment problem

The upstream Docker deployment is designed as a largely self-contained stack: Headwind/Tomcat handles HTTPS and the Compose project includes certificate management. That is convenient when Headwind owns the host or its public TLS lifecycle.

Many installations instead run multiple applications on one host behind an existing reverse proxy. In that model, a host-level nginx, Apache, HAProxy, Traefik, Caddy, cloud load balancer, or similar service already owns:

- public TCP 80/443
- TLS termination
- certificate issuance and renewal
- SNI and virtual-host routing

Headwind should then run as an internal HTTP service and let that existing edge terminate HTTPS.

The original Docker configuration ties Headwind's externally advertised URL to the protocol used by Tomcat through `PROTOCOL://BASE_DOMAIN`. Setting `PROTOCOL=http` is appropriate for the internal proxy-to-Tomcat connection, but it can also cause Headwind to generate public `http://` URLs even though clients actually reach the service over HTTPS.

## What this fork changes

This fork adds an optional `BASE_URL` setting so the two concerns can be represented independently:

```dotenv
BASE_URL=https://mdm.example.com
PROTOCOL=http
```

This means the deployment can be:

```text
managed device / administrator
            |
         HTTPS
            |
   external reverse proxy
            |
          HTTP
            |
     Headwind / Tomcat
```

When `BASE_URL` is not set, the existing `PROTOCOL://BASE_DOMAIN` behavior is retained for compatibility.

The supplied Compose profile also reflects the same shared-host model by default:

- Headwind HTTP is bound to loopback for the external reverse proxy.
- PostgreSQL is private to the Docker network rather than published on the host.
- The stack uses a dedicated Docker network.
- Headwind MQTT remains separately publishable for managed devices.
- Certificate management is intentionally outside the Compose stack.
- Persistent runtime data can be placed outside the source/build checkout with `HMDM_DATA_ROOT`.

## What this fork is not

This is not intended to become an independent Headwind MDM distribution or a divergent application fork.

The goal is deliberately narrow: make the official Docker deployment fit installations where HTTPS and reverse proxying are already provided by infrastructure outside the Headwind Compose project.

Changes should remain generic, avoid site-specific domains or credentials, and preserve upstream behavior where practical. Headwind server and Android application changes should remain upstream unless a deployment-specific change is genuinely required here.

## Upstream relationship

Headwind MDM is open source, and this repository retains the upstream licensing and attribution.

Where a change is broadly useful to Headwind users—particularly the separation of the externally advertised `BASE_URL` from Tomcat's internal transport—it may be suitable for contribution upstream. Keeping the changes small and documented is intentional so future upstream updates can be compared and incorporated without having to rediscover why this fork diverged.

For the actual deployment instructions, configuration variables, topology, and reverse-proxy example, see `README.md`.
