import { NodePgDatabase, drizzle } from "drizzle-orm/node-postgres";
import { Pool } from "pg";
import { ENV, PG_DATABASE, PG_HOST, PG_PASSWORD, PG_USER } from "../config"
import { logger } from "../libs/powertools";

import { getSecret } from "@aws-lambda-powertools/parameters/secrets";
import { PG_CREDENTIALS } from "../config";


type AWSSecret = {
  cluster_identifier: string;
  db_engine: string;
  db_name: string;
  db_port: string;
  host: string;
  password: string;
  read_host: string;
  username: string;
  ssl: boolean;
};

// Unique database client
let client: NodePgDatabase | null = null;


const getDbSecret = async (): Promise<AWSSecret> => {
  const secret = (await getSecret(PG_CREDENTIALS)) as string;

  return JSON.parse(secret) as AWSSecret;
};

export const getDbClient = async (): Promise<NodePgDatabase> => {
  try {

    // Shortcut if the client is already initialized
    if (client !== null) {
      return client;
    }

    // else initialize pool and return it
    let poolConfig = {
      host: PG_HOST,
      user: PG_USER,
      password: PG_PASSWORD,
      database: PG_DATABASE,
      port: 5432,
      max: 20,
      ssl: false
    };

    // override from secret if it is not a local deploy
    if (ENV !== "staging") {
      logger.info("Enstablishing connection to database");
      // eslint-disable-next-line @typescript-eslint/naming-convention
      const { username, host, db_name, password, db_port } = await getDbSecret();
      poolConfig = {
        ...poolConfig,
        host: host,
        user: username,
        password: password,
        port: parseInt(db_port),
        database: db_name,
        ssl: true
      };
    }

    client = drizzle(new Pool(poolConfig));

    logger.info("Connection to database enstablished");
    return client;

  } catch (error) {
    throw new Error("DB Connection ERROR");
  }
};
