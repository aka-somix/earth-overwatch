
import { NodePgDatabase } from "drizzle-orm/node-postgres";

import { geometry, integer, PgSelect, pgTable, serial, timestamp, varchar } from "drizzle-orm/pg-core";
import { and, eq } from "drizzle-orm";
import { Monitor } from "../@types";



/**
 * DATABASE ENTITIES
 */
const municipalityDb = pgTable('municipality', {
    id: serial('id').primaryKey(),
    name: varchar('name', { length: 255 }).notNull(),
    idRegion: integer('id_region').notNull(),
    area: geometry('area', { type: 'MultiPolygon', srid: 4326 }).notNull(),
});

const wildfireMonitoringDb = pgTable('wildfire_monitoring', {
    id: serial('id').primaryKey(),
    idMunicipality: integer('id_municipality').notNull(),
    requestedBy: varchar("requested_by", { length: 100 }).notNull(),
    requestDate: timestamp("requestDate").notNull()
});

/**
 * DATA ACCESS OBJECT for Monitors
 */
export class MonitorDAO {

    client: NodePgDatabase;

    constructor(client: NodePgDatabase) {
        this.client = client;
    }

    /**
     * Parses filters for the query, such as idMunicipality or type.
     */
    private parseFilters<T extends PgSelect>(qb: T, filters: any): T {
        const conditions = [];

        if (filters.idMunicipality) {
            conditions.push(eq(wildfireMonitoringDb.idMunicipality, filters.idMunicipality));
        }

        if (conditions.length > 0) {
            qb = qb.where(and(...conditions));
        }

        return qb;
    }

    /**
     * Create a new monitor.
     * @param monitorDetails Object containing details of the new monitor (idMunicipality, type, dateRequested).
     */
    public async createMonitor(monitorDetails: { idMunicipality: number; type: string; requestedBy: string }): Promise<Monitor> {

        const { idMunicipality, type, requestedBy } = monitorDetails;

        const requestDate = new Date();

        const newMonitor = await this.client
            .insert(wildfireMonitoringDb)
            .values({
                idMunicipality,
                requestDate,
                requestedBy,
            })
            .returning({
                id: wildfireMonitoringDb.id,
                idMunicipality: wildfireMonitoringDb.idMunicipality,
                dateRequested: wildfireMonitoringDb.requestDate
            });

        const monitorCreated = newMonitor[0];

        return {
            id: monitorCreated.id,
            idMunicipality: monitorCreated.idMunicipality,
            type: Monitor.type.WILDFIRE,
            dateRequested: monitorCreated.dateRequested.toISOString(),
        };
    }

    /**
     * Get monitors with optional filters for idMunicipality or type.
     * @param filters Optional filters to retrieve specific monitors.
     */
    public async getMonitors(filters: any): Promise<Array<Monitor>> {

        let queryBuilder = this.client
            .select()
            .from(wildfireMonitoringDb)
            .$dynamic();

        queryBuilder = this.parseFilters(queryBuilder, filters);

        const monitorsFound = await queryBuilder;

        return monitorsFound.map((monitor) => {
            return {
                id: monitor.id,
                idMunicipality: monitor.idMunicipality,
                type: Monitor.type.WILDFIRE,
                dateRequested: monitor.requestDate.toISOString(),
            };
        });
    }

    /**
     * Delete a monitor by its ID.
     * @param id The ID of the monitor to delete.
     * @returns boolean True if the monitor was deleted, false if it did not exist.
     */
    public async deleteMonitor(id: number): Promise<boolean> {

        const result = await this.client
            .delete(wildfireMonitoringDb)
            .where(eq(wildfireMonitoringDb.id, id))
            .returning({
                id: wildfireMonitoringDb.id,
            });

        return result.length > 0;
    }
}
