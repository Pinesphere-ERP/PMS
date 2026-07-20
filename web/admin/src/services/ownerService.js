import { fetchAPI } from './api';

export const ownerService = {
  /**
   * Get all owners with their property count
   */
  getOwners: () => fetchAPI('/owners'),

  /**
   * Get a single owner by ID
   */
  getOwner: (ownerId) => fetchAPI(`/owners/${ownerId}`),

  /**
   * Create a new standalone Owner entity
   */
  createOwner: (data) =>
    fetchAPI('/owners', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  /**
   * Update owner profile
   */
  updateOwner: (ownerId, data) =>
    fetchAPI(`/owners/${ownerId}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    }),

  /**
   * Get all properties belonging to an owner
   */
  getOwnerProperties: (ownerId) => fetchAPI(`/owners/${ownerId}/properties`),
};
