import L from "leaflet";
import { Municipality } from "../../api/geo";
import { RegionLayer } from "../regions/RegionLayer";

export class MunicipalityLayer {
  public id: string
  public name: string
  public layer: L.GeoJSON
  public parent: RegionLayer

  constructor(m: Municipality, parent: RegionLayer) {
    this.id = m.id.toString()
    this.name = m.name
    this.layer = L.geoJSON(m.boundaries)
    this.parent = parent
  }


  public async flyTo() {
    // Disable other municipalities
    this.parent.selectMunicipality(this);

    // Remove layer
    this.layer
      .setStyle({
        color:"#eec211",
        fillOpacity: 0,
        weight: 5
      })
      .removeEventListener('click')
      .removeEventListener('mouseover')
      .removeEventListener('mouseout')
  }

  public enable() {
      this.layer
      .setStyle({color:"#9c641a", fillOpacity: 0.2, weight: 2})
      .addEventListener('mouseover', async() => {
        this.layer.setStyle({fillOpacity: 0.9})
      })
      .addEventListener('mouseout', async() => {
        this.layer.setStyle({fillOpacity: 0.2})
      })
      .addEventListener('click', async() => this.flyTo())
  }

  public disable() {
    this.layer      
      .setStyle({color:"#404040", fillOpacity: 0.6, weight: 2})
      .addEventListener('mouseout', async() => {
        this.layer.setStyle({fillOpacity: 0.6})
      })
  }
}