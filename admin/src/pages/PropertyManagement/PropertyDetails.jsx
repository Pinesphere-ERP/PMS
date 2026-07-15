import React, { useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { propertyService } from '../../../services/propertyService';
import { 
  Building2, MapPin, User, Mail, Phone, CalendarDays, 
  Bed, Layers, Activity, CheckCircle2, AlertCircle, ArrowLeft,
  CreditCard, Loader2
} from 'lucide-react';

export default function PropertyDetails() {
  const { id } = useParams();
  const [property, setProperty] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchProperty = async () => {
      try {
        setLoading(true);
        const data = await propertyService.getPropertyDetails(id);
        setProperty(data);
        setError(null);
      } catch (err) {
        setError(err.message || 'Failed to fetch property details.');
      } finally {
        setLoading(false);
      }
    };
    fetchProperty();
  }, [id]);

  if (loading) {
    return (
      <div className="flex justify-center items-center h-96">
        <Loader2 className="w-8 h-8 text-indigo-600 animate-spin" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-6">
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg flex items-center gap-3">
          <AlertCircle className="w-5 h-5" />
          <p>{error}</p>
        </div>
      </div>
    );
  }

  if (!property) return null;

  const isSubActive = property.subscription?.status?.toLowerCase() === 'active';

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Link 
            to="/properties"
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors text-gray-500 hover:text-gray-700"
          >
            <ArrowLeft className="w-5 h-5" />
          </Link>
          <div>
            <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
              {property.name}
              {property.onboarding_status === 'completed' && (
                <span className="inline-flex items-center rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20">
                  Active
                </span>
              )}
            </h1>
            <p className="text-sm text-gray-500 mt-1 flex items-center gap-1">
              <Building2 className="w-4 h-4" />
              {property.business} • {property.type || 'Hotel'}
            </p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column: Property & Owner Details */}
        <div className="lg:col-span-2 space-y-6">
          {/* General Information */}
          <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
              <Activity className="w-5 h-5 text-indigo-500" />
              General Information
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-y-4 gap-x-6">
              <div>
                <p className="text-sm font-medium text-gray-500">Property ID</p>
                <p className="mt-1 text-sm text-gray-900 font-mono">{property.id}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-gray-500">Onboarding Status</p>
                <p className="mt-1 text-sm text-gray-900 capitalize">{property.onboarding_status}</p>
              </div>
              <div className="flex items-center gap-2">
                <Bed className="w-4 h-4 text-gray-400" />
                <div>
                  <p className="text-sm font-medium text-gray-500">Total Rooms</p>
                  <p className="text-sm text-gray-900">{property.rooms || 'N/A'}</p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <Layers className="w-4 h-4 text-gray-400" />
                <div>
                  <p className="text-sm font-medium text-gray-500">Floors</p>
                  <p className="text-sm text-gray-900">{property.floors || 'N/A'}</p>
                </div>
              </div>
            </div>
            {property.description && (
              <div className="mt-6 pt-6 border-t border-gray-100">
                <p className="text-sm font-medium text-gray-500 mb-2">Description</p>
                <p className="text-sm text-gray-700 whitespace-pre-wrap">{property.description}</p>
              </div>
            )}
          </div>

          {/* Owner Details */}
          <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
              <User className="w-5 h-5 text-indigo-500" />
              Owner Information
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-y-6 gap-x-6">
              <div>
                <p className="text-sm font-medium text-gray-500">Full Name</p>
                <p className="mt-1 text-sm text-gray-900">{property.owner}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-gray-500">Business Name</p>
                <p className="mt-1 text-sm text-gray-900">{property.business}</p>
              </div>
              <div className="flex items-center gap-3">
                <div className="p-2 bg-indigo-50 rounded-lg">
                  <Mail className="w-4 h-4 text-indigo-600" />
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">Email Address</p>
                  <a href={`mailto:${property.email}`} className="text-sm text-indigo-600 hover:text-indigo-700">
                    {property.email || 'N/A'}
                  </a>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <div className="p-2 bg-indigo-50 rounded-lg">
                  <Phone className="w-4 h-4 text-indigo-600" />
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">Mobile Number</p>
                  <a href={`tel:${property.mobile}`} className="text-sm text-indigo-600 hover:text-indigo-700">
                    {property.mobile || 'N/A'}
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Right Column: Subscription & Quick Actions */}
        <div className="space-y-6">
          {/* Subscription Card */}
          <div className={`bg-white rounded-xl shadow-sm border p-6 ${isSubActive ? 'border-green-200' : 'border-amber-200'}`}>
            <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
              <CreditCard className={`w-5 h-5 ${isSubActive ? 'text-green-500' : 'text-amber-500'}`} />
              Subscription Details
            </h2>
            
            {property.subscription ? (
              <div className="space-y-4">
                <div>
                  <p className="text-sm font-medium text-gray-500">Current Plan</p>
                  <p className="text-lg font-semibold text-gray-900 mt-1">{property.subscription.plan}</p>
                </div>
                
                <div className="flex items-center justify-between py-3 border-y border-gray-100">
                  <div className="flex items-center gap-2">
                    <div className={`w-2 h-2 rounded-full ${isSubActive ? 'bg-green-500' : 'bg-amber-500'}`} />
                    <span className="text-sm font-medium text-gray-700">Status</span>
                  </div>
                  <span className={`inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset ${
                    isSubActive ? 'bg-green-50 text-green-700 ring-green-600/20' : 'bg-amber-50 text-amber-700 ring-amber-600/20'
                  }`}>
                    {property.subscription.status}
                  </span>
                </div>

                <div>
                  <p className="text-sm font-medium text-gray-500 flex items-center gap-1">
                    <CalendarDays className="w-4 h-4" />
                    Valid Until
                  </p>
                  <p className="text-sm text-gray-900 mt-1 font-medium">
                    {new Date(property.subscription.expiry).toLocaleDateString(undefined, {
                      year: 'numeric',
                      month: 'long',
                      day: 'numeric'
                    })}
                  </p>
                </div>
              </div>
            ) : (
              <p className="text-sm text-gray-500 italic">No active subscription found.</p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
