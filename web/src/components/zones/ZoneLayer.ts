import { GeoJsonObject } from "geojson";
import L from "leaflet";
import { Landfill } from "../../api/generated";
import { MunicipalityLayer } from "../municipalities/MunicipalityLayer";


export class ZoneLayer {
  public id: string
  public confidence: number
  public source?: string
  public date?: string
  public layer: L.GeoJSON
  public parent: MunicipalityLayer
  private readonly colorHex: string

  constructor(landfill: Landfill, parent: MunicipalityLayer, colorHex: string) {
    this.id = landfill.id.toString()
    this.confidence = (landfill.confidence ?? 0) / 100
    this.layer = L.geoJSON(landfill.geometry as GeoJsonObject)
    this.source = landfill.detected_from
    this.date = landfill.detection_time
    this.parent = parent
    this.colorHex = colorHex

    this.show()
  }

  public show() {
      this.layer
      .setStyle({color:this.colorHex, fillOpacity: 0.2, weight: 2})
      .addEventListener('mouseover', async() => {
        this.layer.setStyle({fillOpacity: 0.9})
      })
      .addEventListener('mouseout', async() => {
        this.layer.setStyle({fillOpacity: 0.6})
      })
  }
}