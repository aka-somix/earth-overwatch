// src/services/apiService.ts

import { AxiosError } from 'axios';
import { GeoJsonObject } from 'geojson';
import { apiClient } from '../client';

/**
 * Types for the API responses
 */
export interface Municipality {
  id: number;
  name: string;
  region: string;
  boundaries: GeoJsonObject; // Assuming boundaries are complex GeoJSON-like objects, adjust type if necessary
}

export interface Region {
  id: number;
  name: string;
  boundaries: GeoJsonObject; // Assuming boundaries are complex GeoJSON-like objects, adjust type if necessary
}

/**
 * Fetch municipalities by region ID
 * @param regionId - The ID of the region
 * @returns Array of municipalities
 */
export const getMunicipalitiesByRegion = async (regionId: number): Promise<Municipality[]> => {
  try {
    const response = await apiClient.get<Municipality[]>('/geo/municipalities', {
      params: {
        region: regionId,
      },
    });
    return response.data;
  } catch (error) {
    console.error(`Error fetching municipalities for region ${regionId}:`, error);
    throw error;
  }
};

/**
 * Fetch a specific municipality by its ID
 * @param id - The ID of the municipality
 * @returns The municipality details
 */
export const getMunicipalityById = async (id: number): Promise<Municipality | null> => {
  try {
    const response = await apiClient.get<Municipality>(`/geo/municipalities/${id}`);
    return response.data;
  } catch (error) {
    const axiosError = error as AxiosError
    if (axiosError.response && axiosError.response.status === 404) {
      console.error(`Municipality with ID ${id} not found.`);
      return null;
    }
    console.error(`Error fetching municipality with ID ${id}:`, error);
    throw error;
  }
};

/**
 * Fetch all regions
 * @returns Array of regions
 */
export const getAllRegions = async (): Promise<Region[]> => {
  try {
    const response = await apiClient.get<Region[]>('/geo/regions');
    return response.data;
  } catch (error) {
    console.error('Error fetching regions:', error);
    throw error;
  }
};

/**
 * Fetch a specific region by its ID
 * @param id - The ID of the region
 * @returns The region details
 */
export const getRegionById = async (id: number): Promise<Region | null> => {
  try {
    const response = await apiClient.get<Region>(`/geo/regions/${id}`);
    return response.data;
  } catch (error) {
    const axiosError = error as AxiosError
    if (axiosError.response && axiosError.response.status === 404) {
      console.error(`Region with ID ${id} not found.`);
      return null;
    }
    console.error(`Error fetching region with ID ${id}:`, error);
    throw error;
  }
};
