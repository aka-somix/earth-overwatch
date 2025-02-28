<script setup lang="ts">
import { ref } from 'vue';
import { useRouter } from 'vue-router';

const router = useRouter();
const isMenuDrawerOpen = ref(false);

function toggleMenuDrawer() {
  isMenuDrawerOpen.value = !isMenuDrawerOpen.value;
}

const bsn_views = [
  { icon: 'map', text: 'Mappa', route: '/map' },
  { icon: 'place', text: 'Zone d\'interesse', route: '/zones' },

];
const others = [{ icon: 'info', text: 'About this Project', route: '/about' }];
</script>

<template>
  <q-layout view="hHh lpR lff">
    <q-btn
      round
      color="primary"
      icon="menu"
      size="xl"
      class="nav"
      :class="{ 'nav-open': isMenuDrawerOpen }"
      @click="toggleMenuDrawer"
    />

    <!-- LEFT DRAWER -->
    <q-drawer v-model="isMenuDrawerOpen" side="left" bordered overlay :width="300">
      <q-scroll-area class="fit">
        <q-list padding class="text-grey-8">
          <q-item
            v-ripple
            v-for="page in bsn_views"
            :key="page.text"
            clickable
            @click="router.push(page.route)"
          >
            <q-item-section avatar>
              <q-icon :name="page.icon" />
            </q-item-section>
            <q-item-section>
              <q-item-label>{{ page.text }}</q-item-label>
            </q-item-section>
          </q-item>

          <q-separator inset class="q-my-sm" />

          <q-item
            v-ripple
            v-for="page in others"
            :key="page.text"
            clickable
            @click="router.push(page.route)"
          >
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
.q-btn.nav {
  margin-top: 1vh;
  position: fixed;
  left: 10px;
  transition: transform 0.3s ease, left 0.3s ease;
  z-index: 5000;
}

.q-btn.nav.nav-open {
  left: 320px; /* Adjust based on drawer width */
}

</style>
