import { Request, Response, Router } from "express";
import { EventDAO } from "../DAO/Event";
import { logger } from '../libs/powertools';
import { EventFilter } from "../@types";
import { NextFunction } from "express-serve-static-core";
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

        // TODO: This should be put somewhere else
        const db = await getDbClient();

        const events = await new EventDAO(db).getEvents(filters);

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

        // TODO: This should be put somewhere else
        const db = await getDbClient();

        const eventFound = await new EventDAO(db).getEventByID(id);

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
