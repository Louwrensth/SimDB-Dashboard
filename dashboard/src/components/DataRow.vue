<!-- eslint-disable no-prototype-builtins -->
<script setup lang="ts">
import { ref, onMounted } from 'vue'
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

// API response shape (IDS provenance + data)
type ApiResult = {
  value: any
  shape?: number[]
  coordinate?: string | null
  coordinateData?: any
  // IDS provenance fields returned by the API
  path?: string
  file_uuid?: string
  occurrence?: number
  simulation?: string
}

const fetchedValue = ref<ApiResult | null>(null)
const isFetching = ref(false)
const fetchError = ref<string | null>(null)

/** Convert dot-notation metadata key → summary IDS slash-path.
 *  "global_quantities.ip.value"         → "summary/global_quantities/ip/value"
 */
function toDataPath(metaName: string): string {
  const name = metaName.startsWith('summary.') ? metaName.substring(8) : metaName
  return 'summary/' + name.replace(/\./g, '/')
}

async function fetchApiRaw(path: string): Promise<ApiResult> {
  const url = `${props.server}/v${config.api_version}/simulation/${props.simId}/data?path=${encodeURIComponent(path)}`
  const resp = await fetch(url)
  if (!resp.ok) throw new Error(`HTTP ${resp.status}: ${resp.statusText}`)
  return resp.json() // API returns { value, shape, coordinate, ... }
}

async function fetchData() {
  if (!props.simId || !props.server) return
  isFetching.value = true
  fetchError.value = null
  fetchedValue.value = null
  try {
    const response = await fetchApiRaw(toDataPath(props.meta_name))
    let coordinateData: any = null
    if (response.coordinate) {
      try {
        const coordResponse = await fetchApiRaw(response.coordinate)
        coordinateData = coordResponse.value
      } catch {
        // coordinate is optional — silently ignore failures
      }
    }
    fetchedValue.value = { ...response, coordinateData }
  } catch (e: any) {
    fetchError.value = e.message ?? String(e)
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
  const { value, coordinateData } = fetchedValue.value
  const yArr = toNumberArray(value)
  if (yArr.length === 0) return []
  const trace: Trace = { name: props.name, y: yArr }
  if (coordinateData !== null && coordinateData !== undefined) {
    const xArr = toNumberArray(coordinateData)
    if (xArr.length > 0) trace.x = xArr
  } else {
    trace.x = Array.from({ length: yArr.length }, (_, i) => i)
  }
  return [trace]
}

/** Label for x-axis */
function getCoordinateLabel(): string {
  if (!fetchedValue.value?.coordinate) return ''
  const parts = fetchedValue.value.coordinate.split('/')
  return parts[parts.length - 1]
}

function isFetchedArray(): boolean {
  if (!fetchedValue.value) return false
  const v = fetchedValue.value.value
  return Array.isArray(v) || isNumpyArray(v)
}

function isFetchedScalar(): boolean {
  if (!fetchedValue.value) return false
  const v = fetchedValue.value.value
  return typeof v === 'number' || typeof v === 'string'
}

function getTraces(value: any): Trace[] {
  const trace: Trace = {
    name: props.name,
    y: processValue(value)
  }
  const x_trace = getXData()
  if (x_trace) {
    trace['x'] = x_trace
  }
  return [trace]
}

function getXData() {
  let root = props.name.split('.')[0]
  let time = props.data.find((el) => el.element === root + '.time')
  return time ? processValue(time.value) : null
}

function processValue(value: any) {
  if (value !== 0 && !value) {
    return 'No data available.'
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
  return (
    props.value &&
    typeof props.value !== 'string' &&
    typeof props.value !== 'number' &&
    props.value._type === 'numpy.ndarray' &&
    props.name !== 'time'
  )
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

// Auto-fetch when this row is mounted, but only for array-typed metadata fields
onMounted(() => {
  if (isArray() && props.simId && props.server) {
    fetchData()
  }
})
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
          <div v-if="isFetching" class="d-flex align-center ga-2">
            <v-progress-circular indeterminate size="18" width="2"></v-progress-circular>
            <span class="text-caption">Loading…</span>
          </div>
          <div v-else-if="fetchError" class="d-flex align-center ga-2">
            <span class="text-error text-caption">{{ fetchError }}</span>
            <v-btn size="x-small" variant="text" @click="fetchData">Retry</v-btn>
          </div>
          <template v-else-if="isFetchedArray()">
            <PlotlyLoader
              :id="'plot' + index"
              :traces="getFetchedTraces()"
              :ylabel="meta_name"
              :xlabel="fetchedValue!.coordinate ? getCoordinateLabel() : 'index'"
            ></PlotlyLoader>
          </template>
          <template v-else-if="isFetchedScalar()">
            <span>{{ fetchedValue!.value }}</span>
          </template>
          <template v-else-if="fetchedValue">
            <span class="text-caption text-medium-emphasis">No data at: {{ toDataPath(meta_name) }}</span>
          </template>
        </template>
        <template v-else-if="isUUID()">
          <a :href="'/' + config.prefix + '/uuid/' + getHex(value)" :title="getHex(value)">{{ getHex(value) }}</a>
        </template>
        <template v-else-if="isShortString()">
          <a :href="'/' + config.prefix + '../?__server=' + server + '&' + meta_name + '=eq:' + value">{{
            processValue(value)
          }}</a>
        </template>
        <template v-else-if="value !== null && value !== undefined">
          <span style="white-space: pre-wrap">
            {{ processValue(value) }}
          </span>
        </template>
        <template v-else> No data available. </template>
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
