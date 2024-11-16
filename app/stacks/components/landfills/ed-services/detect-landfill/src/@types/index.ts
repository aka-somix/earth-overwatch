export interface InputDetail {
    latitude: number,
    longitude: number,
    imageS3URL: string
}

export interface DetectionResults {
    boxes: Array<Array<number>>;
}

export interface GeoJSONPolygon {
    type: string;
    coordinates: number[][][];
}