// tailwind.config.js
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{html,js,svelte,ts}'],
  theme: {
    extend: {
      colors: {
        primary: '#0EA5E9',
        'primary-dark': '#0284C7',
        accent: '#38BDF8',
        income: '#16A34A',
        expense: '#DC2626',
        warning: '#F59E0B',
        surface: '#F1F5F9',
        card: '#FFFFFF',
        border: '#E2E8F0'
      },
      fontFamily: {
        sans: ['"Plus Jakarta Sans"', 'system-ui', 'sans-serif']
      },
      borderRadius: {
        DEFAULT: '0.625rem',
        lg: '0.875rem',
        xl: '1rem',
        '2xl': '1.25rem'
      }
    }
  },
  plugins: []
};
