import { Request, Response, Router } from "express";
import { LandfillFilter } from "../@types";
import { LandfillDAO } from "../dao/Landfill";
import { logger } from '../libs/powertools';
import { landfillSchema } from "../validations";
const router = Router();

router.get("/", async (req: Request, res: Response) => {
    try {
        logger.info(`Processing ${req.method} Request for path: ${req.path}`);

        const queryParams = req.query

        const filters: LandfillFilter = {
            municipality: queryParams.municipality?.toString()
        }

        const events = await new LandfillDAO().getLandfills(filters);

        // RESPONSE
        logger.info(`Processed ${req.method} Request for path: ${req.path}`);
        res.status(200).json(events);

    } catch (error: unknown) {
        logger.error(`Error while processing ${req.method} Request for path: ${req.path}: ${typeof error}`, { error });
        res.status(500).json(error);
    }
});

router.post("/", async (req: Request, res: Response) => {
    try {
        logger.info(`Processing ${req.method} Request for path: ${req.path}`);

        // Validate request body
        const parsedBody = landfillSchema.safeParse(req.body);

        if (!parsedBody.success) {
            logger.warn(`Validation failed for ${req.method} Request: ${JSON.stringify(parsedBody.error.format())}`);
            return res.status(400).json({ error: "Invalid request body", details: parsedBody.error.format() });
        }

        const events = await new LandfillDAO().createLandfill(parsedBody.data);

        // RESPONSE
        logger.info(`Processed ${req.method} Request for path: ${req.path}`);
        res.status(200).json(events);

    } catch (error: unknown) {
        logger.error(`Error while processing ${req.method} Request for path: ${req.path}: ${typeof error}`, { error });
        res.status(500).json(error);
    }
});

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
