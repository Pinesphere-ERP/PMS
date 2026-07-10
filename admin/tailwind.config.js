/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Outfit', 'sans-serif'],
      },
      colors: {
        pine: {
          light: '#8aa356',   // Light Olive Green
          DEFAULT: '#5f703a', // Olive Green
          dark: '#2f2e2a',    // Dark Charcoal/Brown
          muted: '#777147',   // Khaki/Muted Olive
          
          50: '#f5f7f2',      // Very light subtle green for backgrounds
          100: '#e5ecd9',
          900: '#1a1c14'      // Deep contrast
        }
      },
      animation: {
        'fade-in': 'fadeIn 0.4s ease-out forwards',
        'slide-up': 'slideUp 0.4s ease-out forwards',
        'slide-in-right': 'slideInRight 0.3s cubic-bezier(0.16, 1, 0.3, 1) forwards',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { opacity: '0', transform: 'translateY(8px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        slideInRight: {
          '0%': { transform: 'translateX(100%)' },
          '100%': { transform: 'translateX(0)' },
        }
      },
      boxShadow: {
        'saas': '0 1px 3px rgba(0,0,0,0.05), 0 4px 12px rgba(0,0,0,0.03)',
        'saas-hover': '0 4px 6px rgba(0,0,0,0.05), 0 10px 24px rgba(0,0,0,0.08)',
        'drawer': '-4px 0 24px rgba(0,0,0,0.05)',
      }
    },
  },
  plugins: [],
}
