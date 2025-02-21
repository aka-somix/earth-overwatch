/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { DetectionValidity } from './DetectionValidity';
export type Landfill = {
    id: number;
    /**
     * Detection type.
     */
    detected_from?: string;
    /**
     * Time when the landfill was detected.
     */
    detection_time?: string;
    /**
     * ID of the municipality.
     */
    municipality_id: number;
    /**
     * The confidence of the detection (normalized between 0 and 1)
     */
    confidence?: number;
    status: DetectionValidity;
    imageURI?: string;
    geometry: ({
        type?: string;
        /**
         * Coordinates of the polygon
         */
        coordinates?: Array<Array<Array<number>>>;
    } | {
        type?: string;
        /**
         * Coordinates of the point
         */
        coordinates?: Array<number>;
    });
};

