import { useState } from 'react';

export default function PropertySelector({ properties = [], onChange, value }) {
  return (
    <div>
      <label className="block text-xs font-medium text-slate-500 mb-1">Property</label>
      <select
        value={value || ''}
        onChange={(e) => onChange(e.target.value)}
        className="saas-input text-sm"
      >
        <option value="">All Properties</option>
        {properties.map((p) => (
          <option key={p.property_id} value={p.property_id}>
            {p.property_name}
          </option>
        ))}
      </select>
    </div>
  );
}
