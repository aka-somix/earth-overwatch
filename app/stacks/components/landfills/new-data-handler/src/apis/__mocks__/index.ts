import { Monitor } from "../models/Monitor";
import { MonitorGeoSearch } from "../models/MonitorGeoSearch";

export class MOCKS {
    public static async postMonitoringGeosearch(
        type: 'LANDFILL',
        requestBody: MonitorGeoSearch,
    ): Promise<Array<Monitor>> {

        return [
            {
                id: 1,
                dateRequested: '2025-01-01',
                idMunicipality: 2,
                type: Monitor.type.LANDFILL
            }
        ]
    }
}