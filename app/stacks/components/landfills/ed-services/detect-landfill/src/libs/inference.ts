import { InvokeEndpointCommand, SageMakerRuntimeClient } from "@aws-sdk/client-sagemaker-runtime";
import { DetectionResults } from "../@types";
import { AWS_API_VERSION, ENDPOINT_NAME } from "../config";
import { logger } from "./powertools";

const sagemakerClient = new SageMakerRuntimeClient({ apiVersion: AWS_API_VERSION });

export class InferenceAPI {


    private static parseResults (r: any): DetectionResults {
        return r as DetectionResults;
    }

    public static async inference (imageBase64: string): Promise<DetectionResults> {

        // Prepare payload in JSON format
        const payload = JSON.stringify({ image: imageBase64 });

        // Set up the command to invoke the endpoint
        const command = new InvokeEndpointCommand({
            EndpointName: ENDPOINT_NAME,
            ContentType: "image/png",
            Body: Buffer.from(payload),
        });

        // Launch inference
        try {

            const response = await sagemakerClient.send(command);
            const responseBody = response.Body?.transformToString();
            return InferenceAPI.parseResults(JSON.parse(responseBody || "{}"));

        } catch (error) {
            logger.error(`Error invoking SageMaker endpoint: ${error}`,);
            throw error;
        }
    }
}