window.__SIMDB_RUNTIME_CONFIG__ = {
  // Modify runtime settings for the Dockerized dashboard.
  // Using SSI, inject the public host at HOST_PLACEHOLDER.
  servers: [
    'http://HOST_PLACEHOLDER:5000',
  ],
  defaultServer: 'http://HOST_PLACEHOLDER:5000',
  serverConfig: {
    'http://HOST_PLACEHOLDER:5000': { requiresAuth: false }
  }
}
