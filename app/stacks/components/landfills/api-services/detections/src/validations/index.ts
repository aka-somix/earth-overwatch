import { z } from "zod";

export const landfillSchema = z.object({
    municipality_id: z.number(),
    detected_from: z.string(),
    detection_time: z.string(),
    geometry: z.any(),
});
