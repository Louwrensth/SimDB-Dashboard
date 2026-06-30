const dashboard_internal = `/scenarios/api`;
const simdb_iter_org = `https://simdb.iter.org/scenarios/api`;

window.__SIMDB_RUNTIME_CONFIG__ = {
  // Required runtime settings loaded by index.html.
  // This file is overwritten at docker-compose time for production and testing purposes.
  servers: [
    dashboard_internal,
    simdb_iter_org,
  ],
  defaultServer: dashboard_internal,
  serverConfig: {
    [dashboard_internal]: { requiresAuth: false },
    [simdb_iter_org]: { requiresAuth: true }
  }
};
