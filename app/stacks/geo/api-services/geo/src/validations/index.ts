import { z } from "zod";

/**
 * Zod schema for validating the request body.
 */
export const geometrySchema = z.object({
    type: z.literal("Polygon"),
    coordinates: z.array(z.array(z.array(z.number()))).min(1, "Coordinates must contain at least one polygon."),
});

export const searchMunicipalitiesSchema = z.object({
    geometry: geometrySchema,
});
