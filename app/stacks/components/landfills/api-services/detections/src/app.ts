
import express from 'express';
import { BASE_PATH } from "./config";
import router from "./controller";
import { logger } from "./libs/powertools";
import cors = require("cors");
import serverless = require("serverless-http");

const app = express();

// ---- CORS SETTINGS ----
app.use(cors());

app.use(express.json());


/**
 *  Instantiate Router middleware
 */
app.use(`/${BASE_PATH}/`, router);

app.use((req: express.Request, res: express.Response, next: express.NextFunction) => {
  logger.error(`No resource found at given path ${req.path}`);
  res.status(404).send();
});

app.use((err: unknown, req: express.Request, res: express.Response, next: express.NextFunction) => {
  logger.error(`Internal error while trying to handle request ${req.path}. Error details: ${err as string}`);
  res.status(500).send();
});

const serverlessHandler = serverless(app);


export const handler = async (event: object, ctx: object): Promise<object> => {
  /*
   * INSERT HERE pre-hooks  
   */

  return await serverlessHandler(event, ctx);
};

export default app;
