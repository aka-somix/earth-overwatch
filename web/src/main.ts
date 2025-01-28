import './assets/styles/main.css';
// Import icon libraries
import '@quasar/extras/material-icons/material-icons.css';
// Import Leaflet css
import 'leaflet';
import 'leaflet/dist/leaflet.css';
import { Quasar } from 'quasar';
// Import Quasar css
import { createPinia } from 'pinia';
import 'quasar/src/css/index.sass';
import { createApp } from 'vue';
import App from './App.vue';
import router from './router';

const app = createApp(App)

app.use(router)
app.use(createPinia());
app.use(Quasar, {})

app.mount('#app')
