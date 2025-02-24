<template>
  <div class="dialog-overlay">
    <div class="dialog">
      <h2>{{ region.name }}</h2>
      <p>TODO: Add tutorial for using Region</p>
      <button @click="$emit('close')">Close</button>
    </div>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  region: { name: string; description: string };
}>();
</script>

<style>
.dialog-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
}

.dialog {
  background: white;
  padding: 20px;
  border-radius: 8px;
  text-align: center;
}
</style>
