<script setup lang="ts">
import { defineEmits, defineProps } from "vue";
import ZoneFilterRow from "../zones/ZoneFilterRow.vue";
import { MunicipalityLayer } from "./MunicipalityLayer";

// PROPS
const {municipality} = defineProps<{ municipality: MunicipalityLayer }>();

// EMITS
const emit = defineEmits<{
  (e: 'showZones', municipality: MunicipalityLayer): void,
  (e: 'hideZones', municipality: MunicipalityLayer): void,
}>();

// FUNCTIONS
const toggleZones = (onoff: boolean) => {
  if (onoff) emit('showZones', municipality);
  else emit('hideZones', municipality);
}

</script>

<template>
  <div class="dialogbody">
    <div class="section visual">
      <div class="title text-primary">Visualizzazione</div>
      <ZoneFilterRow 
        class="row" 
        enabled 
        title="Discariche Abusive"
        @show-zones="() => {toggleZones(true)}"
        @hide-zones="() => {toggleZones(false)}"
      />
    </div>
    <div class="section monitors">
      <div class="title text-primary">Monitoraggi</div>
    </div>
  </div>
</template>

<style scoped>
.dialogbody {
  margin-left: 1rem;
  overflow-y: scroll;
  overflow-x: unset;
}

.section {
  margin-top: 5vh;
  margin-bottom: 2.5vh;
}

.title {
  font-size: 1.7rem;
  font-weight: 800;
}

.row {
  margin-top: 1vh;
}
</style>
