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

1. Build the production service image:

```sh
make service
```

2. Start the dashboard container:

```sh
make up
```

3. Open the dashboard: http://localhost:80/dashboard/

4. Stop the service when needed:

```sh
make down
```

## Adjusting the installation

Did something change in the `docker-compose.yml` or `docker/*` files? Stop the service, and restart service (rebuild not necessary):

```sh
make down up
```

Changed something in the `dashboard/*` sources? (e.g. after a `git pull`.) Stop the service, rebuild the service image (dependencies are cached) and restart:

```sh
make down service up
```

Notes:

- Requests under `/scenarios/api/` are proxied by nginx to a simdb server expected at `API_HOST:API_PORT` (defaults to `host.docker.internal:5000`).
- You can start multiple dashboards if you change the host port with `DASHBOARD_PORT`.
- Use `PUBLIC_SIMDB_URL` or edit `docker\runtime-config-template.js` for adjusting the simdb server:

```sh
DASHBOARD_PORT=8080 make up
DASHBOARD_PORT=8081 API_PORT=5001 make up
DASHBOARD_PORT=8082 API_HOST=172.20.0.1 API_PORT=5001 make up
PUBLIC_SIMDB_URL=https://simdb.iter.org/scenarios/api make up
```

- Additional conveniences are:

```sh
make list-all  # list all running dashboard containers
DASHBOARD_PORT=8081 make list      # list container for the selected container
DASHBOARD_PORT=8081 make logs-f    # follow compose logs for the selected container
DASHBOARD_PORT=8081 make shell     # open sh inside running dashboard container
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
make build        # build image for lint/type-check/test
make lint         # run lint checks against the build image
make type-check   # run TypeScript type checks against the build image
make test         # run unit tests against the build image
make update-base  # rebuild service image pulling latest base images
make update-deps  # refresh package-lock and apply npm audit fixes
make distclean    # remove local images/artifacts and compose runtime state
```
