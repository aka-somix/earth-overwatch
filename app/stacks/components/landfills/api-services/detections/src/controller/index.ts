import { Request, Response, Router } from "express";
import { LandfillDAO } from "../DAO/Landfill";
import { logger } from '../libs/powertools';
import { EventFilter } from "../@types";
import { getDbClient } from "../libs/database";
const router = Router();

/**
 * TODO Docs here
 */
router.get("/", async (req: Request, res: Response) => {
    try {
        logger.info(`Processing ${req.method} Request for path: ${req.path}`);

        const queryParams = req.query

        const filters: EventFilter = {
            municipality: queryParams.municipality?.toString()
        }

        const events = await new LandfillDAO().getEvents(filters);

        // RESPONSE
        logger.info(`Processed ${req.method} Request for path: ${req.path}`);
        res.status(200).json(events);

    } catch (error: unknown) {
        logger.error(`Error while processing ${req.method} Request for path: ${req.path}: ${typeof error}`, { error });
        res.status(500).json(error);
    }
});

/**
 * TODO Docs here
 */
router.get("/:id", async (req: Request, res: Response) => {
    try {
        logger.info(`Processing ${req.method} Request for path: ${req.path}`);

        const { id } = req.params;

        const numericId = parseInt(id);

        const eventFound = await new LandfillDAO().getLandfillById(numericId);

        if (eventFound === null) {
            res.status(404).json({
                message: "No Event found with this id.",
                id: id
            });
            return
        }

        // RESPONSE
        logger.info(`Processed ${req.method} Request for path: ${req.path}`);
        res.status(200).json(eventFound);

    } catch (error: unknown) {
        logger.error(`Error while processing ${req.method} Request for path: ${req.path}: ${typeof error}`, { error });
        res.status(500).json(error);
    }
});

export default router;
