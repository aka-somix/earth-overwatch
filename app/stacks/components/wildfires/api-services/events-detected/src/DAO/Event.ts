import { NodePgDatabase } from "drizzle-orm/node-postgres";
import { Event, EventFilter } from "../@types";
import { char, geometry, integer, numeric, PgSelect, pgTable, PgTableWithColumns, serial, timestamp, varchar } from "drizzle-orm/pg-core";
import { and, eq } from "drizzle-orm";


/**
 * DATABASE ENTITIES
 */
const eventDbTable = pgTable('event_detected', {
    id: serial('id').primaryKey(),
    idMunicipality: integer('id_municipality').notNull(),
    source: varchar('source', { length: 20 }).notNull(),
    detectionTime: timestamp('detection_time').notNull(),
    area: geometry('area', { type: 'MultiPolygon', srid: 4326 }),
    pointLocation: geometry('point_location', { type: 'point', srid: 4326 }),
    createdAt: timestamp('created_at').defaultNow(),
    updatedAt: timestamp('updated_at').defaultNow(),
});



/**
 * DATA ACCESS OBJECT
 */
export class EventDAO {

    client: NodePgDatabase

    constructor(client: NodePgDatabase) {
        this.client = client
    }

    private parseFilters<T extends PgSelect>(qb: T, filters: EventFilter): T {
        const conditions = []

        if (filters.municipality) {
            conditions.push(eq(eventDbTable.idMunicipality, parseInt(filters.municipality)))
        }

        if (conditions.length > 0) {
            qb = qb.where(and(...conditions));
        }
        return qb;
    }

    public async getEvents(filters: EventFilter): Promise<Array<Event>> {

        let queryBuilder = this.client
            .select()
            .from(eventDbTable)
            .$dynamic()

        queryBuilder = this.parseFilters(queryBuilder, filters);

        const eventsFound = await queryBuilder;

        return eventsFound;
    }

    public async getEventByID(id: string): Promise<Event | null> {


        const eventFound = await this.client
            .select()
            .from(eventDbTable)
            .where(eq(eventDbTable.id, parseInt(id)))
            .limit(1);

        if (eventFound.length === 0) return null;

        const event = eventFound[0];

        return {
            id: event.id,
            detected_from: event.source,
            municipality_id: event.idMunicipality,
            detection_time: event.detectionTime.toISOString(),
            geometry: event.area // TODO Change this once you figure out how to do it
        }
    }
}
