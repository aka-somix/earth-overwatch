<script setup lang="ts">
import { onMounted } from 'vue';
import { mapsStore } from '../store/maps';


const mapStore = mapsStore();

const {initMap} = mapStore;

onMounted(async ()=> {
  await initMap()
});

</script>

<template>
  <div class="container">
    <div id="map"></div>
  </div>
</template>

<style scoped>
    /* .container {
      padding: 5vh;
    } */

    #map {
        height: 100vh;
    }
</style>