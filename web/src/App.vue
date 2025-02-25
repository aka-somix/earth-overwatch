<template>
<q-layout view="hHh lpR lff">
  <!-- BODY -->
  <q-page-container class="mainbox">
    <router-view />
  </q-page-container>

</q-layout>
</template>

<style>
  .q-toolbar {
    cursor: pointer;
  }
  * {
    scrollbar-width: thin;
    scrollbar-color: rgba(0, 0, 0, 0.5) transparent;
  }
</style>
