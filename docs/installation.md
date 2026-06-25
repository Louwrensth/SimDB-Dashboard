# Installation and maintenance guide

This project uses the top-level Makefile as the main entry point for building,
running, and maintaining the dashboard.

## Prerequisites

Install the following tools:

1. Docker
2. Docker Compose provider
3. GNU Make

Clone the repository and move to its root:

```sh
git clone git@github.com:iterorganization/SimDB-Dashboard.git
cd SimDB-Dashboard
```

To see all available commands:

```sh
make help
```

## Main installation workflow (Docker image + Compose)

From the repository root:

1. Optional cache setup:

```sh
make cache-setup
```

2. Build the production service image:

```sh
make service
```

3. Start the dashboard container:

```sh
make up
```

4. Open the dashboard:

```text
http://localhost:80/dashboard/
```

Stop the service when needed:

```sh
make down
```

Notes:

- `make up` starts Compose using the prebuilt `simdb-dashboard:service` image.
- Requests under `/api/` are proxied by nginx to a backend expected at
  `host.docker.internal:5000`.
- You can change the host port with `DASHBOARD_PORT`, for example:

```sh
DASHBOARD_PORT=8080 make up
```

## Static artifact installation (non-Compose nginx deployments)

If you want to deploy static files to an existing nginx host:

1. Build and export frontend artifacts:

```sh
make dist
```

This creates `dist/` at the repository root containing the built app.

2. Copy artifacts to your web root (example path):

```sh
sudo cp -r dist/* /www/data/
```

With the Dockerfile defaults, assets are served under `/dashboard`, so the final
index path should be `/www/data/dashboard/index.html`.

## nginx configuration

Use a location block that falls back to the SPA entry point:

```nginx
root /www/data;

location /dashboard {
    try_files $uri $uri.html /dashboard/index.html;
}
```

This is required for client-side routes under `/dashboard/*`.

## Maintenance and verification

Use Makefile targets for quality checks and updates:

```sh
make lint         # run lint stage in Docker
make test         # run unit tests in Docker
make update-base  # rebuild service image pulling latest base images
make update-deps  # refresh package-lock and apply npm audit fixes
make distclean    # remove local images/artifacts and compose runtime state
```

