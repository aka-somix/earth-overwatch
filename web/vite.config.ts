import { quasar, transformAssetUrls } from "@quasar/vite-plugin";
import vue from '@vitejs/plugin-vue';
import { URL, fileURLToPath } from "node:url";
import { defineConfig } from 'vite';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    vue({
      template: { transformAssetUrls },
    }),
    quasar({
      sassVariables: "@/assets/styles/quasar-variables.sass",
    }),
  ],
  resolve: {
      alias: {
          "@": fileURLToPath(new URL("./src", import.meta.url)),
      },
  }
})
