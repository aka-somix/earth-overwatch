import { Region, RegionDB } from "../@types";
import { customGeometry, executeQuery } from '../database/client'; // Import the db client and helpers

/**
 * DATA ACCESS OBJECT
 */
export class RegionDAO {
    public async getRegions(): Promise<Array<Region>> {
        // SQL query to get all regions with PostGIS boundary data
        const query = `
            SELECT id, name, ${customGeometry.toGeoJSON('boundaries')} AS boundaries
            FROM region;
        `;

        // Execute the query and get the result
        const regions: RegionDB[] = await executeQuery(query);

        // Map the result to the expected Region type
        return regions.map((r) => {
            return {
                id: r.id,
                name: r.name,
                boundaries: r.boundaries
            };
        });
    }

    public async getRegionByID(id: number): Promise<Region | null> {
        // SQL query to get a single region by its ID
        const query = `
            SELECT id, name, ${customGeometry.toGeoJSON('boundaries')} AS boundaries
            FROM region
            WHERE id = $1
            LIMIT 1;
        `;

        // Execute the query with the provided ID
        const result: RegionDB[] = await executeQuery(query, [id]);

        // Check if any region was found
        if (result.length === 0) {
            return null;
        }

        // Extract the region from the result and return it
        const region = result[0];
        return {
            id: region.id,
            name: region.name,
            boundaries: region.boundaries
        };
    }
}
