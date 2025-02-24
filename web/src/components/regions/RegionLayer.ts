import L from "leaflet";
import { Region } from "../../api/geo";

export class RegionLayer {
  public id: string
  public name: string
  public layer: L.GeoJSON

  constructor(region: Region) {
    this.id = region.id.toString()
    this.name = region.name
    this.layer = L.geoJSON(region.boundaries)
  }

  public async flyTo(next: (r: RegionLayer)=>Promise<void>) {
    // TODO Load Municipalities

    // Remove layer
    this.disable();
    this.layer.setStyle({
      color:"#00c3f9",
      fillOpacity: 0,
      weight: 4
    })
    
    // Callback
    next(this);
  }

  public enable(next: (r: RegionLayer)=>Promise<void>) {
      this.layer
      .setStyle({color: '#3fd4ac', fillOpacity: 0.2, weight: 2})
      .addEventListener('mouseover', async() => {
        this.layer.setStyle({fillOpacity: 0.9})
      })
      .addEventListener('mouseout', async() => {
        this.layer.setStyle({fillOpacity: 0.2})
      })
      .addEventListener('click', async() => this.flyTo(next))
  }

  public disable() {
    this.layer
      .setStyle({color: '#000'})
      .removeEventListener('mouseover')
      .removeEventListener('mouseout')
      .removeEventListener('click')
  }
}