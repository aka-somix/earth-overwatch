/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { DetectionValidity } from '../models/DetectionValidity';
import type { Landfill } from '../models/Landfill';
import type { NewLandfillRequest } from '../models/NewLandfillRequest';
export class LandfillsService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Retrieve all detected landfills
     * Get a list of all landfills detected, with optional filtering by municipality.
     * @param municipality Municipality ID to filter landfills.
     * @returns Landfill A list of detected landfills.
     * @throws ApiError
     */
    public getDetections(
        municipality?: number,
    ): CancelablePromise<Array<Landfill>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/detections',
            query: {
                'municipality': municipality,
            },
            errors: {
                500: `Server error.`,
            },
        });
    }
    /**
     * Add a new landfill
     * Submit a new landfill detection record.
     * @param requestBody
     * @returns Landfill Landfill successfully created.
     * @throws ApiError
     */
    public postDetections(
        requestBody: NewLandfillRequest,
    ): CancelablePromise<Landfill> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/detections',
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                400: `Invalid request body.`,
                500: `Server error.`,
            },
        });
    }
    /**
     * Retrieve landfill details
     * Get detailed information about a specific landfill, including its location as a polygon (for SAT) or point (for SIG).
     * @param id The ID of the landfill to retrieve.
     * @returns Landfill Landfill details along with its geometry information.
     * @throws ApiError
     */
    public getDetections1(
        id: number,
    ): CancelablePromise<Landfill> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/detections/{id}',
            path: {
                'id': id,
            },
            errors: {
                404: `No event found with this ID.`,
                500: `Server error.`,
            },
        });
    }
    /**
     * Update landfill validity
     * Update the validity status of a specific landfill (VALID, INVALID, or UNKNOWN).
     * @param id The ID of the landfill to update.
     * @param requestBody
     * @returns Landfill Landfill status updated successfully.
     * @throws ApiError
     */
    public putDetections(
        id: number,
        requestBody: {
            status: DetectionValidity;
        },
    ): CancelablePromise<Landfill> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/detections/{id}',
            path: {
                'id': id,
            },
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                400: `Invalid request body or landfill ID.`,
                404: `Landfill not found.`,
                500: `Server error.`,
            },
        });
    }
}
