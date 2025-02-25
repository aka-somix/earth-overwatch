/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { DetectionValidity } from './DetectionValidity';
import type { Geometry } from './Geometry';
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
     * The confidence of the detection (normalized between 0 and 1).
     */
    confidence?: number;
    status: DetectionValidity;
    imageURI?: string;
    geometry: Geometry;
};

