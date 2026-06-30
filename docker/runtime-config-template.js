const dashboard_relative = `/scenarios/api`;
const dashboard_absolute = `${window.location.origin}/api`;
const dashboard_otherport = `${window.location.protocol}//${window.location.hostname}:8080/scenarios`;
const dashboard_envsubst = 'SCHEME://PUBLIC_SIMDB_HOST:DASHBOARD_PORT/scenarios/api';
const simdb_iter_org = `https://simdb.iter.org/scenarios/api`;

window.__SIMDB_RUNTIME_CONFIG__ = {
  // Required runtime settings loaded by index.html.
  // This file is overwritten at docker-compose time for production and testing purposes.
  servers: [
    dashboard_relative,
    dashboard_absolute,
    dashboard_otherport,
    dashboard_envsubst,
    simdb_iter_org,
  ],
  defaultServer: dashboard_relative,
  serverConfig: {
    [dashboard_relative]: { requiresAuth: false },
    [dashboard_absolute]: { requiresAuth: false },
    [dashboard_otherport]: { requiresAuth: false },
    [dashboard_envsubst]: { requiresAuth: false },
    [simdb_iter_org]: { requiresAuth: true }
  }
};

