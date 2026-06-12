# Installation and maintenance guide

## Installing the dashboard

1. Check out the dashboard: `git clone git@github.com:iterorganization/SimDB-Dashboard.git`.
2. Change to the `dashboard` directory: `cd SimDB-Dashboard/dashboard`
3. Install the Bun dependencies: `bun install`
4. Build the dashboard: `bun run build`
5. As root install the dashboard: `cp -r dist/* /www-data/dashboard` (the location to install the files to will depend on which user is being used to serve them using nginx -- see below).

## Configuring nginx

Use the following configuration:

```
    root /www/data
    
    location /dashboard {
        try_files $uri $uri.html /dashboard/index.html
    }
```

This will serve static files from /www/data so /www/data/dashboard/index.html will be server as <server>/dashboard/index.html.

The `try_files` is required to allow for the behaviour of the single page app, as all endpoints under /dashboard will 
end up falling back to being served by /dashboard/index.html.

## Running with Docker Compose

1. From the repository root, build the image: `docker compose build`
2. Start the container: `docker compose up`
3. Open the dashboard at `http://localhost:8080/dashboard/`

The container image builds the frontend from `dashboard/` with Bun and serves the generated static files with nginx.
Requests under `/api/` are proxied to a Flask backend expected to be reachable from the Docker host on port `5000`.
