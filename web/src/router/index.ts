import { createRouter, createWebHistory } from 'vue-router';
import AboutView from '../views/AboutView.vue';
import HomeView from '../views/HomeView.vue';
import SplashScreenView from '../views/SplashScreenView.vue';



const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      component: SplashScreenView
    },
    {
      path: '/home',
      component: HomeView
    },
    {
      path: '/about',
      name: 'About',
      component: AboutView
    },
  ]
});

export default router;