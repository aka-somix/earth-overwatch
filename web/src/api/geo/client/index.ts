// src/services/apiClient.ts

import axios, { AxiosInstance, AxiosRequestConfig } from 'axios';
import { API_KEY, GEO_API_URL } from '../../config';


const createApiClient = (): AxiosInstance => {
  const config: AxiosRequestConfig = {
    baseURL: GEO_API_URL,
    headers: {
      'x-api-key': API_KEY,
      'Content-Type': 'application/json',
    }
  };

  const client = axios.create(config);

  // Optionally add interceptors for request/response here
  client.interceptors.request.use((request) => {
    // Log or modify request if necessary
    return request;
  });

  client.interceptors.response.use(
    (response) => {
      // Handle successful response
      return response;
    },
    (error) => {
      // Handle errors globally
      console.error('API Error:', error.response || error.message);
      return Promise.reject(error);
    }
  );

  return client;
};

export const apiClient = createApiClient();
