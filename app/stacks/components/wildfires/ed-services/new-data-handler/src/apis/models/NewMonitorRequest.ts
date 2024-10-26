/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
export type NewMonitorRequest = {
    /**
     * The ID of the municipality to be monitored
     */
    idMunicipality: number;
    /**
     * The type of monitoring
     */
    type: NewMonitorRequest.type;
};
export namespace NewMonitorRequest {
    /**
     * The type of monitoring
     */
    export enum type {
        WILDFIRE = 'WILDFIRE',
    }
}

