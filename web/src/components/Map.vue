<script setup lang="ts">
import L, { Layer, Map } from 'leaflet';
import { computed, onMounted, ref } from 'vue';
import { landfillService } from '../api';
import { getAllRegions } from '../api/geo';
import { SELECTION_SCOPE } from './@types';
import Dialog from './core/Dialog.vue';
import MunicipalityDialog from './municipalities/MunicipalityDialog.vue';
import { MunicipalityLayer } from './municipalities/MunicipalityLayer';
import RegionDialog from './regions/RegionDialog.vue';
import { RegionLayer } from './regions/RegionLayer';
import ZoneDialog from './zones/ZoneDialog.vue';
import { ZoneLayer } from './zones/ZoneLayer';

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
    opacity: 0.8,
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
  }),
};

/*
 * REFS
 */
const isMapLoading = ref<boolean>(false);
const regionLayers = ref<Array<RegionLayer>>([]);
  
const selectedRegion = ref<RegionLayer | null>(null);
const selectedMunicipality = ref<MunicipalityLayer | null>(null);
const selectedZone = ref<ZoneLayer | null>(null);

const isDialogOpen = computed(() => selectedRegion.value !== null);
const dialogScope = computed((): SELECTION_SCOPE => {
  if (selectedRegion.value !== null && selectedMunicipality.value !== null && selectedZone.value !== null) return "ZONE";
  if (selectedRegion.value !== null && selectedMunicipality.value !== null) return "MUNICIPALITY";
  else if (selectedRegion.value !== null) return "REGION";
  else return 'NONE';
}) 

const loadRegions = async () => {
    // Retrieve regions from api
    const regions = await getAllRegions();
    const layers =  regions.map(r => {
      const regionLayer = new RegionLayer(r, map)
      regionLayer.regionSelectController = regionSelectController;
      regionLayer.municipalitySelectController = municipalitySelectController;
      return regionLayer;
    });
    // Enable all regions
    enableAllRegions(layers)
    // Add to map
    layers.forEach(r => map.addLayer(r.layer));
    return layers
}

const resetMap = () => {
  map.setView([41.9, 12.5], 7);
  enableAllRegions(regionLayers.value as RegionLayer[]);
  // Remove Zones
  selectedMunicipality.value?.hideZones(map)
  // Remove municipalities
  selectedRegion.value?.purgeMunicipalities()
  // Reset selectedRegion
  selectedRegion.value = null;
  selectedMunicipality.value = null;
}

const enableAllRegions = async (regions: Array<RegionLayer>) => {
    console.log("Enabling all regions")
    regions.forEach(r => r.enable());
}

/**
 * Manages click on region
 */
const regionSelectController = async (selected: RegionLayer) => {
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
  selectedMunicipality.value?.hideZones(map);
  selectedMunicipality.value = null;
}

//
// ZONES MANAGEMENT METHODS
//
const showZones = async (municipality: MunicipalityLayer) => {
    console.log(`Showing zones in municipality ${municipality.name}`);

    isMapLoading.value = true;
    
    const landfills = await landfillService.landfills.getDetections(parseInt(municipality.id));
    municipality.landfills = landfills
      .map((l) => {
        const zone = new ZoneLayer(l, municipality, "#008dc9")
        zone.selectController = zonesSelectController
        return zone;
      })
    municipality.landfills.forEach((l) => map.addLayer(l.layer))
    
    isMapLoading.value = false;
}

const hideZones = async (municipality: MunicipalityLayer) => {
    console.log(`Hiding zones in municipality ${municipality.name}`);
    isMapLoading.value = true;

    municipality.hideZones(map);
    selectedZone.value = null;

    isMapLoading.value = false;
}


/**
 * Manages click on municipality
 */
const municipalitySelectController = async (selected: MunicipalityLayer) => {
  console.log({selected});
  // Remove zones from last municipality
  selectedMunicipality.value?.hideZones(map);

  // Set selected region
  selectedMunicipality.value = selected;
}

/**
 * Manages click on municipality
 */
const zonesSelectController = async (selected: ZoneLayer) => {
  console.log({selected});
  // unselect the previous zone
  selectedZone.value?.unselect();
  // Set selected region
  selectedZone.value = selected;

}


/*
 * - HOOKS 
 */
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
        selectedMunicipality.value = null;
        //Re-enable all regions
        enableAllRegions(regionLayers.value as RegionLayer[])
      }
    });
});

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
          @click="() => selectedRegion?.select()"
        />
        <q-breadcrumbs-el 
          v-if="selectedMunicipality !== null"
          :label="selectedMunicipality?.name"
        />
      </q-breadcrumbs>
      <!-- BODY -->
      <RegionDialog v-if="dialogScope === 'REGION'" />
      <MunicipalityDialog 
        v-if="dialogScope === 'MUNICIPALITY'" 
        :key="selectedMunicipality?.id"
        :municipality="selectedMunicipality as MunicipalityLayer"
          @show-zones="showZones"
          @hide-zones="hideZones"
      />
      <ZoneDialog v-if="dialogScope === 'ZONE'" />
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
  font-size: 2rem;
}

.q-breadcrumbs:hover{
  cursor: pointer;
}
</style>
