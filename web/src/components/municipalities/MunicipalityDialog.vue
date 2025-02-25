<script setup lang="ts">
import ZoneFilterRow from "../zones/ZoneFilterRow.vue";
</script>

<template>
  <div class="dialogbody">
    <div class="section visual">
      <div class="title text-primary">Visualizzazione</div>
      <ZoneFilterRow title="Discariche Abusive" enabled class="row" />
      <ZoneFilterRow title="Incendi" class="row" />
      <ZoneFilterRow title="Zone a rischio frana" class="row" />
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
