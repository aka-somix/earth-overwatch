
import { NodePgDatabase } from "drizzle-orm/node-postgres";

import { geometry, integer, PgSelect, pgTable, serial, varchar } from "drizzle-orm/pg-core";
import { and, eq } from "drizzle-orm";
import { MunFilters, Municipality } from "../@types";
import { regionDb } from "./Region";


/**
 * DATABASE ENTITIES
 */
const municipalityDb = pgTable('municipality', {
    id: serial('id').primaryKey(),
    name: varchar('name', { length: 255 }).notNull(),
    idRegion: integer('id_region').notNull(),
    area: geometry('area', { type: 'MultiPolygon', srid: 4326 }).notNull(),
});


/**
 * DATA ACCESS OBJECT
 */
export class MunicipalityDAO {

    client: NodePgDatabase

    constructor(client: NodePgDatabase) {
        this.client = client
    }

    private parseFilters<T extends PgSelect>(qb: T, filters: MunFilters): T {
        const conditions = []

        if (filters.idRegion) {
            conditions.push(eq(municipalityDb.idRegion, filters.idRegion))
        }

        if (conditions.length > 0) {
            qb = qb.where(and(...conditions));
        }
        return qb;
    }

    public async getMunicipalities(filters: any): Promise<Array<Municipality>> {

        let queryBuilder = this.client
            .select()
            .from(municipalityDb)
            .$dynamic()

        queryBuilder = this.parseFilters(queryBuilder, filters);

        const munFound = await queryBuilder;

        return munFound.map((m) => {
            return {
                id: m.id,
                name: m.name,
                boundaries: m.area
            }
        });
    }

    public async getMunicipalityByID(id: number): Promise<Municipality | null> {

        const dbResult = await this.client
            .select()
            .from(municipalityDb)
            .leftJoin(regionDb, eq(regionDb.id, municipalityDb.idRegion))
            .where(eq(municipalityDb.id, id))
            .limit(1);

        if (dbResult.length === 0) return null;

        const m = dbResult[0];

        return {
            id: m.municipality.id,
            name: m.municipality.name,
            region: m.region?.name ?? 'Unknown Region',
            boundaries: m.municipality.area
        }
    }
}
