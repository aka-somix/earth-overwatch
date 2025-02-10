export interface ValidInput {
    id: string;
    bbox: BBox
    s3Source: string;
}

export interface EventPayload extends ValidInput { }

export interface BBox {
    xmin: number,
    xmax: number,
    ymin: number,
    ymax: number,
}
