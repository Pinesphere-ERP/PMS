import React from 'react';
import styles from './page.module.css';

interface Property {
  property_id: string;
  property_name: string;
  property_type?: string;
  description?: string;
  cover_image?: string;
  whatsapp_number?: string;
  address?: {
    address?: string;
    city?: string;
    state?: string;
    pincode?: string;
    google_maps_url?: string;
  };
  gallery: { type: string; url: string }[];
}

interface RoomType {
  room_name: string;
  description?: string;
  max_capacity: int;
  base_price: number;
  weekend_price?: number;
  seasonal_price?: number;
  holiday_price?: number;
  extra_adult?: number;
  extra_child?: number;
  amenities: string[];
  images: string[];
}

async function getProperty(slug: string): Promise<Property | null> {
  // In a real app, you might read the backend URL from environment
  const backendUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
  const res = await fetch(`${backendUrl}/api/v1/public/properties/${slug}`, { next: { revalidate: 60 } });
  
  if (!res.ok) {
    return null;
  }
  
  return res.json();
}

async function getRooms(slug: string): Promise<RoomType[]> {
  const backendUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
  const res = await fetch(`${backendUrl}/api/v1/public/properties/${slug}/rooms`, { next: { revalidate: 60 } });
  
  if (!res.ok) {
    return [];
  }
  
  return res.json();
}

export async function generateMetadata({ params }: { params: { slug: string } }) {
  const property = await getProperty(params.slug);
  if (!property) {
    return {
      title: 'Property Not Found',
    };
  }
  
  const ogImage = property.cover_image || 'https://images.unsplash.com/photo-1542314831-c6a4d275722c?q=80&w=2000&auto=format&fit=crop';
  
  return {
    title: `${property.property_name} | Book your stay`,
    description: property.description || `Experience a wonderful stay at ${property.property_name}.`,
    openGraph: {
      title: `${property.property_name} | Book your stay`,
      description: property.description || `Experience a wonderful stay at ${property.property_name}.`,
      images: [{ url: ogImage }],
      type: 'website',
    },
    twitter: {
      card: 'summary_large_image',
      title: `${property.property_name} | Book your stay`,
      description: property.description || `Experience a wonderful stay at ${property.property_name}.`,
      images: [ogImage],
    },
    alternates: {
      canonical: `/p/${params.slug}`,
    }
  };
}

export default async function PropertyShowcase({ params }: { params: { slug: string } }) {
  const property = await getProperty(params.slug);
  const rooms = await getRooms(params.slug);

  if (!property) {
    return (
      <div className={styles.notFound}>
        <h1 className={styles.notFoundTitle}>Property Not Found</h1>
        <p className={styles.notFoundText}>The property you are looking for does not exist or is currently inactive.</p>
      </div>
    );
  }

  const coverImage = property.cover_image || 'https://images.unsplash.com/photo-1542314831-c6a4d275722c?q=80&w=2000&auto=format&fit=crop';
  const fullAddress = property.address 
    ? [property.address.address, property.address.city, property.address.state, property.address.pincode].filter(Boolean).join(', ')
    : 'Address not provided';

  return (
    <div className={styles.container}>
      {/* Hero Section */}
      <header 
        className={styles.hero} 
        style={{ backgroundImage: `url(${coverImage})` }}
      >
        <div className={styles.heroOverlay}></div>
        <div className={styles.heroContent}>
          <h1 className={styles.title}>{property.property_name}</h1>
          <div className={styles.subtitle}>
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
              <circle cx="12" cy="10" r="3"></circle>
            </svg>
            {property.address?.city || 'Premium Location'}
          </div>
        </div>
      </header>

      <main className={styles.mainContent}>
        {/* Main Left Column */}
        <div>
          <section style={{ marginBottom: '3rem' }}>
            <h2 className={styles.sectionTitle}>About this property</h2>
            <p className={styles.aboutText}>
              {property.description || 'Welcome to our beautiful property. We offer a comfortable and memorable stay with premium amenities and excellent service.'}
            </p>
          </section>

          {property.gallery && property.gallery.length > 0 && (
            <section style={{ marginBottom: '3rem' }}>
              <h2 className={styles.sectionTitle}>Gallery</h2>
              <div className={styles.galleryGrid}>
                {property.gallery.map((img, idx) => (
                  <img key={idx} src={img.url} alt={`Gallery ${idx + 1}`} className={styles.galleryImg} />
                ))}
              </div>
            </section>
          )}

          <section>
            <h2 className={styles.sectionTitle}>Our Rooms</h2>
            {rooms.length === 0 ? (
              <p className={styles.aboutText}>No rooms available at the moment.</p>
            ) : (
              rooms.map((room) => (
                <div key={room.room_name} className={styles.roomCard}>
                  <div className={styles.roomImages}>
                    <img 
                      src={room.images.length > 0 ? room.images[0] : 'https://images.unsplash.com/photo-1611892440504-42a792e24d32?q=80&w=800&auto=format&fit=crop'} 
                      alt={room.room_name} 
                      className={styles.roomImg} 
                    />
                  </div>
                  <div className={styles.roomDetails}>
                    <h3 className={styles.roomName}>{room.room_name}</h3>
                    <p className={styles.roomDesc}>{room.description || 'A comfortable room for your stay.'}</p>
                    
                    <div className={styles.amenities}>
                      <span className={styles.amenityTag}>
                        👥 Up to {room.max_capacity} guests
                      </span>
                      {room.amenities.slice(0, 5).map((amenity, idx) => (
                        <span key={idx} className={styles.amenityTag}>{amenity}</span>
                      ))}
                      {room.amenities.length > 5 && (
                        <span className={styles.amenityTag}>+{room.amenities.length - 5} more</span>
                      )}
                    </div>
                    
                    <div className={styles.pricingGrid}>
                      <div className={styles.priceItem}>
                        <span className={styles.priceLabel}>Base Price</span>
                        <span className={styles.priceValue}>₹{room.base_price.toLocaleString()}</span>
                      </div>
                      {room.weekend_price && (
                        <div className={styles.priceItem}>
                          <span className={styles.priceLabel}>Weekend</span>
                          <span className={styles.priceValue}>₹{room.weekend_price.toLocaleString()}</span>
                        </div>
                      )}
                      {room.holiday_price && (
                        <div className={styles.priceItem}>
                          <span className={styles.priceLabel}>Holiday</span>
                          <span className={styles.priceValue}>₹{room.holiday_price.toLocaleString()}</span>
                        </div>
                      )}
                      {room.extra_adult && (
                        <div className={styles.priceItem}>
                          <span className={styles.priceLabel}>Extra Bed</span>
                          <span className={styles.priceValue}>₹{room.extra_adult.toLocaleString()}</span>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              ))
            )}
          </section>
        </div>

        {/* Right Sidebar */}
        <aside>
          <div className={styles.contactCard}>
            <h2 className={styles.sectionTitle} style={{ marginBottom: '1.5rem' }}>Contact & Location</h2>
            
            <div className={styles.contactItem}>
              <div className={styles.contactIcon}>
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"></path></svg>
              </div>
              <div className={styles.contactText}>
                {property.whatsapp_number || 'Contact number not provided'}
              </div>
            </div>

            <div className={styles.contactItem}>
              <div className={styles.contactIcon}>
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path><circle cx="12" cy="10" r="3"></circle></svg>
              </div>
              <div className={styles.contactText}>
                {fullAddress}
              </div>
            </div>

            {property.address?.google_maps_url && (
              <a 
                href={property.address.google_maps_url} 
                target="_blank" 
                rel="noopener noreferrer"
                style={{ 
                  display: 'block', 
                  width: '100%', 
                  padding: '1rem', 
                  backgroundColor: '#0f172a', 
                  color: 'white', 
                  textAlign: 'center', 
                  borderRadius: '0.5rem',
                  textDecoration: 'none',
                  fontWeight: '600',
                  marginTop: '1rem'
                }}
              >
                View on Google Maps
              </a>
            )}
            
            {property.whatsapp_number && (
              <a 
                href={`https://wa.me/${property.whatsapp_number.replace(/\D/g,'')}`} 
                target="_blank" 
                rel="noopener noreferrer"
                style={{ 
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '0.5rem',
                  width: '100%', 
                  padding: '1rem', 
                  backgroundColor: '#25D366', 
                  color: 'white', 
                  textAlign: 'center', 
                  borderRadius: '0.5rem',
                  textDecoration: 'none',
                  fontWeight: '600',
                  marginTop: '1rem'
                }}
              >
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"></path></svg>
                Chat on WhatsApp
              </a>
            )}
          </div>
        </aside>
      </main>
    </div>
  );
}
