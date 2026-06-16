import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { VitePWA } from "vite-plugin-pwa";

// Dokkho build config.
// The PWA plugin generates a service worker that caches the app shell so the
// whole interface loads with no connection. Lesson *content* is cached
// separately in IndexedDB (see src/storage.js) — the SW handles the code/UI,
// IndexedDB handles the downloaded courses.
export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: "autoUpdate",
      includeAssets: ["favicon.svg", "icon-192.png", "icon-512.png"],
      manifest: {
        name: "Dokkho — Learn, Get Work, Earn",
        short_name: "Dokkho",
        description:
          "Freelancing co-pilot and adaptive skills academy for Bangladeshi youth. Works offline.",
        theme_color: "#0f766e",
        background_color: "#f6f2ea",
        display: "standalone",
        orientation: "portrait",
        start_url: "/",
        lang: "bn",
        icons: [
          { src: "icon-192.png", sizes: "192x192", type: "image/png" },
          { src: "icon-512.png", sizes: "512x512", type: "image/png" },
          { src: "icon-512.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
        ],
      },
      workbox: {
        // cache the app shell + fonts; never cache /api or the dashboard
        navigateFallbackDenylist: [/^\/api/, /^\/dashboard/],
        runtimeCaching: [
          {
            urlPattern: /^https:\/\/fonts\.(googleapis|gstatic)\.com\/.*/,
            handler: "CacheFirst",
            options: {
              cacheName: "google-fonts",
              expiration: { maxEntries: 20, maxAgeSeconds: 60 * 60 * 24 * 365 },
            },
          },
        ],
      },
    }),
  ],
  build: {
    target: "es2018", // friendly to older Android WebViews on cheap phones
    rollupOptions: {
      input: {
        // Two pages: the learner app (index.html) and the operator dashboard.
        main: "index.html",
        dashboard: "dashboard.html",
      },
    },
  },
});
