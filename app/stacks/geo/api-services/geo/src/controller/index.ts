import { Request, Response, Router } from "express";
import { logger } from '../libs/powertools';
import { getDbClient } from "../database/client";
import { RegionDAO } from "../DAO/Region";
import { MunFilters } from "../@types";
import { MunicipalityDAO } from "../DAO/Municipality";
const router = Router();

/**
 * Get all regions.
 * Returns a list of regions.
 */
router.get("/regions", async (req: Request, res: Response) => {
    try {
        logger.info(`Processing ${req.method} Request for path: ${req.path}`);

        const regions = await new RegionDAO().getRegions();

        logger.info(`Processed ${req.method} Request for path: ${req.path}`);
        res.status(200).json(regions);

    } catch (error: unknown) {
        logger.error(`Error while processing ${req.method} Request for path: ${req.path}: ${typeof error}`, { error });
        res.status(500).json(error);
    }
});

/**
 * Get a specific region by ID.
 * @param id - The ID of the region.
 */
router.get("/regions/:id", async (req: Request, res: Response) => {
    try {
        logger.info(`Processing ${req.method} Request for path: ${req.path}`);

        const { id } = req.params;
        const idNumeric = parseInt(id);

        const regionFound = await new RegionDAO().getRegionByID(idNumeric);

        if (regionFound === null) {
            res.status(404).json({ message: "No region found with this id.", id });
            return;
        }

        logger.info(`Processed ${req.method} Request for path: ${req.path}`);
        res.status(200).json(regionFound);

    } catch (error: unknown) {
        logger.error(`Error while processing ${req.method} Request for path: ${req.path}: ${typeof error}`, { error });
        res.status(500).json(error);
    }
});

/**
 * Get all municipalities filtered by region (mandatory).
 * @param region - The ID of the region to filter by. (mandatory)
 */
router.get("/municipalities", async (req: Request, res: Response) => {
    try {
        const { region } = req.query;

        // Check if region is provided
        if (region === undefined) {
            return res.status(400).json({ message: "The 'region' query parameter is required." });
        }

        const filters: MunFilters = {};
        filters.idRegion = parseInt(region as string);

        const response = await new MunicipalityDAO().getMunicipalities(filters);

        logger.info(`Processed ${req.method} Request for path: ${req.path}`);
        res.status(200).json(response);

    } catch (error: unknown) {
        logger.error(`Error while processing ${req.method} Request for path: ${req.path}: ${typeof error}`, { error });
        res.status(500).json(error);
    }
});

/**
 * Get a specific municipality by ID.
 * @param id - The ID of the municipality.
 */
router.get("/municipalities/:id", async (req: Request, res: Response) => {
    try {
        logger.info(`Processing ${req.method} Request for path: ${req.path}`);

        const { id } = req.params;
        const idNumeric = parseInt(id);

        const response = await new MunicipalityDAO().getMunicipalityByID(idNumeric);

        if (response === null) {
            res.status(404).json({ message: "No municipality found with this id.", id });
            return;
        }

        logger.info(`Processed ${req.method} Request for path: ${req.path}`);
        res.status(200).json(response);

    } catch (error: unknown) {
        logger.error(`Error while processing ${req.method} Request for path: ${req.path}: ${typeof error}`, { error });
        res.status(500).json(error);
    }
});

export default router;
