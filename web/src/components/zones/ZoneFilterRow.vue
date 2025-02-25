<script setup lang="ts">
import { defineProps, ref } from "vue";

const showZones = ref<boolean>(false);
const zoneColor = ref<string>("#008dc9");
const pickerActive = ref<boolean>(false);
const props = defineProps<{ title: string; enabled?: boolean }>();
</script>

<template>
  <div class="row">
    <q-color
      v-show="pickerActive"
      v-model="zoneColor"
      no-header-tabs
      class="picker"
    />
    <p class="text-tertiary">{{ props.title }}</p>
    <q-btn-toggle
      v-model="showZones"
      toggle-color="primary"
      dense
      :disable="!enabled"
      :options="[
        { label: 'ON', value: true },
        { label: 'OFF', value: false },
      ]"
    />
    <div
      class="color"
      :style="{ backgroundColor: enabled ? zoneColor : '#999' }"
      @click="
        () => {
          pickerActive = !pickerActive;
        }
      "
    ></div>
  </div>
</template>

<style lang="css" scoped>
.row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.row > p {
  font-size: 1.3rem;
  font-weight: 400;
  flex-basis: 60%;
  margin: 0;
}

.row > .color {
  width: 3rem;
  height: 3rem;
  border-radius: 100%;
  cursor: pointer;
}
.row > .color:hover {
  box-shadow: inset 0 0 0 100vmax rgba(0, 0, 0, 0.2);
}

.picker {
  position: fixed;
  top: 7rem;
  right: 7rem;
  z-index: 100000;
}
</style>
