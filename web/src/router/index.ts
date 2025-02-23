import { createRouter, createWebHistory } from 'vue-router';
import HomeLayout from '../layouts/HomeLayout.vue';
import AboutView from '../views/AboutView.vue';
import MapView from '../views/MapView.vue';
import SplashScreenView from '../views/SplashScreenView.vue';
import ZonesView from '../views/ZonesView.vue';

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      component: HomeLayout,
      redirect: '/welcome',
      children: [
        {
          path: '/map',
          name: 'Map',
          component: MapView
        },
        {
          path: '/zones',
          name: 'Zones',
          component: ZonesView
        },
        {
          path: '/about',
          name: 'About',
          component: AboutView
        },
      ]
    },
    {
      path: '/welcome',
      component: SplashScreenView
    }
  ]
});

export default router;