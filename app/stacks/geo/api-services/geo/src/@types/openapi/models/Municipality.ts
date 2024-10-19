/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
export type Municipality = {
    /**
     * Unique identifier of the municipality
     */
    id?: number;
    /**
     * Name of the municipality
     */
    name?: string;
    /**
     * The region the municipality belongs to
     */
    region?: string;
    /**
     * Geographical boundaries of the municipality (MultiPolygon in SRID 4326)
     */
    boundaries?: any
};

