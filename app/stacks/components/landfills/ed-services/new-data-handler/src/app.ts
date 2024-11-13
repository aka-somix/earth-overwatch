import { EventBridgeEvent } from 'aws-lambda';
import { Input } from "./@types";
import { MonitoringAPI } from "./apis";
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

/**
 * Parses an detail object and extracts the required fields for Input.
 * If any attribute is missing or of the wrong type, the function throws an error.
 * 
 * @param detail - An unknown detail object expected to contain latitude, longitude, and imageS3URL fields.
 * @returns An Input object containing the validated latitude, longitude, and imageS3URL.
 * 
 * @throws Error if the detail is null, not an object, or lacks any required attributes with correct types.
 */
function parseInput(detail: unknown): Input {
  if (typeof detail !== 'object' || detail === null) {
    throw new Error("Invalid detail object");
  }

  const { latitude, longitude, imageS3URL } = detail as { [key: string]: any; };

  if (typeof latitude !== 'number' || typeof longitude !== 'number' || typeof imageS3URL !== 'string') {
    throw new Error("Missing or invalid attributes in detail");
  }

  return { latitude, longitude, imageS3URL };
}



export const handler = async (event: EventBridgeEvent<string, unknown>): Promise<void> => {
  logger.info("Event", { event });

  // Step 1 - Input Validation
  logger.info("Validating input");
  const validInput = parseInput(event.detail);

  // Step 2 - Check for data based on the coordinates
  logger.info(`Looking for a monitor for coordinates: [${validInput.latitude}, ${validInput.longitude}]`);

  const response = await monitoringApi.default.postMonitoringGeosearch('LANDFILL', {
    latitude: validInput.latitude,
    longitude: validInput.longitude
  });

  // Check for results
  if (response.length > 0) {
    // Step 3 - Send the image for image segmentation over EventBridge
    logger.info(`Found ${response.length} monitors for requested coordinates.`);

    logger.info(`Monitors found: [${response.map(i => JSON.stringify(i)).join(', ')}]`);

    await sendEvent({
      ...validInput,
      source: event.source ?? 'unknown'
    });

  } else {
    logger.info('No monitors found for given point');
  }
};
