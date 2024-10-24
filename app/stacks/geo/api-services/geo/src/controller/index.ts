import { Request, Response, Router } from "express";
import { logger } from '../libs/powertools';
import { getDbClient } from "../database/client";
import { RegionDAO } from "../DAO/Region";
import { MunFilters } from "../@types";
import { MunicipalityDAO } from "../DAO/Municipality";
const router = Router();

/**
 * TODO Docs here
 */
router.get("/regions", async (req: Request, res: Response) => {
    try {
        logger.info(`Processing ${req.method} Request for path: ${req.path}`);

        const regions = await new RegionDAO().getRegions();

        // RESPONSE
        logger.info(`Processed ${req.method} Request for path: ${req.path}`);
        res.status(200).json(regions);

    } catch (error: unknown) {
        logger.error(`Error while processing ${req.method} Request for path: ${req.path}: ${typeof error}`, { error });
        res.status(500).json(error);
    }
});

/**
 * TODO Docs here
 */
router.get("/regions/:id", async (req: Request, res: Response) => {
    try {
        logger.info(`Processing ${req.method} Request for path: ${req.path}`);

        const { id } = req.params;

        const idNumeric = parseInt(id);

        const regionFound = await new RegionDAO().getRegionByID(idNumeric);

        if (regionFound === null) {
            res.status(404).json({
                message: "No Event found with this id.",
                id: id
            });
            return
        }

        // RESPONSE
        logger.info(`Processed ${req.method} Request for path: ${req.path}`);
        res.status(200).json(regionFound);

    } catch (error: unknown) {
        logger.error(`Error while processing ${req.method} Request for path: ${req.path}: ${typeof error}`, { error });
        res.status(500).json(error);
    }
});

/**
 * TODO Docs here
 */
router.get("/municipalities", async (req: Request, res: Response) => {
    try {
        const { region } = req.query;

        const filters: MunFilters = {}

        // add Region filter
        if (region !== undefined) filters.idRegion = parseInt(region as string)

        const response = await new MunicipalityDAO().getMunicipalities(filters);

        // RESPONSE
        logger.info(`Processed ${req.method} Request for path: ${req.path}`);
        res.status(200).json(response);

    } catch (error: unknown) {
        logger.error(`Error while processing ${req.method} Request for path: ${req.path}: ${typeof error}`, { error });
        res.status(500).json(error);
    }
});

/**
 * TODO Docs here
 */
router.get("/municipalities/:id", async (req: Request, res: Response) => {
    try {
        logger.info(`Processing ${req.method} Request for path: ${req.path}`);

        const { id } = req.params;

        const idNumeric = parseInt(id);

        const response = await new MunicipalityDAO().getMunicipalityByID(idNumeric);

        if (response === null) {
            res.status(404).json({
                message: "No Event found with this id.",
                id: id
            });
            return
        }

        // RESPONSE
        logger.info(`Processed ${req.method} Request for path: ${req.path}`);
        res.status(200).json(response);

    } catch (error: unknown) {
        logger.error(`Error while processing ${req.method} Request for path: ${req.path}: ${typeof error}`, { error });
        res.status(500).json(error);
    }
});


export default router;
