import { GetObjectCommand, S3Client } from "@aws-sdk/client-s3";
import { AWS_API_VERSION } from "../config";

const s3Client = new S3Client({ apiVersion: AWS_API_VERSION });

function parseS3Uri (s3Uri: string): { bucket: string; key: string; } {
    const s3UriPattern = /^s3:\/\/([^/]+)\/(.+)$/;
    const match = s3Uri.match(s3UriPattern);

    if (match) {
        const bucket = match[1];
        const key = match[2];
        return { bucket, key };
    }

    throw new Error("Invalid S3 URI format");
}

export async function getStreamFromS3Url (s3Url: string) {

    const { bucket, key } = parseS3Uri(s3Url);

    console.log(`BUCKET: ${bucket}| KEY: ${key}`);

    const stream = await s3Client.send(new GetObjectCommand({
        Bucket: bucket,
        Key: key,
    }));

    if (stream.Body === undefined) throw new Error(`No Stream Retrieved from S3 for ${s3Url}`);

    return stream.Body;
}