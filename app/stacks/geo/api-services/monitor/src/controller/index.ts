import { Request, Response, Router } from "express";
import { logger } from '../libs/powertools';
import { getDbClient } from "../libs/database";
import { Monitor } from "../@types";
import { MonitorDAO } from "../DAO/Monitor";
const router = Router();

/**
 * POST /monitors
 * Creates a new monitor for a specific municipality with a specified type of monitoring.
 */
router.post("/monitors", async (req: Request, res: Response) => {
    try {
        logger.info(`Processing ${req.method} Request for path: ${req.path}`);

        const { idMunicipality, type } = req.body;
        const apikey = (req.headers["x-api-key"] ?? "Unknown") as string;

        // Validate input
        if (!idMunicipality || !type) {
            return res.status(400).json({
                message: "Missing required fields: idMunicipality and type"
            });
        }

        if (type !== Monitor.type.WILDFIRE) {
            return res.status(400).json({
                message: "Invalid type. Currently only WILDFIRE type is supported."
            });
        }

        // Get database client
        const db = await getDbClient();

        // Add monitor
        const monitor = await new MonitorDAO(db).createMonitor({
            idMunicipality,
            type,
            requestedBy: apikey,
        });

        logger.info(`Processed ${req.method} Request for path: ${req.path}`);
        res.status(201).json(monitor);

    } catch (error: unknown) {
        logger.error(`Error while processing ${req.method} Request for path: ${req.path}: ${typeof error}`, { error });
        res.status(500).json(error);
    }
});

/**
 * GET /monitors
 * Returns all monitors, with optional filters for municipality or type.
 */
router.get("/monitors", async (req: Request, res: Response) => {
    try {
        logger.info(`Processing ${req.method} Request for path: ${req.path}`);

        const { idMunicipality, type } = req.query;

        // Get database client
        const db = await getDbClient();

        const filters: any = {};
        if (idMunicipality) {
            filters.idMunicipality = parseInt(idMunicipality as string);
        }
        if (type) {
            filters.type = type;
        }

        // Fetch monitors
        const monitors = await new MonitorDAO(db).getMonitors(filters);

        logger.info(`Processed ${req.method} Request for path: ${req.path}`);
        res.status(200).json(monitors);

    } catch (error: unknown) {
        logger.error(`Error while processing ${req.method} Request for path: ${req.path}: ${typeof error}`, { error });
        res.status(500).json(error);
    }
});

/**
 * DELETE /monitors/:id
 * Deletes an existing monitor by ID.
 */
router.delete("/monitors/:id", async (req: Request, res: Response) => {
    try {
        logger.info(`Processing ${req.method} Request for path: ${req.path}`);

        const { id } = req.params;

        const idNumeric = parseInt(id);

        // Get database client
        const db = await getDbClient();

        // Delete monitor
        const deleteResult = await new MonitorDAO(db).deleteMonitor(idNumeric);

        if (!deleteResult) {
            return res.status(404).json({
                message: "Monitor not found",
                id: id
            });
        }

        logger.info(`Processed ${req.method} Request for path: ${req.path}`);
        res.status(204).send(); // No content for successful deletion

    } catch (error: unknown) {
        logger.error(`Error while processing ${req.method} Request for path: ${req.path}: ${typeof error}`, { error });
        res.status(500).json(error);
    }
});

export default router;
