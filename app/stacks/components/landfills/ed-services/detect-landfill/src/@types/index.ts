export interface DetectionResults {
    boxes: Array<Array<number>>;
}

export interface GeoJSONPolygon {
    type: string;
    coordinates: number[][][];
}