import { EventBridgeEvent } from 'aws-lambda';
import { BBox, ValidInput } from "./@types";
import { Monitor, MonitorGeoSearch, MonitoringAPI } from "./apis";
import { API_KEY, MONITORING_API_BASE_PATH } from "./config";
import { sendEvent } from "./libs/events";
import { logger } from "./libs/powertools";

/*
 * -- APIS --
 */
const monitoringApi = new MonitoringAPI({
  BASE: MONITORING_API_BASE_PATH,
  HEADERS: {
    'x-api-key': API_KEY
  }
});


function parseInput(detail: unknown): ValidInput {
  if (typeof detail !== "object" || detail === null) {
    throw new Error("Invalid detail object");
  }
  const { bbox, imageS3URL } = detail as { [key: string]: any };

  // Internal Function for parsing BBOX from string
  function parseBBoxString(bbox: any): [number, number, number, number] | null {
    if (typeof bbox !== "string") {
      return null;
    }
    try {
      const parsed = JSON.parse(bbox);
      if (
        Array.isArray(parsed) &&
        parsed.length === 4 &&
        parsed.every((val) => typeof val === "number")
      ) {
        return parsed as [number, number, number, number];
      }
    } catch {
      return null;
    }
    return null;
  }

  const parsedBBox = parseBBoxString(bbox);
  if (!parsedBBox || typeof imageS3URL !== "string") {
    throw new Error("Missing or invalid attributes in detail");
  }

  const bboxObject: BBox = {
    xmin: parsedBBox[0],
    ymin: parsedBBox[1],
    xmax: parsedBBox[2],
    ymax: parsedBBox[3],
  };

  return { bbox: bboxObject, imageS3URL };
}


async function searchMonitorsInBoundingBox (bbox: BBox): Promise<Array<Monitor>> {

  const payloads: Array<MonitorGeoSearch> = [
    // bottom left
    { latitude: bbox.ymin, longitude: bbox.xmin },
    // bottom right
    { latitude: bbox.ymin, longitude: bbox.xmax },
    // top left
    { latitude: bbox.ymax, longitude: bbox.xmin },
    // top right
    { latitude: bbox.ymax, longitude: bbox.xmax },
    // top center
    { latitude: (bbox.ymin + bbox.ymax) / 2, longitude: (bbox.xmin + bbox.xmax) / 2 },
  ];

  const geoSearchPromises = payloads.map(payload => monitoringApi.default.postMonitoringGeosearch('LANDFILL', payload));

  const geoSearchResults = await Promise.all(geoSearchPromises);

  return geoSearchResults.flat();
}


export const handler = async (event: EventBridgeEvent<string, unknown>): Promise<void> => {
  logger.info("Event", { event });

  // Step 1 - Input Validation
  logger.info("Validating input");
  const { bbox, imageS3URL } = parseInput(event.detail);

  // Step 2 - Check for data based on the coordinates
  logger.info(`Looking for a monitor for coordinates: ${bbox}`);

  const monitorsFound = await searchMonitorsInBoundingBox(bbox);

  // Check for results
  if (monitorsFound.length > 0) {
    // Step 3 - Send the image for image segmentation over EventBridge
    logger.info(`Found ${monitorsFound.length} monitors for requested coordinates.`);

    logger.info(`Monitors found: [${monitorsFound.map(i => JSON.stringify(i)).join(', ')}]`);

    await sendEvent({
      bbox,
      imageS3URL,
      source: event.source ?? 'unknown'
    });

  } else {
    logger.info('No monitors found for given point');
  }
};
