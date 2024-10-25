import { Monitor } from "../@types";
import { executeQuery } from "../libs/database";
import { logger } from "../libs/powertools";

/**
 * DATABASE ENTITIES
 */
const wildfireMonitoringTable = 'wildfire_monitoring';

/**
 * DATA ACCESS OBJECT for Monitors
 */
export class MonitorDAO {

    /**
     * Create a new monitor.
     * @param monitorDetails Object containing details of the new monitor (idMunicipality, type, requestedBy).
     */
    public async createMonitor(monitorDetails: { idMunicipality: number; requestedBy: string }): Promise<Monitor> {
        const { idMunicipality, requestedBy } = monitorDetails;
        const requestDate = new Date();

        const query = `
            INSERT INTO ${wildfireMonitoringTable} (id_municipality, requested_by, requested_date)
            VALUES ($1, $2, $3)
            RETURNING id, id_municipality, requested_date;
        `;

        const [newMonitor] = await executeQuery(query, [idMunicipality, requestedBy, requestDate]);

        logger.info("DEBUGGING", { newMonitor });

        return {
            id: newMonitor.id,
            idMunicipality: newMonitor.id_municipality,
            type: Monitor.type.WILDFIRE,
            dateRequested: newMonitor.requested_date,
        };
    }

    /**
     * Get monitors with optional filters for idMunicipality.
     * @param filters Optional filters to retrieve specific monitors.
     */
    public async getMonitors(filters: { idMunicipality?: number }): Promise<Array<Monitor>> {
        // Build the dynamic WHERE clause
        let query = `
            SELECT id, id_municipality, requested_date
            FROM ${wildfireMonitoringTable}
        `;

        const queryParams: any[] = [];
        if (filters.idMunicipality) {
            query += ` WHERE id_municipality = $1`;
            queryParams.push(filters.idMunicipality);
        }

        logger.info(`QUERY: ${query}`);

        const monitorsFound: Array<Record<string, any>> = await executeQuery(query, queryParams);

        return monitorsFound.map((monitor) => ({
            id: monitor.id,
            idMunicipality: monitor.id_municipality,
            type: Monitor.type.WILDFIRE,
            dateRequested: monitor.requested_date,
        }));
    }

    /**
     * Delete a monitor by its ID.
     * @param id The ID of the monitor to delete.
     * @returns boolean True if the monitor was deleted, false if it did not exist.
     */
    public async deleteMonitor(id: number): Promise<boolean> {
        const query = `
            DELETE FROM ${wildfireMonitoringTable}
            WHERE id = $1
            RETURNING id;
        `;

        const result = await executeQuery(query, [id]);

        return result.length > 0;
    }
}
