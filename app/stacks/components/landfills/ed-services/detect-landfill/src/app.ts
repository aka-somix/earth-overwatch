import { GetObjectCommand, S3Client } from "@aws-sdk/client-s3";
import { InvokeEndpointCommand, SageMakerRuntimeClient } from "@aws-sdk/client-sagemaker-runtime";
import { EventBridgeEvent } from "aws-lambda";
import { DetectionResults, GeoJSONPolygon } from "./@types";
import { ENDPOINT_NAME } from "./config";

const s3Client = new S3Client({});
const sagemakerClient = new SageMakerRuntimeClient({});

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

async function invokeSagemakerEndpoint(imageBase64: string, endpointName: string) {

    // Prepare payload in JSON format
    const payload = JSON.stringify({ image: imageBase64 });

    // Set up the command to invoke the endpoint
    const command = new InvokeEndpointCommand({
        EndpointName: endpointName,
        ContentType: "application/json",
        Body: Buffer.from(payload),
    });

    try {
        const response = await sagemakerClient.send(command);
        const responseBody = await response.Body?.transformToString();
        return JSON.parse(responseBody || "{}");
    } catch (error) {
        console.error("Error invoking SageMaker endpoint:", error);
        throw error;
    }
}

function parseS3Uri(s3Uri: string): { bucket: string; key: string } {
    const s3UriPattern = /^s3:\/\/([^/]+)\/(.+)$/;
    const match = s3Uri.match(s3UriPattern);

    if (match) {
        const bucket = match[1];
        const key = match[2];
        return { bucket, key };
    }

    throw new Error("Invalid S3 URI format");
}

export async function handler(event: EventBridgeEvent<string, { s3Url: string; }>) {
    console.log(`Parsing ${JSON.stringify(event)}`);

    const { bucket, key } = parseS3Uri(event.detail.s3Url);

    console.log(`BUCKET: ${bucket}| KEY: ${key}`);

    const imageStream = await s3Client.send(new GetObjectCommand({
        Bucket: bucket,
        Key: key,
    }));

    const imageBase64 = await imageStream.Body?.transformToString('base64');

    if (imageBase64 === undefined) return;

    console.log("Invoking Sagemaker for inference");

    const detections = await invokeSagemakerEndpoint(imageBase64, ENDPOINT_NAME);

    const geojsons = convertBoxesToGeoJSON(detections);

    console.log(JSON.stringify(geojsons));
}
