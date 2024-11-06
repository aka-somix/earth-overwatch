export interface Input {
    latitude: number;
    longitude: number;
    imageS3URL: string;
}

export interface EventPayload {
    imageS3URL: string;
    latitude: number;
    longitude: number;
    source: string;
}