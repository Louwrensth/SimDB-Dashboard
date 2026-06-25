window.__SIMDB_RUNTIME_CONFIG__ = {
  // Modify runtime settings for the Dockerized dashboard.
  // nginx injects TOKENs at response time.
  servers: [
    'http://DASHBOARD_HOST:DASHBOARD_PORT/api',
  ],
  defaultServer: 'http://DASHBOARD_HOST:DASHBOARD_PORT/api',
  serverConfig: {
    'http://DASHBOARD_HOST:DASHBOARD_PORT/api': { requiresAuth: false }
  }
}
