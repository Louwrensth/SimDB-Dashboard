window.__SIMDB_RUNTIME_CONFIG__ = {
  // Modify runtime settings for the Dockerized dashboard.
  // nginx injects TOKENs at response time.
  servers: [
    'SCHEME://PUBLIC_SIMDB_HOST:DASHBOARD_PORT/scenarios/api',
  ],
  defaultServer: 'SCHEME://PUBLIC_SIMDB_HOST:DASHBOARD_PORT/scenarios/api',
  serverConfig: {
    'SCHEME://PUBLIC_SIMDB_HOST:DASHBOARD_PORT/scenarios/api': { requiresAuth: false }
  }
}
