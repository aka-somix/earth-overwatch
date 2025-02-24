<template>
  <div class="map-container">
    <l-map ref="mapRef" :zoom="zoom" :center="[41.9, 12.5]">
      <l-tile-layer :url="tileLayerUrl" />
    </l-map>
  </div>
</template>

<script setup lang="ts">
import { LMap, LTileLayer } from "@vue-leaflet/vue-leaflet";
import { ref, useTemplateRef } from "vue";

const zoom = ref(6);
const tileLayerUrl = "https://tile.openstreetmap.org/{z}/{x}/{y}.png";


const map = useTemplateRef("mapRef");


// // Define GeoJSON Options
// const _geoJsonOptions = {
//   style: () => ({
//     color: "black",
//     weight: 1,
//     fillOpacity: 0.2,
//   }),
//   onEachFeature: (feature: any, layer: any) => {
//     layer.on({
//       mouseover: (_e: any) => {
//         layer.setStyle({ fillOpacity: 0.6 });
//         layer.bindTooltip(feature.properties.name).openTooltip();
//       },
//       mouseout: () => {
//         layer.setStyle({ fillOpacity: 0.2 });
//         layer.unbindTooltip();
//       },
//       click: (e: any) => selectRegion(feature, e.target),
//     });
//   },
// };

// // Selection Logic
// const selectRegion = (feature: any, layer: any) => {
//   selectedRegion.value = feature;
//   selectedRegionData.value = feature.properties;
//   center.value = layer.getBounds().getCenter();
//   zoom.value = 8;
// };
 
// // Options for Selected Region
// const _selectedRegionOptions = computed(() => ({
//   style: {
//     color: "blue",
//     weight: 2,
//     fillOpacity: 0.5,
//   },
// }));

// // Reset Selection
// const _resetSelection = () => {
//   selectedRegion.value = null;
//   selectedRegionData.value = null;
//   zoom.value = 6;
//   center.value = new Point(41.9, 12.5);
// };

</script>

<style>
.map-container {
  height: 100vh;
}
</style>
