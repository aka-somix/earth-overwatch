import { logger } from "./libs/powertools";


export const handler = async (event: unknown): Promise<void> => {
  /*
   * INSERT HERE code  
   */

  logger.info("Event", { event })
};
