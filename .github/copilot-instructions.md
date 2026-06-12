# Copilot instructions for SimDB-Dashboard

## Build, test, and lint commands

Run frontend commands from `dashboard/`.

```bash
cd dashboard
npm install
npm run dev
npm run build
npm run preview
npm run type-check
npm run lint
npm run test:unit
```

Run a single Vitest file with:

```bash
cd dashboard
npm run test:unit -- src/components/SomeComponent.spec.ts
```

CI installs dependencies with `npm ci` and runs linting, type-checking, and the production build from `dashboard/`.

## High-level architecture

The active application code is the Vue 3 + Vite SPA under `dashboard/`. The repo root also contains deployment/docs assets, but the frontend source, package scripts, and CI all center on `dashboard/`.

- `dashboard/src/main.ts` boots Vue, registers Vuetify, exposes the build-time `__APP_VERSION__`, and adds a global `String.prototype.toLabel()` helper used throughout the UI.
- `dashboard/src/router/index.ts` defines the three user-facing flows:
  - `/` for search
  - `/uuid/:id` and `/alias/:id` for simulation detail
  - `/compare/` for multi-simulation comparison
- `dashboard/src/config.ts` is the main source of truth for backend integration and default UI behavior: API version, available servers, auth requirements, default search fields, default result columns, default metadata rows, and the `/dashboard` deployment prefix.

The search flow spans several components:

- `SearchInput.vue` builds URL query strings from configured metadata fields and comparators.
- `SearchView.vue` owns the current query string and pushes it into browser history.
- `SearchOutput.vue` parses the query string, checks auth for the selected server, calls the SimDB `/simulations` endpoint, and renders a Vuetify data table with expandable metadata rows.

The detail and comparison flows both fetch full simulation records from `/simulation/:id`:

- `DetailView.vue` loads a single simulation by UUID or alias, renders metadata through `DataRow.vue`, and exposes related inputs/outputs/parent-child links.
- `CompareView.vue` loads multiple simulations from repeated `uuid` query parameters and renders both tabular rows and plots.
- `ComparePlot.vue`, `DataRow.vue`, and `common.ts` handle backend `numpy.ndarray` payloads by decoding base64 bytes into typed arrays and rendering them with Plotly.

Build output is meant to be deployed as a static app under `/dashboard`. `vite.config.ts` hardcodes `base: '/dashboard'` and injects the displayed app version from `git describe --tags --always`.

## Key conventions

- Keep server behavior centralized in `dashboard/src/config.ts`. New API servers, auth rules, default columns, and default metadata rows should be added there instead of hardcoding them in individual components.
- Preserve the URL-driven state model. Search state lives in the query string (`__server`, `__sort_asc`, metadata filters); detail routes use the path plus `server` query param; compare uses repeated `uuid` params. Changes to one screen often need matching updates in the others.
- Preserve the existing auth flow across search/detail/compare:
  - call the server root first to discover `authentication`
  - use `config.serverConfig` when a server has an explicit auth override
  - store tokens in `sessionStorage` under `simdb-token-${server}`
  - use `AuthDialog.vue` for credential entry and token generation
- Metadata keys are backend field names such as `code.name` or `ids_properties.creation_date`. UI labels are usually derived instead of manually authored: `toLabel()` splits on `.` and `_`, and also rewrites `field#2` to `field[2]`.
- Reuse the existing numpy/binary decoding pattern instead of inventing new parsing logic. `common.ts` contains the shared base64-to-typed-array helpers; `DataRow.vue`, `ComparePlot.vue`, and `SearchOutput.vue` are the main consumers.
- User-selected metadata rows are persisted in `localStorage` under `simdb-display-items`. Changes to default row handling should account for that persisted override in both `DetailView.vue` and `CompareView.vue`.
- Internal links assume the app is hosted under `/dashboard`. If you change routing, links, or the configured prefix, update the Vite base path and installation/nginx docs together.
