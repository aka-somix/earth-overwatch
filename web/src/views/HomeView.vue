<script setup lang="ts">
import { ref } from 'vue';
import { useRouter } from 'vue-router';

const router = useRouter();

const isMenuDrawerOpen = ref(false)

function toggleMenuDrawer () {
  isMenuDrawerOpen.value = !isMenuDrawerOpen.value
}

const bsn_views = [
  { icon: 'map', text: 'Map Exploration', route: "/map" },
]
const others = [
  { icon: 'info', text: 'About this Project', route: "/about"},
]

</script>

<template>
<q-layout view="hHh lpR lff">

  <!-- LEFT DRAWER -->
  <q-drawer v-model="isMenuDrawerOpen" side="left" bordered :width="240">
      <q-scroll-area class="fit">
        <q-list padding class="text-grey-8">

          <q-item v-ripple v-for="page in bsn_views" :key="page.text" clickable @click="router.push(page.route)">
            <q-item-section avatar>
              <q-icon :name="page.icon" />
            </q-item-section>
            <q-item-section>
              <q-item-label>{{ page.text }}</q-item-label>
            </q-item-section>
          </q-item>

          <q-separator inset class="q-my-sm" />

          <q-item v-ripple v-for="page in others" :key="page.text" clickable @click="router.push(page.route)">
            <q-item-section avatar>
              <q-icon :name="page.icon" />
            </q-item-section>
            <q-item-section>
              <q-item-label>{{ page.text }}</q-item-label>
            </q-item-section>
          </q-item>
        </q-list>
      </q-scroll-area>
  </q-drawer>

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

</style>
