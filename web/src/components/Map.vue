<script setup lang="ts">
import L, { Layer, Map } from 'leaflet';
import { computed, onMounted, ref } from 'vue';
import { getAllRegions } from '../api/geo';
import Dialog from './core/Dialog.vue';
import RegionDialog from './regions/RegionDialog.vue';
import { RegionLayer } from './regions/RegionLayer';

/*
 * CONSTANTS 
 */
let map: Map;
// Layers object with predefined layers for satellite and streets
const layers: { [key: string]: Layer } = {
  "satellite": L.tileLayer('http://{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}', {
    minZoom: 5,
    maxZoom: 20,
    subdomains: ['mt0', 'mt1', 'mt2', 'mt3']
  }),

  "streets": L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
    minZoom: 5,
    maxZoom: 20,
    opacity: 1,
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
  }),
};

/*
 * REFS
 */
const isMapLoading = ref<boolean>(false);
const isDialogOpen = computed(() => selectedRegion.value !== null);
const regionLayers = ref<Array<RegionLayer>>([]);
const selectedRegion = ref<RegionLayer | null>(null);

onMounted(async ()=> {
    map = L.map('map').setView([41.9, 12.5], 7);
    map.zoomControl.remove()
    map.addControl(L.control.zoom({position: 'bottomright'}));
    map.addLayer(layers['satellite']).addLayer(layers['streets']);

    isMapLoading.value = true;
    regionLayers.value = await loadRegions();
    isMapLoading.value = false;

    map.on('zoom', () => {
      const curZoom = map.getZoom();
      if (selectedRegion.value !== null && curZoom < 8) {
        // Remove municipalities
        selectedRegion.value.purgeMunicipalities()
        // Reset selectedRegion
        selectedRegion.value = null;
        //Re-enable all regions
        enableAllRegions(regionLayers.value as RegionLayer[])
      }
    });
});

const loadRegions = async () => {
    // Retrieve regions from api
    const regions = await getAllRegions();
    const layers =  regions.map(r => new RegionLayer(r, map));
    // Enable all regions
    enableAllRegions(layers)
    // Add to map
    layers.forEach(r => map.addLayer(r.layer));
    return layers
}

const resetMap = () => {
  map.setView([41.9, 12.5], 7);
  enableAllRegions(regionLayers.value as RegionLayer[]);
  // Remove municipalities
  selectedRegion.value?.purgeMunicipalities()
  // Reset selectedRegion
  selectedRegion.value = null;
}

const enableAllRegions = async (regions: Array<RegionLayer>) => {
    console.log("Enabling all regions")
    regions.forEach(r => r.enable(regionClickCallback));
}

/**
 * Manages click on feature impact on the whole map
 */
const regionClickCallback = async (selected: RegionLayer) => {
  console.log({selected});
  // Center Region
  const bounds = selected.layer.getBounds();
  map.fitBounds(bounds, {animate: true, maxZoom: 10});

  // Disable all but region selected
  regionLayers.value
    .filter(r => r.id !== selected.id)
    .forEach(r => r.disable())

  // Set selected region
  selectedRegion.value = selected;
}

</script>

<template>
  <div class="container">
    <Dialog :visible="isDialogOpen">
      <!-- NAVIGATION BREADCRUMB -->
      <q-breadcrumbs active-color="primary">
        <q-breadcrumbs-el 
        label="Map" icon="map"
        @click="() => resetMap()"
        class="pointer"
        />
        <q-breadcrumbs-el 
        :label="selectedRegion?.name"
        />
      </q-breadcrumbs>
      <!-- BODY -->
      <RegionDialog/>
    </Dialog>
    <div class="loader" v-show="isMapLoading">
      <p>🌍 Your map is loading</p>
    </div>
    <div id="map"></div>
  </div>
</template>


<style scoped>
#map {
    height: 100vh;
}

.loader {
    background-color: #05573483;
    color: white;
    position: absolute;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    height: 100vh;
    width: 100vw;
    z-index: 1000;
}

.loader > p {
    font-size: 4rem;
    animation: fadeInOut 2s infinite ease-in-out;
}

/* Fade-in and fade-out animation */
@keyframes fadeInOut {
    0% { opacity: 0; }
    50% { opacity: 1; }
    100% { opacity: 0; }
}

.q-breadcrumbs{
  font-size: 2.2rem;
}

.q-breadcrumbs:hover{
  cursor: pointer;
}

</style>
