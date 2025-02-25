import { API_KEY, LANDFILLS_API_URL } from './config';
import { Landfills } from './generated';

export * from './geo';

export const landfillService = new Landfills({
    BASE: LANDFILLS_API_URL,
    HEADERS: {"x-api-key": API_KEY}
});
