import L from "leaflet";
import { getMunicipalitiesByRegion, Region } from "../../api/geo";
import { MunicipalityLayer } from "../municipalities/MunicipalityLayer";

export class RegionLayer {
  public id: string
  public name: string
  public layer: L.GeoJSON
  public municipalities: Array<MunicipalityLayer>
  public parent: L.Map

  /*
   * EVENT CONTROLLERS
   */
  public regionSelectController: (r: RegionLayer)=>Promise<void>
  public municipalitySelectController: (m: MunicipalityLayer)=>Promise<void>

  constructor(region: Region, parent: L.Map) {
    this.id = region.id.toString()
    this.name = region.name
    this.layer = L.geoJSON(region.boundaries)
    this.municipalities = [];
    this.parent = parent;

    this.regionSelectController = async() => {};
    this.municipalitySelectController = async() => {};
  }

  public async select() {
    // Lazily import municipalities
    if (this.municipalities.length === 0){
      await this.importMunicipalities();
    }
    this.municipalities.forEach(m => {
      m.enable();
      this.parent.addLayer(m.layer);
    });

    // Remove layer
    this.layer
      .setStyle({
        color:"#006e28",
        fillOpacity: 0,
        weight: 4
      })
      .removeEventListener('mouseover')
      .removeEventListener('mouseout')
      .removeEventListener('click')
    
    // Callback
    this.regionSelectController(this);
  }

  public enable() {
      this.layer
      .setStyle({color:"#116952", fillOpacity: 0.2, weight: 2})
      .addEventListener('mouseover', async() => {
        this.layer.setStyle({fillOpacity: 0.9})
      })
      .addEventListener('mouseout', async() => {
        this.layer.setStyle({fillOpacity: 0.2})
      })
      .addEventListener('click', async() => this.select())
  }

  public disable() {
    this.layer
      .setStyle({color: '#000'})
      .removeEventListener('mouseover')
      .removeEventListener('mouseout')
      .removeEventListener('click')
    this.purgeMunicipalities()
  }

  private async importMunicipalities() {
    const municipalities = await getMunicipalitiesByRegion(parseInt(this.id));
    console.log({municipalities})
    this.municipalities = municipalities.map(m => new MunicipalityLayer(m, this));
  }


  public purgeMunicipalities() {
    this.municipalities.forEach(m => this.parent.removeLayer(m.layer));
  }

  public selectMunicipality(selected: MunicipalityLayer) {
    // Center Region
    const bounds = selected.layer.getBounds();
    this.parent.fitBounds(bounds, {animate: true, maxZoom: 13, duration: 800});
    
    this.municipalities
      .filter(m => m.id !== selected.id)
      .forEach(m => m.disable())
    
    this.municipalitySelectController(selected);
  }
}