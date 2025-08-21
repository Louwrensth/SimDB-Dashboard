export { config }

const config: Readonly<{ [key: string]: any }> = {
  api_version: '1.2',
  servers: [
    'https://simdb.iter.org/scenarios/api',
    //'https://simdb.iter.org/itpa/api',    
  ],
  serverConfig: {
    'https://simdb.iter.org/scenarios/api': { 'requiresAuth': false },
    //'https://simdb.iter.org/itpa/api': { 'requiresAuth': false },
  },
  defaultServer: 'https://simdb.iter.org/scenarios/api',
  searchFields: ['alias','summary.code.name','summary.heating_current_drive.power_additional.value','summary.global_quantities.ip.value', 'summary.global_quantities.b0.value','summary.description'],
  searchOutputFields: [
    'summary.code.name',
    'status',
    'uploaded_by'
  ],
  displayHeaders: [
    { label: 'Simulation', value: 'uuid' },
    { label: 'Server', value: 'server' },
    { label: 'Alias', value: 'alias' },
    { label: 'Upload Info', value: 'upload_info' },
  ],
  // displayFields: 'all',
  displayFields: [    
    'summary.code.name',
    'ids',
    'summary.description',
    'status',
    'summary.ids_properties.creation_date'
  ],
  prefix: 'dashboard',
  searchOutputColumns: ['alias/UUID', 'status', 'Upload Date'],
  rootURL: function (server: string) {
    return server + '/'
  },
  rootAPI: function (server: string) {
    return server + '/v' + config.api_version
  }
}
