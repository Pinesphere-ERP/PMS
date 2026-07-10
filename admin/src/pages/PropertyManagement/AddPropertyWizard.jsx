import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  ChevronRight, 
  ChevronLeft, 
  Check, 
  UploadCloud, 
  Building2, 
  FileText,
  MapPin,
  Camera,
  Banknote,
  ShieldCheck,
  Smartphone
} from 'lucide-react';

const steps = [
  { id: 1, name: 'Owner Info', icon: Building2 },
  { id: 2, name: 'Business', icon: FileText },
  { id: 3, name: 'Property', icon: Building2 },
  { id: 4, name: 'Location', icon: MapPin },
  { id: 5, name: 'Ownership', icon: ShieldCheck },
  { id: 6, name: 'Amenities', icon: Building2 },
  { id: 7, name: 'Photos', icon: Camera },
  { id: 8, name: 'Policies', icon: FileText },
  { id: 9, name: 'Pricing', icon: Banknote },
  { id: 10, name: 'Bank Details', icon: Banknote },
  { id: 11, name: 'Legal Docs', icon: FileText },
  { id: 12, name: 'License', icon: Smartphone },
  { id: 13, name: 'Review', icon: Check },
];

export default function AddPropertyWizard() {
  const navigate = useNavigate();
  const [currentStep, setCurrentStep] = useState(1);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const nextStep = () => setCurrentStep(prev => Math.min(prev + 1, 13));
  const prevStep = () => setCurrentStep(prev => Math.max(prev - 1, 1));

  const handleSubmit = () => {
    setIsSubmitting(true);
    setTimeout(() => {
      setIsSubmitting(false);
      navigate('/properties');
    }, 1500);
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6 animate-fade-in relative pb-24">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-semibold text-gray-900 tracking-tight">Onboard New Property</h1>
        <p className="text-sm text-gray-500 mt-1">Complete the multi-step process to add a new property to the platform.</p>
      </div>

      {/* Progress Indicator */}
      <div className="saas-card p-4 overflow-hidden">
        <div className="flex items-center justify-between relative">
          <div className="absolute left-0 top-1/2 transform -translate-y-1/2 w-full h-0.5 bg-gray-100 -z-10"></div>
          {steps.map((step) => {
            const isCompleted = currentStep > step.id;
            const isCurrent = currentStep === step.id;
            
            // Render only a few steps visually on small screens, full on large
            return (
              <div key={step.id} className={`flex flex-col items-center ${step.id > 1 && step.id < 13 && Math.abs(currentStep - step.id) > 2 ? 'hidden md:flex' : 'flex'}`}>
                <div className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-semibold transition-colors duration-300 ${
                  isCompleted ? 'bg-pine text-white' :
                  isCurrent ? 'bg-pine-100 text-pine ring-2 ring-pine ring-offset-2' :
                  'bg-white border-2 border-gray-200 text-gray-400'
                }`}>
                  {isCompleted ? <Check className="w-4 h-4" /> : step.id}
                </div>
                <span className={`text-[10px] mt-2 uppercase tracking-wider font-medium ${isCurrent ? 'text-pine' : 'text-gray-400'}`}>
                  {step.name}
                </span>
              </div>
            );
          })}
        </div>
      </div>

      {/* Form Area */}
      <div className="saas-card p-6 sm:p-8 min-h-[400px]">
        {currentStep === 1 && (
          <div className="space-y-6 animate-slide-in-right">
            <div>
              <h2 className="text-lg font-semibold text-gray-900">Owner Information</h2>
              <p className="text-sm text-gray-500">Primary contact details for the property owner.</p>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Full Name</label><input type="text" className="saas-input" placeholder="John Doe" /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Designation</label><input type="text" className="saas-input" placeholder="Owner / Director" /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Mobile Number</label><input type="tel" className="saas-input" placeholder="+91" /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">WhatsApp Number</label><input type="tel" className="saas-input" placeholder="+91" /></div>
              <div className="sm:col-span-2"><label className="block text-sm font-medium text-gray-700 mb-1">Email Address</label><input type="email" className="saas-input" placeholder="john@example.com" /></div>
            </div>
          </div>
        )}

        {currentStep === 2 && (
          <div className="space-y-6 animate-slide-in-right">
            <div>
              <h2 className="text-lg font-semibold text-gray-900">Business Information</h2>
              <p className="text-sm text-gray-500">Legal business entity details.</p>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="sm:col-span-2"><label className="block text-sm font-medium text-gray-700 mb-1">Registered Business Name</label><input type="text" className="saas-input" placeholder="Grand Hotels Pvt Ltd" /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Business Type</label>
                <select className="saas-input bg-white"><option>Private Limited</option><option>LLP</option><option>Proprietorship</option></select>
              </div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Registration Number</label><input type="text" className="saas-input" placeholder="CIN/LLPIN" /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">GST Number</label><input type="text" className="saas-input uppercase" placeholder="29ABCDE1234F1Z5" /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">PAN</label><input type="text" className="saas-input uppercase" placeholder="ABCDE1234F" /></div>
            </div>
          </div>
        )}

        {currentStep === 3 && (
          <div className="space-y-6 animate-slide-in-right">
            <div>
              <h2 className="text-lg font-semibold text-gray-900">Property Information</h2>
              <p className="text-sm text-gray-500">Basic physical details of the property.</p>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="sm:col-span-2"><label className="block text-sm font-medium text-gray-700 mb-1">Property Name (Display Name)</label><input type="text" className="saas-input" placeholder="Grand Plaza Hotel" /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Property Type</label>
                <select className="saas-input bg-white"><option>Hotel</option><option>Resort</option><option>Hostel</option></select>
              </div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Star Category</label>
                <select className="saas-input bg-white"><option>3 Star</option><option>4 Star</option><option>5 Star</option></select>
              </div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Total Floors</label><input type="number" className="saas-input" placeholder="5" /></div>
              <div><label className="block text-sm font-medium text-gray-700 mb-1">Total Rooms</label><input type="number" className="saas-input" placeholder="50" /></div>
              <div className="sm:col-span-2"><label className="block text-sm font-medium text-gray-700 mb-1">Description</label><textarea className="saas-input" rows="3" placeholder="A brief description of the property..."></textarea></div>
            </div>
          </div>
        )}

        {currentStep >= 4 && currentStep <= 10 && (
          <div className="space-y-6 animate-slide-in-right flex flex-col items-center justify-center py-12 text-center">
            <div className="w-16 h-16 bg-pine-50 rounded-full flex items-center justify-center mb-4">
              <FileText className="w-8 h-8 text-pine" />
            </div>
            <h2 className="text-xl font-semibold text-gray-900">{steps.find(s => s.id === currentStep)?.name} Setup</h2>
            <p className="text-sm text-gray-500 max-w-sm">This is a mock placeholder for step {currentStep}. In production, this would contain the specific forms for Location, Photos, Pricing, etc.</p>
          </div>
        )}

        {currentStep === 11 && (
          <div className="space-y-6 animate-slide-in-right">
            <div>
              <h2 className="text-lg font-semibold text-gray-900">Legal Documents</h2>
              <p className="text-sm text-gray-500">Upload all required compliance documents.</p>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {['PAN Card', 'GST Certificate', 'Trade License', 'Fire NOC'].map(doc => (
                <div key={doc} className="border-2 border-dashed border-gray-200 rounded-lg p-6 flex flex-col items-center justify-center text-center hover:border-pine-light transition-colors bg-gray-50">
                  <UploadCloud className="h-8 w-8 text-gray-400 mb-2" />
                  <p className="text-sm font-medium text-gray-900">{doc}</p>
                  <p className="text-xs text-gray-500 mt-1">PDF, JPG up to 5MB</p>
                  <button className="mt-3 text-xs font-semibold text-pine bg-white border border-pine-200 px-3 py-1.5 rounded-full shadow-sm hover:bg-pine-50 transition-colors">Browse File</button>
                </div>
              ))}
            </div>
          </div>
        )}

        {currentStep === 12 && (
          <div className="space-y-6 animate-slide-in-right">
            <div>
              <h2 className="text-lg font-semibold text-gray-900">Subscription & License</h2>
              <p className="text-sm text-gray-500">Select a plan and generate the initial license.</p>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {['Basic', 'Pro', 'Enterprise'].map(plan => (
                <div key={plan} className={`border rounded-xl p-5 cursor-pointer transition-all ${plan === 'Pro' ? 'border-pine ring-1 ring-pine bg-pine-50/30' : 'border-gray-200 hover:border-pine-light'}`}>
                  <h3 className="font-semibold text-gray-900">{plan} Plan</h3>
                  <p className="text-2xl font-bold text-gray-900 mt-2">${plan === 'Basic' ? '99' : plan === 'Pro' ? '299' : '999'}<span className="text-xs text-gray-500 font-normal">/mo</span></p>
                  <ul className="mt-4 space-y-2 text-sm text-gray-600">
                    <li className="flex items-center"><Check className="h-4 w-4 text-pine mr-2" /> Up to {plan === 'Basic' ? '20' : plan === 'Pro' ? '100' : 'Unlimited'} Rooms</li>
                    <li className="flex items-center"><Check className="h-4 w-4 text-pine mr-2" /> {plan === 'Basic' ? '1 Device' : plan === 'Pro' ? '5 Devices' : 'Unlimited Devices'}</li>
                  </ul>
                </div>
              ))}
            </div>
          </div>
        )}

        {currentStep === 13 && (
          <div className="space-y-6 animate-slide-in-right">
            <div className="text-center pb-6 border-b border-gray-100">
              <div className="w-16 h-16 bg-green-50 rounded-full flex items-center justify-center mx-auto mb-4">
                <CheckCircle2 className="w-8 h-8 text-green-500" />
              </div>
              <h2 className="text-xl font-semibold text-gray-900">Ready to Submit!</h2>
              <p className="text-sm text-gray-500 mt-1">Please review the details. Submitting will trigger the manual verification queue.</p>
            </div>
            <div className="grid grid-cols-2 gap-x-4 gap-y-6 text-sm">
              <div>
                <span className="block text-gray-500">Property</span>
                <span className="block font-medium text-gray-900">Grand Plaza Hotel</span>
              </div>
              <div>
                <span className="block text-gray-500">Owner</span>
                <span className="block font-medium text-gray-900">John Doe (+91 9876543210)</span>
              </div>
              <div>
                <span className="block text-gray-500">Subscription</span>
                <span className="block font-medium text-gray-900">Pro Plan ($299/mo)</span>
              </div>
              <div>
                <span className="block text-gray-500">Documents</span>
                <span className="block font-medium text-green-600">4/4 Uploaded</span>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Floating Action Footer */}
      <div className="fixed bottom-0 left-0 lg:left-64 right-0 bg-white border-t border-gray-200 p-4 shadow-saas z-40 flex items-center justify-between px-6 sm:px-10">
        <button 
          onClick={prevStep}
          disabled={currentStep === 1}
          className="saas-button-secondary disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <ChevronLeft className="w-4 h-4 mr-1" /> Back
        </button>
        
        <div className="flex space-x-3">
          <button className="saas-button-secondary font-medium text-gray-600">
            Save as Draft
          </button>
          
          {currentStep < 13 ? (
            <button onClick={nextStep} className="saas-button-primary">
              Continue <ChevronRight className="w-4 h-4 ml-1" />
            </button>
          ) : (
            <button onClick={handleSubmit} disabled={isSubmitting} className="saas-button-primary bg-pine">
              {isSubmitting ? 'Submitting...' : 'Complete Onboarding'}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
