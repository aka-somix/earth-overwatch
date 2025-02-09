export interface ValidInput {
    bbox: BBox
    imageS3URL: string;
}

export interface EventPayload {
    bbox: BBox
    imageS3URL: string;
    source: string;
}

export interface BBox {
    xmin: number,
    xmax: number,
    ymin: number,
    ymax: number,
}
