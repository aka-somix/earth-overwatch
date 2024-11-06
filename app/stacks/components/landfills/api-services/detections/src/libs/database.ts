import { Pool } from 'pg';
import { ENV, PG_DATABASE, PG_HOST, PG_PASSWORD, PG_USER } from "../config";
import { logger } from "./powertools";

import { getSecret } from "@aws-lambda-powertools/parameters/secrets";
import { DATABASE_SECRET } from "../config";

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

// Unique database pool instance
let pool: Pool | null = null;

/**
 * POSTGIS CUSTOM TYPES (Note: You'll need to use ST_* PostGIS functions in raw SQL with pg)
 */
export const customGeometry = {
  toPostGIS(data: string) {
    return `ST_GeomFromText('${data}', 4326)`;
  },
  toGeoJSON(column: string) {
    return `ST_AsGeoJSON(${column})`;
  }
};

const getDbSecret = async (): Promise<AWSSecret> => {
  const secret = (await getSecret(DATABASE_SECRET)) as string;

  return JSON.parse(secret) as AWSSecret;
};

export const getDbClient = async (): Promise<Pool> => {
  // Shortcut if the pool is already initialized
  if (pool !== null) {
    return pool;
  }

  // Initialize the configuration object
  let config;

  // Initialize from local environment if testing 
  if (ENV === 'local') {
    config = {
      host: PG_HOST,
      user: PG_USER,
      password: PG_PASSWORD,
      database: PG_DATABASE,
      port: 5432,  // default PostgreSQL port
      max: 20,     // max number of clients in the pool
      min: 1,      // min number of clients in the pool
      ssl: { rejectUnauthorized: false }
    };
  } else {
    // Retrieve secret from Secrets Manager
    const { username, host, db_name, password, db_port } = await getDbSecret();

    config = {
      host: host,
      user: username,
      password: password,
      database: db_name,
      port: parseInt(db_port),
      max: 20,
      min: 1,
      ssl: { rejectUnauthorized: false }
    };
  }

  // Initialize the pool
  pool = new Pool(config);

  logger.info("Connection to the database established");
  return pool;
};

/**
 * Sample query execution with raw SQL
 */
export const executeQuery = async (query: string, params: any[] = []) => {
  const client = await getDbClient();
  try {
    const result = await client.query(query, params);
    return result.rows;
  }
  catch (error) {
    logger.error(`Database query failed: ${error}`);
    throw new Error(`Failed to execute query. Please check the database connection or the SQL query syntax.`);
  }
};
