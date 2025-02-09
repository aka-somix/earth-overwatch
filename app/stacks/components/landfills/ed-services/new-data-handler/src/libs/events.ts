import { EventBridgeClient, PutEventsCommand } from "@aws-sdk/client-eventbridge";
import { EventPayload } from "../@types";
import { AWS_API_VERSION, EVENT_BUS_NAME } from "../config";
import { logger } from "./powertools";

const client = new EventBridgeClient({ apiVersion: AWS_API_VERSION });

/**
 * Sends an event to EventBridge.
 * 
 * @param input - The input data containing latitude, longitude, and imageS3URL.
 * @returns A promise that resolves when the event is sent successfully.
 */
export async function sendEvent (payload: EventPayload) {
    const eventParams = {
        Entries: [
            {
                Source: "component/landfill/newdata",
                DetailType: "detect/landfills",
                Detail: JSON.stringify({
                    bbox: payload.bbox,
                    imageS3URL: payload.imageS3URL,
                    source: payload.source
                }),
                EventBusName: EVENT_BUS_NAME,
            },
        ],
    };

    const command = new PutEventsCommand(eventParams);

    try {
        const response = await client.send(command);
        logger.info("Event sent to EventBridge", { response });
    } catch (error) {
        logger.error("Failed to send event to EventBridge", { error });
        throw error;
    }
}