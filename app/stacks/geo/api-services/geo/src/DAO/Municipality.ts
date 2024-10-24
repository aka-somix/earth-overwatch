import { Municipality, MunFilters } from "../@types";
import { customGeometry, executeQuery } from "../database/client";
import { logger } from "../libs/powertools";
/**
 * DATABASE ENTITIES
 */
const municipalityTable = 'municipality';
const regionTable = 'region';

/**
 * DATA ACCESS OBJECT
 */
export class MunicipalityDAO {

    /**
     * Helper method to parse filters and dynamically build the WHERE clause
     */
    private parseFilters(filters: MunFilters): { query: string, params: any[] } {
        let conditions: string[] = [];
        let params: any[] = [];

        if (filters.idRegion) {
            conditions.push(`id_region = $${params.length + 1}`);
            params.push(filters.idRegion);
        }

        const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
        return { query: whereClause, params };
    }

    /**
     * Get municipalities based on filters
     */
    public async getMunicipalities(filters: MunFilters): Promise<Array<Municipality>> {

        // Build the dynamic WHERE clause
        const { query: whereClause, params } = this.parseFilters(filters);

        // SQL query
        const query = `
            SELECT id, name, ${customGeometry.toGeoJSON('boundaries')} AS boundaries
            FROM ${municipalityTable}
            ${whereClause};
        `;

        logger.info(`QUERY: ${query}`)

        // Execute the query
        const munFound = await executeQuery(query, params);

        // Map the result to the Municipality type
        return munFound.map((m) => ({
            id: m.id,
            name: m.name,
            boundaries: m.boundaries,
        }));
    }

    /**
     * Get municipality by ID, with a left join to regions table
     */
    public async getMunicipalityByID(id: number): Promise<Municipality | null> {
        const query = `
            SELECT m.id AS "municipalityId", m.name AS "municipalityName", 
                   r.name AS "regionName", ${customGeometry.toGeoJSON('m.boundaries')} AS boundaries
            FROM ${municipalityTable} m
            LEFT JOIN ${regionTable} r ON r.id = m.id_region
            WHERE m.id = $1
            LIMIT 1;
        `;

        // Execute the query
        const dbResult = await executeQuery(query, [id]);

        // Check if municipality was found
        if (dbResult.length === 0) return null;

        const m = dbResult[0];

        // Return the mapped Municipality object
        return {
            id: m.municipalityId,
            name: m.municipalityName,
            region: m.regionName ?? 'Unknown Region',
            boundaries: m.boundaries,
        };
    }
}
