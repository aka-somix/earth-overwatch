import { EventBridgeEvent } from "aws-lambda";
import { DetectionResults, GeoJSONPolygon, InputDetail } from "./@types";
import { InferenceAPI } from "./libs/inference";
import { logger } from "./libs/powertools";
import { getStreamFromS3Url } from "./libs/s3";

function parseAndValidate (input: unknown): InputDetail {
    // Validate the input is an object
    if (typeof input !== "object" || input === null) {
        throw new Error("Input must be a non-null object");
    }

    // Narrow the input to a specific type
    const obj = input as Partial<InputDetail>;

    // Validate latitude
    if (typeof obj.latitude !== "number" || obj.latitude < -90 || obj.latitude > 90) {
        throw new Error("Latitude must be a number between -90 and 90");
    }

    // Validate longitude
    if (typeof obj.longitude !== "number" || obj.longitude < -180 || obj.longitude > 180) {
        throw new Error("Longitude must be a number between -180 and 180");
    }

    // Validate imageS3URL
    if (typeof obj.imageS3URL !== "string") {
        throw new Error("imageS3URL must be a valid string");
    }

    // If all validations pass, return the object as InputDetail
    return {
        latitude: obj.latitude,
        longitude: obj.longitude,
        imageS3URL: obj.imageS3URL,
    };
}

function convertBoxesToGeoJSON(detectionResults: DetectionResults): GeoJSONPolygon[] {
    const polygons: GeoJSONPolygon[] = [];

    for (const box of detectionResults.boxes) {
        const [xMin, yMin, xMax, yMax] = box.slice(0, 4);

        // Construct the GeoJSON Polygon for this box
        const polygon: GeoJSONPolygon = {
            type: "Polygon",
            coordinates: [[
                [xMin, yMin], // top-left
                [xMax, yMin], // top-right
                [xMax, yMax], // bottom-right
                [xMin, yMax], // bottom-left
                [xMin, yMin]  // back to top-left to close the polygon
            ]]
        };

        polygons.push(polygon);
    }

    return polygons;
}


export async function handler (event: EventBridgeEvent<string, unknown>) {
    console.log(`Parsing ${JSON.stringify(event)}`);

    const { latitude, longitude, imageS3URL } = parseAndValidate(event.detail);

    logger.info(`Retrieving Stream from ${imageS3URL}`)

    const imageStream = await getStreamFromS3Url(imageS3URL);

    const imageBase64 = await imageStream.transformToString('base64');

    if (imageBase64 === undefined) return;

    logger.info("Invoking Sagemaker API for inference on stream");

    const detections = await InferenceAPI.inference(imageBase64)
        ;
    logger.info("Converting results into GeoJSON Boxes")

    const geojsons = convertBoxesToGeoJSON(detections);

    console.log(JSON.stringify(geojsons));
}
