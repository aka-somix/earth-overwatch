import { Request, Response, Router } from "express";
import { logger } from '../libs/powertools';
import { getDbClient } from "../libs/database";
import { RegionDAO } from "../DAO/Region";
import { MunFilters } from "../@types";
import { MunicipalityDAO } from "../DAO/Municipality";
const router = Router();

/**
 * TODO Docs here
 */
router.get("/regions/", async (req: Request, res: Response) => {
    try {
        logger.info(`Processing ${req.method} Request for path: ${req.path}`);

        // TODO: This should be put somewhere else
        const db = await getDbClient();

        const regions = await new RegionDAO(db).getRegions();

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

        // TODO: This should be put somewhere else
        const db = await getDbClient();

        const regionFound = await new RegionDAO(db).getRegionByID(idNumeric);

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

router.get("/municipalities/", async (req: Request, res: Response) => {
    try {
        logger.info(`Processing ${req.method} Request for path: ${req.path}`);

        const { region } = req.params;

        const filters: MunFilters = {
            idRegion: parseInt(region)
        }

        // TODO: This should be put somewhere else
        const db = await getDbClient();

        const response = await new MunicipalityDAO(db).getMunicipalities(filters);

        // RESPONSE
        logger.info(`Processed ${req.method} Request for path: ${req.path}`);
        res.status(200).json(response);

    } catch (error: unknown) {
        logger.error(`Error while processing ${req.method} Request for path: ${req.path}: ${typeof error}`, { error });
        res.status(500).json(error);
    }
});

router.get("/municipalities/:id", async (req: Request, res: Response) => {
    try {
        logger.info(`Processing ${req.method} Request for path: ${req.path}`);

        const { id } = req.params;

        const idNumeric = parseInt(id);

        // TODO: This should be put somewhere else
        const db = await getDbClient();

        const response = await new MunicipalityDAO(db).getMunicipalityByID(idNumeric);

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
