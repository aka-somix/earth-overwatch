<script setup lang="ts">
import { ref } from 'vue';
import { useRouter } from 'vue-router';

const router = useRouter();

const drawerOpen = ref(false)

function toggleLeftDrawer () {
  drawerOpen.value = !drawerOpen.value
}

const bsn_views = [
  { icon: 'map', text: 'Map Exploration', route: "/" },
]
const others = [
  { icon: 'info', text: 'About this Project', route: "/about"},
]


</script>

<template>
<q-layout view="hHh lpR lff">

  <!-- HEADER -->
  <q-header bordered class="bg-primary text-white">
      <q-toolbar>
        <q-btn dense flat round icon="menu" @click="toggleLeftDrawer" />

        <q-toolbar-title @click="router.push('/')">
          Thesis Project
        </q-toolbar-title>
      </q-toolbar>
  </q-header>

  <!-- DRAWER -->
  <q-drawer v-model="drawerOpen" side="left" bordered :width="240" show-if-above>
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

  .mainbox {
    padding: 2rem;
  }

</style>
