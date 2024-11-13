import { Request, Response, Router } from "express";
import { Monitor } from "../@types";
import { MonitorDAO } from "../DAO/Monitor";
import { logger } from '../libs/powertools';
const router = Router();

/**
 * POST /monitors
 * Creates a new monitor for a specific municipality with a specified type of monitoring.
 */
router.post("/:type", async (req: Request, res: Response) => {
    try {
        logger.info(`Processing ${req.method} Request for path: ${req.path}`);

        const { type } = req.params;
        const { idMunicipality } = req.body;
        const apikey = (req.headers["x-api-key"] ?? "Unknown") as string;

        // Validate input
        if (!idMunicipality || !type) {
            return res.status(400).json({
                message: "Missing required fields: idMunicipality and type"
            });
        }

        if (type !== Monitor.type.LANDFILL) {
            return res.status(400).json({
                message: "Invalid type. Currently only LANDFILL type is supported."
            });
        }

        // Add monitor
        const monitor = await new MonitorDAO().createMonitor({
            idMunicipality,
            requestedBy: apikey,
            type
        });

        logger.info(`Processed ${req.method} Request for path: ${req.path}`);
        res.status(201).json(monitor);

    } catch (error: unknown) {
        logger.error(`Error while processing ${req.method} Request for path: ${req.path}: ${typeof error}`, { error });
        res.status(500).json(error);
    }
});

/**
 * GET /monitors/:type
 * Returns all monitors, with optional filters for municipality or type.
 */
router.get("/:type", async (req: Request, res: Response) => {
    try {
        logger.info(`Processing ${req.method} Request for path: ${req.path}`);

        const { type } = req.params;
        const { idMunicipality } = req.query;

        // Build Filters
        const filters: Record<string, any> = { type };
        if (idMunicipality) {
            filters.idMunicipality = parseInt(idMunicipality as string);
        }

        // Fetch monitors
        const monitors = await new MonitorDAO().getMonitors(filters);

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
router.delete("/:id", async (req: Request, res: Response) => {
    try {
        logger.info(`Processing ${req.method} Request for path: ${req.path}`);

        const { id } = req.params;

        const idNumeric = parseInt(id);

        // Delete monitor
        const deleteResult = await new MonitorDAO().deleteMonitor(idNumeric);

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

/**
 * POST /monitoring/:type/geosearch
 * Search a Monitor based on a geographic search on latitude and longitude.
 */
router.post("/:type/geosearch", async (req: Request, res: Response) => {
    try {
        logger.info(`Processing ${req.method} Request for path: ${req.path}`);

        const { type } = req.params;
        const { latitude, longitude } = req.body;

        // Validate input
        if (!latitude || !longitude) {
            return res.status(400).json({
                message: "Missing required fields: latitude and longitude"
            });
        }

        if (type !== Monitor.type.LANDFILL) {
            return res.status(400).json({
                message: "Invalid type. Currently only LANDFILL type is supported."
            });
        }

        // Perform geographic search for monitors
        const monitors = await new MonitorDAO().searchByPoint(latitude, longitude);

        logger.info(`Processed ${req.method} Request for path: ${req.path}`);
        res.status(200).json(monitors);

    } catch (error: unknown) {
        logger.error(`Error while processing ${req.method} Request for path: ${req.path}: ${typeof error}`, { error });
        res.status(500).json(error);
    }
});


export default router;
