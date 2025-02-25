<template>
  <div :class="['dialog-overlay', { 'is-visible': visible }]">
    <div :class="['dialog-card', { 'is-visible': visible }]">
      <slot></slot>
    </div>
  </div>
</template>

<script setup lang="ts">
import { defineProps } from 'vue';

const props = defineProps<{ visible: boolean }>();
</script>

<style scoped>
.dialog-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  padding-right: 2vw;
  z-index: 1000;
  pointer-events: none;
  opacity: 0;
  transition: opacity 0.3s ease-in-out;
}

.dialog-overlay.is-visible {
  opacity: 1;
}

.dialog-card {
  width: 30vw;
  min-height: 30vh;
  max-height: 80vh;
  background-color: #fAfAfA ;
  box-shadow: 0px 4px 10px rgba(0, 0, 0, 0.3);
  border-radius: 10px;
  display: flex;
  flex-direction: column;
  padding: 2rem;
  pointer-events: auto;
  opacity: 0;
  transition: opacity 0.3s ease-in-out, transform 0.3s ease-in-out;
}

.dialog-card.is-visible {
  opacity: 1;
  transform: translateY(0);
}

@media screen and (max-width: 1600px) {
  .dialog-overlay {
    justify-content: center;
    align-items: flex-end;
    padding-right: 0;
    padding-bottom: 5vh;
  }
  .dialog-card {
    width: 90vw;
    min-height: 10vh;
    max-height: 40vh;
  }
}
</style>
