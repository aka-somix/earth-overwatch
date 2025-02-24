import L, { Layer, Map } from 'leaflet';
import { defineStore } from 'pinia';

// GEO JSON STATIC IMPORT
import { GeoJsonObject } from 'geojson';
import { getAllRegions, getMunicipalitiesByRegion } from '../api/geo';

// Define the store
export const mapsStore = defineStore('map', () => {
  let map: Map | null = null;

  // Layers object with predefined layers for satellite and streets
  const layers: { [key: string]: Layer } = {
    "satellite": L.tileLayer('http://{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}', {
      minZoom: 5,
      maxZoom: 20,
      subdomains: ['mt0', 'mt1', 'mt2', 'mt3']
    }),

    "streets": L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      minZoom: 5,
      maxZoom: 20,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }),
  };

  // Initialize map and add default layers
  const initMap = async () => {
    map = L.map('map').setView([39.363849580093145, 16.226570855657855], 9);
    map.zoomControl.remove()
    map.addControl(L.control.zoom({position: 'bottomright'}));
    map.addLayer(layers['satellite']);

    // Call API to fetch regions
    const regions = await getAllRegions();

    // Loop through the regions and add each one as a GeoJSON layer
    regions.forEach(region => {
      // Parse the boundaries string into an actual GeoJSON object
      const geoJsonBoundary: GeoJsonObject = region.boundaries;

      // Create a Leaflet GeoJSON layer and add it to the map
      const regionLayer = L.geoJSON(geoJsonBoundary, {
        style: {
          color: '#ff7800',
          fillOpacity: 0.2,
          weight: 2
        },
      });

      regionLayer.on('mouseover', async() => {
        regionLayer.setStyle({fillOpacity: 0.9})
      });
      regionLayer.on('mouseout', async() => {
        regionLayer.setStyle({fillOpacity: 0.2})
      });

      regionLayer.on('click', async ()=> {
        const bounds = regionLayer.getBounds();
        map?.fitBounds(bounds);

        const municipalities = await getMunicipalitiesByRegion(region.id)
        regionLayer.setStyle({opacity: 0.1})
        municipalities.forEach(m => {
          console.log(m.boundaries)
          const mBoundaries: GeoJsonObject = m.boundaries;
          const mLayer = L.geoJSON(mBoundaries, {
            style: {
              color: '#0078AD',
              weight: 1,
              opacity: 0.5,
            },
          })
          mLayer.on('mouseover', async() => {
            mLayer.setStyle({fillOpacity: 0.9})
          });
          mLayer.on('mouseout', async() => {
            mLayer.setStyle({fillOpacity: 0.2})
          });
          map?.addLayer(mLayer);
        });
      })

      // Add the region layer to the map
      map?.addLayer(regionLayer);
    });
  };

  return {
    map,
    initMap,
  };
});