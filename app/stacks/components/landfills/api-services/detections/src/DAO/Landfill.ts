import { DetectionValidity, Landfill, LandfillFilter, NewLandfillRequest } from "../@types";
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

    private statusFromString (status: string): DetectionValidity {
        switch (status) {
            case 'U':
                return DetectionValidity.UNKNOWN;
            case 'V':
                return DetectionValidity.VALID;
            case 'I':
                return DetectionValidity.INVALID;
            default:
                throw new Error("Invalid Status from Database");
        }
    }

    /**
     * Helper method to parse filters and dynamically build the WHERE clause
     */
    private parseFilters (filters: LandfillFilter): { query: string, params: any[]; } {
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
    public async getLandfills (filters: LandfillFilter): Promise<Array<Landfill>> {
        // Build the dynamic WHERE clause
        const { query: whereClause, params } = this.parseFilters(filters);

        // SQL query
        const query = `
            SELECT id, id_municipality AS municipality_id, source, detection_time, 
                   ${customGeometry.toGeoJSON('area')} as geometry, confidence, status, image_uri
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
            geometry: JSON.parse(e.geometry),
            status: this.statusFromString(e.status),
            confidence: parseInt(e.confidence) / 100,
            imageURI: e.image_uri
        }));
    }

    /**
     * Get event by ID
     */
    public async getLandfillById (id: number): Promise<Landfill | null> {
        const query = `
            SELECT id, id_municipality AS municipality_id, source, detection_time, 
                   ${customGeometry.toGeoJSON('area')} as geometry, confidence, status, image_uri
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
            geometry: JSON.parse(e.geometry),
            status: this.statusFromString(e.status),
            confidence: parseInt(e.confidence) / 100,
            imageURI: e.image_uri
        };
    }

    /**
     * Create a new Landfill
     */
    public async createLandfill (landfill: NewLandfillRequest): Promise<Landfill> {
        // Generate Query
        const query = `
            INSERT INTO ${landfillTable} (id_municipality, source, detection_time, area, point_location, confidence, image_uri, status)
            VALUES ($1, $2, $3, ${customGeometry.fromGeoJSON('$4')}, null, $5, $6, $7)
            RETURNING id_municipality, source, detection_time, ${customGeometry.toGeoJSON('area')} as geometry, confidence, image_uri, status
        `;

        const queryArgs = [
            landfill.municipality_id,
            landfill.detected_from,
            landfill.detection_time,
            landfill.geometry,
            landfill.confidence,
            landfill.imageURI,
            "U"                    //UNKNOWN
        ];

        logger.info(`QUERY: ${query}, ARGS: ${JSON.stringify(queryArgs)}`);

        // Execute the query
        const dbResult = await executeQuery(query, queryArgs);

        if (dbResult.length === 0) {
            throw new Error("Failed to insert landfill record");
        }

        const landfillCreated = dbResult[0];
        return {
            id: landfillCreated.id,
            municipality_id: landfillCreated.id_municipality,
            detected_from: landfillCreated.source,
            detection_time: landfillCreated.detection_time.toISOString(),
            geometry: JSON.parse(landfillCreated.geometry),
            status: this.statusFromString(landfillCreated.status),
            confidence: parseInt(landfillCreated.confidence) / 100,
            imageURI: landfillCreated.image_uri
        };
    }
}
