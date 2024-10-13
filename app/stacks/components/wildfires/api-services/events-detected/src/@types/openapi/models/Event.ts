/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
export type Event = {
    id?: number;
    /**
     * Detection type.
     */
    detected_from?: string;
    /**
     * Time when the event was detected.
     */
    detection_time?: string;
    /**
     * ID of the municipality.
     */
    municipality_id?: number;
    geometry?: ({
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

