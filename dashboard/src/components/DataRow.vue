<!-- eslint-disable no-prototype-builtins -->
<script setup lang="ts">
import { ref, watch } from 'vue'
import { to_i32_array, to_f32_array, to_f64_array } from '../common'
import { config } from '../config'

import PlotlyLoader from './PlotlyLoader.vue'
import { truncateSummary } from '../utils/utils'

type Data = { element: string; value: any }
type UUIDValue = { _type: string; hex: string }
type NumpyValue = { _type: string; bytes: string; dtype: string }
type Trace = { name: string; x?: number[]; y: number[] }

const props = defineProps<{
  name: string
  value?: number | string | NumpyValue | UUIDValue
  index: number
  data: Data[]
  server: string | null
  meta_name: string
  simId?: string
  showRemoveButton?: boolean
}>()

const emit = defineEmits(['remove'])

type QuantityData = {
  name: string
  units: string
  data: any
}

// API response shape matching ImasDataResponse from the backend
type ApiResult = {
  simulation?: string
  file_uuid?: string
  path?: string
  occurrence?: number
  field: QuantityData
  coordinates: QuantityData[]
}

const fetchedValue = ref<ApiResult | null>(null)
const isFetching = ref(false)

/** Convert dot-notation metadata key → summary IDS slash-path.
 *  "global_quantities.ip.value"         → "summary/global_quantities/ip/value"
 */
function toDataPath(metaName: string): string {
  const name = metaName.startsWith('summary.') ? metaName.substring(8) : metaName
  return 'summary/' + name.replace(/\./g, '/')
}

async function fetchData() {
  if (!props.simId || !props.server) return
  isFetching.value = true
  fetchedValue.value = null
  try {
    const url = `${props.server}/v${config.api_version}/simulation/${props.simId}/data?path=${encodeURIComponent(toDataPath(props.meta_name))}`
    const resp = await fetch(url)
    if (!resp.ok) throw new Error(`HTTP ${resp.status}: ${resp.statusText}`)
    fetchedValue.value = await resp.json()
  } catch {
    // Keep displaying the metadata value when this path has no data.
  } finally {
    isFetching.value = false
  }
}

function isNumpyArray(val: any): boolean {
  return val !== null && typeof val === 'object' && val._type === 'numpy.ndarray'
}

function toNumberArray(val: any): number[] {
  if (Array.isArray(val)) return val as number[]
  if (isNumpyArray(val)) {
    if (val.dtype === 'int32') return Array.from(to_i32_array(val.bytes))
    if (val.dtype === 'float32') return Array.from(to_f32_array(val.bytes))
    if (val.dtype === 'float64') return Array.from(to_f64_array(val.bytes))
  }
  return []
}

function getFetchedTraces(): Trace[] {
  if (!fetchedValue.value) return []
  const fieldData = fetchedValue.value.field?.data
  const yArr = toNumberArray(fieldData)
  if (yArr.length === 0) return []
  const trace: Trace = { name: props.name, y: yArr }
  const coordData = fetchedValue.value.coordinates?.[0]?.data
  if (coordData !== null && coordData !== undefined) {
    const xArr = toNumberArray(coordData)
    if (xArr.length === yArr.length) trace.x = xArr
  }
  return [trace]
}

/** Label for x-axis */
function getCoordinateLabel(): string {
  const coord = fetchedValue.value?.coordinates?.[0]
  if (!coord) return ''
  const name = coord.name.replace(/^summary\//, '')
  return coord.units ? `${name} [${coord.units}]` : name
}

/** Label for y-axis  */
function getFieldLabel(): string {
  const field = fetchedValue.value?.field
  if (!field) return props.meta_name
  const name = field.name.replace(/^summary\//, '')
  return field.units ? `${name} [${field.units}]` : name
}

function isFetchedArray(): boolean {
  if (!fetchedValue.value) return false
  const v = fetchedValue.value.field?.data
  return Array.isArray(v) || isNumpyArray(v)
}

function processValue(value: any) {
  if (value !== 0 && !value) {
    return 'No data available.'
  }
  
  if (value && typeof value === 'object' && 'min' in value && 'max' in value) {
    return `Range: [${value.min}, ${value.max}]`
  }
  
  if (value.hasOwnProperty('_type') && value._type === 'numpy.ndarray') {
    if (value.dtype === 'int32') {
      return to_i32_array(value.bytes)
    } else if (value.dtype === 'float32') {
      return to_f32_array(value.bytes)
    } else if (value.dtype === 'float64') {
      return to_f64_array(value.bytes)
    } else {
      return 'Unknown data type: ' + value.dtype
    }
  }
  return value
}

function isXML() {
  return typeof props.value === 'string' && props.value.startsWith('<?xml')
}

function isArray() {
  // Check if it's a numpy array (compatibility with old database)
  if (
    props.value &&
    typeof props.value !== 'string' &&
    typeof props.value !== 'number' &&
    props.value._type === 'numpy.ndarray' &&
    props.name !== 'time'
  ) {
    return true
  }
  
  // Check if it's a range object 
  // Arrays are stored as { min: value, max: value } in metadata
  if (
    props.value &&
    typeof props.value === 'object' &&
    'min' in props.value &&
    'max' in props.value &&
    props.name !== 'time'
  ) {
    return true
  }
  
  return false
}

function isUUID() {
  return (
    props.value &&
    typeof props.value !== 'string' &&
    typeof props.value !== 'number' &&
    props.value._type === 'uuid.UUID'
  )
}

function isShortString() {
  return props.value && props.value.toString && props.value.toString().length < 20
}

function getHex(value: number | string | NumpyValue | UUIDValue | undefined): string {
  return (value && typeof value === 'object' && 'hex' in value) ? value.hex : '';
}

function handleRemove() {
  emit('remove', props.index)
}

watch(
  [() => props.value, () => props.simId, () => props.server, () => props.meta_name],
  () => {
    fetchData()
  },
  { immediate: true }
)
</script>

<template>
  <tr>
    <td style="min-width: 25em">{{ name }}</td>
    <td style="min-width: 35em">
      <v-container style="width: 70%;white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;" class="ml-0">
        <template v-if="isXML()">
          <v-card height="400px" class="scroll">
            <pre style="max-height: 400px"
              >{{ value }}
            </pre>
          </v-card>
        </template>
        <template v-else-if="isArray()">
          <span style="white-space: pre-wrap">{{ processValue(value) }}</span>
        </template>
        <template v-else-if="isUUID()">
          <a :href="'/' + config.prefix + '/uuid/' + getHex(value)" :title="getHex(value)">{{ getHex(value) }}</a>
        </template>
        <template v-else-if="isShortString()">
          <a :href="'/' + config.prefix + '?__server=' + server + '&' + meta_name + '=eq:' + value">{{
            processValue(value)
          }}</a>
        </template>
        <template v-else-if="value !== null && value !== undefined">
          <span style="white-space: pre-wrap">
            {{ processValue(value) }}
          </span>
        </template>
        <template v-else> No data available. </template>
        <PlotlyLoader
          v-if="isFetchedArray()"
          :id="'plot' + index"
          :traces="getFetchedTraces()"
          :ylabel="getFieldLabel()"
          :xlabel="getCoordinateLabel()"
        ></PlotlyLoader>
        <v-progress-circular
          v-if="isFetching"
          class="ml-2"
          indeterminate
          size="14"
          width="2"
        ></v-progress-circular>
      </v-container>
    </td>
    <td v-if="showRemoveButton !== false" style="width: 1em; text-align: center;">
      <v-btn
        icon
        size="x-small"
        variant="text"
        color="error"        
        title="Remove metadata"
        @click="handleRemove"
      >      
        <v-icon size="large">mdi-minus-box</v-icon>
      </v-btn>
    </td>
  </tr>
</template>
