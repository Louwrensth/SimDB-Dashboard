window.__SIMDB_RUNTIME_CONFIG__ = {
  // Required runtime settings loaded by index.html.
  // Can be overwritten at docker-compose time for testing purposes.
  servers: [
    'https://simdb.iter.org/scenarios/api'
  ],
  defaultServer: 'https://simdb.iter.org/scenarios/api',
  serverConfig: {
    'https://simdb.iter.org/scenarios/api': { requiresAuth: false }
  }
}
