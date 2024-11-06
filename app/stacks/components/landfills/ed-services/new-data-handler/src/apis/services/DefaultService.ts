/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Monitor } from '../models/Monitor';
import type { NewMonitorRequest } from '../models/NewMonitorRequest';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class DefaultService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Create a new monitor
     * Creates a new monitor for a specific municipality with a specific type of monitoring.
     * @param requestBody The information needed to create a new monitor
     * @returns Monitor Monitor created successfully
     * @throws ApiError
     */
    public postMonitoring(
        requestBody: NewMonitorRequest,
    ): CancelablePromise<Monitor> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/monitoring',
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                400: `Bad request, missing or invalid parameters`,
                500: `Internal server error`,
            },
        });
    }
    /**
     * Retrieve all monitors
     * Retrieve a list of all monitors, with optional filtering. Each monitor includes details about the monitored municipality, type of monitoring, and the date when the monitoring was requested.
     * @param idMunicipality Filter monitors by municipality ID
     * @param type Filter monitors by the type of monitoring (e.g., WILDFIRE)
     * @param longitude Filter monitor by municipality not known, looking up a spatial point to get the municipality, also requires longitude to work
     * @param latitude Filter monitor by municipality not known, looking up a spatial point to get the municipality, also requires latitude to work
     * @returns Monitor A list of monitors
     * @throws ApiError
     */
    public getMonitoring(
        idMunicipality?: number,
        type?: 'WILDFIRE',
        longitude?: number,
        latitude?: number,
    ): CancelablePromise<Array<Monitor>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/monitoring',
            query: {
                'idMunicipality': idMunicipality,
                'type': type,
                'longitude': longitude,
                'latitude': latitude,
            },
            errors: {
                500: `Internal server error`,
            },
        });
    }
    /**
     * Remove a monitor
     * Deletes an existing monitor identified by the monitor ID.
     * @param monitorId ID of the monitor to delete
     * @returns void
     * @throws ApiError
     */
    public deleteMonitoring(
        monitorId: number,
    ): CancelablePromise<void> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/monitoring/{monitorId}',
            path: {
                'monitorId': monitorId,
            },
            errors: {
                404: `Monitor not found`,
                500: `Internal server error`,
            },
        });
    }
}
