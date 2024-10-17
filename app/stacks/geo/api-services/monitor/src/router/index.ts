import { Request, Response, Router } from "express";
import { logger } from '../libs/powertools';
const router = Router();


router.get("/", async (req: Request, res: Response) => {
    try {
        logger.info(`Processing ${req.method} Request for path: ${req.path}`);

        const { area } = req.query;

        // Get Feedbacks for the zone


        logger.info(`Processed ${req.method} Request for path: ${req.path}`);
        res.status(200).json({ message: "pong" });

    } catch (error: unknown) {
        logger.error(`Error while processing ${req.method} Request for path: ${req.path}: ${typeof error}`, { error });
        res.status(500).json(error);
    }
});

export default router;
