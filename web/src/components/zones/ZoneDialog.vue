<script setup lang="ts">
import { ZoneLayer } from './ZoneLayer';


// PROPS
const {zone} = defineProps<{ zone: ZoneLayer }>();


</script>

<template>
  <div class="dialogbody">
    <div class="title text-secondary">📍 Finding#{{zone.id}}</div>
    <div class="section">
      <div class="subtitle text-primary">Immagine:</div>
      <p>Immagine sulla quale i nostri algoritmi hanno rilevato la zona d'interesse:</p>
      <div style="display: flex; justify-content: center; width: 100%;">
        <div class="image"></div>
      </div>
    </div>
    <div class="section monitors">
      <div class="subtitle text-primary">Dati associati</div>
      <!-- DATE -->
      <div class="row">
        <p>Data rilevazione:</p>
        <p class="val text-secondary">{{ zone.date ?? 'Sconosciuta' }}</p>
      </div>
      <!-- PRODUCT -->
      <div class="row">
        <p>Prodotto:</p>
        <p class="val text-secondary">{{ zone.source ?? 'Sconosciuta' }}</p>
      </div>
      <!-- Confidence -->
      <div class="row">
        <p>Confidenza:</p>
        <p class="val text-secondary">{{ zone.confidence ?? 0 }}%</p>
      </div>
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
  margin-top: 2vh;
  margin-bottom: 2.5vh;
}

.title {
  margin: 3vh 0 3vh 0;
  font-size: 2rem;
  font-weight: 800;

}

.subtitle {
  font-size: 1.4rem;
  font-weight: 800;
}

.row {
  margin: .5rem 2rem 0 2rem;
  display: flex;
  justify-content: space-between;
}

p {
  font-size: 1rem;
}

.val {
  font-weight: 800;
}

.image {
  width: 28vh;
  height: 28vh;
  background-color: black;
}
</style>