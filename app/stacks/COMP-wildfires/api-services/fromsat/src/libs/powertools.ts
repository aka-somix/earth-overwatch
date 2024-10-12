import { Logger } from "@aws-lambda-powertools/logger";
import { LOG_LEVEL } from "../config";

const logger: Logger = new Logger({
  serviceName: process.env.SERVICE_NAME,
  logLevel: LOG_LEVEL
});

class AppLambda { }

export { AppLambda, logger };

