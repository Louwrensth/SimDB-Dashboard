const dev_backend_api_url = `http://${window.location.hostname}:5000`;

window.__SIMDB_RUNTIME_CONFIG__ = {
  // Required runtime settings loaded by index.html.
  // This file is overwritten at docker-compose time for production and testing purposes.
  servers: [
    dev_backend_api_url,
  ],
  defaultServer: dev_backend_api_url,
  serverConfig: {
    [dev_backend_api_url]: { requiresAuth: false }
  }
};
