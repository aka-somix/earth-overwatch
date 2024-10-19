/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
export type Monitor = {
    /**
     * The unique identifier of the monitor
     */
    id?: number;
    /**
     * The ID of the municipality being monitored
     */
    idMunicipality?: number;
    /**
     * The type of monitoring (e.g., WILDFIRE)
     */
    type?: Monitor.type;
    /**
     * The date when the monitoring was requested
     */
    dateRequested?: string;
};
export namespace Monitor {
    /**
     * The type of monitoring (e.g., WILDFIRE)
     */
    export enum type {
        WILDFIRE = 'WILDFIRE',
    }
}

