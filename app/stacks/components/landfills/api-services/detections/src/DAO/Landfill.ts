import { Event, EventFilter as LandfillFilter } from "../@types";
import { customGeometry, executeQuery } from "../libs/database";
import { logger } from "../libs/powertools";

/**
 * DATABASE ENTITIES
 */
const landfillTable = 'landfills';

/**
 * DATA ACCESS OBJECT
 */
export class LandfillDAO {

    /**
     * Helper method to parse filters and dynamically build the WHERE clause
     */
    private parseFilters(filters: LandfillFilter): { query: string, params: any[] } {
        let conditions: string[] = [];
        let params: any[] = [];

        if (filters.municipality) {
            conditions.push(`id_municipality = $${params.length + 1}`);
            params.push(filters.municipality);
        }

        const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
        return { query: whereClause, params };
    }

    /**
     * Get events based on filters
     */
    public async getEvents(filters: LandfillFilter): Promise<Array<Event>> {
        // Build the dynamic WHERE clause
        const { query: whereClause, params } = this.parseFilters(filters);

        // SQL query
        const query = `
            SELECT id, id_municipality AS municipality_id, source, detection_time, 
                   ${customGeometry.toGeoJSON('area')} AS geometry
            FROM ${landfillTable}
            ${whereClause};
        `;

        logger.info(`QUERY: ${query}`);

        // Execute the query
        const landfillsFound = await executeQuery(query, params);

        // Map the result to the Event type
        return landfillsFound.map((e) => ({
            id: e.id,
            municipality_id: e.municipality_id,
            detected_from: e.source,
            detection_time: e.detection_time.toISOString(),
            geometry: e.geometry,
        }));
    }

    /**
     * Get event by ID
     */
    public async getLandfillById(id: number): Promise<Event | null> {
        const query = `
            SELECT id, id_municipality AS municipality_id, source, detection_time, 
                   ${customGeometry.toGeoJSON('area')} AS geometry
            FROM ${landfillTable}
            WHERE id = $1
            LIMIT 1;
        `;

        // Execute the query
        const dbResult = await executeQuery(query, [id]);

        // Check if event was found
        if (dbResult.length === 0) return null;

        const e = dbResult[0];

        // Return the mapped Event object
        return {
            id: e.id,
            municipality_id: e.municipality_id,
            detected_from: e.source,
            detection_time: e.detection_time.toISOString(),
            geometry: e.geometry,
        };
    }
}
