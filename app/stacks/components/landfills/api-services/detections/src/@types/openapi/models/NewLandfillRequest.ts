/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
export type NewLandfillRequest = {
    /**
     * ID of the municipality.
     */
    municipality_id: number;
    /**
     * Detection type.
     */
    detected_from: string;
    /**
     * Time when the landfill was detected.
     */
    detection_time: string;
    /**
     * The confidence of the detection (normalized between 0 and 1)
     */
    confidence: number;
    imageURI: string;
    geometry: any;
};

