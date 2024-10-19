import { NodePgDatabase } from "drizzle-orm/node-postgres";
import { Region } from "../@types";
import { geometry, pgTable, serial, varchar } from "drizzle-orm/pg-core";
import { and, eq } from "drizzle-orm";
import { customGeometry } from "../libs/database";


/**
 * DATABASE ENTITIES
 */
export const regionDb = pgTable('region', {
    id: serial('id').primaryKey(),
    name: varchar("name", { length: 255 }).notNull(),
    boundaries: customGeometry('boundaries').notNull()
});

/**
 * DATA ACCESS OBJECT
 */
export class RegionDAO {

    client: NodePgDatabase

    constructor(client: NodePgDatabase) {
        this.client = client
    }

    public async getRegions(): Promise<Array<Region>> {

        let queryBuilder = this.client
            .select()
            .from(regionDb)

        const regions = await queryBuilder;

        return regions.map((r) => {
            return {
                id: r.id,
                name: r.name,
                boundaries: r.boundaries
            }
        })
    }

    public async getRegionByID(id: number): Promise<Region | null> {


        const regionFound = await this.client
            .select()
            .from(regionDb)
            .where(eq(regionDb.id, id))
            .limit(1);

        if (regionFound.length === 0) return null;

        const region = regionFound[0];

        return {
            id: region.id,
            name: region.name,
            boundaries: region.boundaries
        }
    }
}
