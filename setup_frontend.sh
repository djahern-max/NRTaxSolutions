#!/bin/bash

# Set text colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get project name from environment or use default
PROJECT_NAME=${PROJECT_NAME:-"ryze-nrtax"}

# Error handling function
handle_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

# Function to verify that a file exists
verify_file() {
    if [ ! -f "$1" ]; then
        handle_error "File $1 not found. Setup failed."
    else
        echo -e "${GREEN}✓ $1 created successfully${NC}"
    fi
}

echo -e "${GREEN}========================================================"
echo -e "       Setting up ${PROJECT_NAME} Frontend"
echo -e "========================================================${NC}"

# Create frontend directory
echo -e "\n${YELLOW}Creating frontend directory...${NC}"
mkdir -p frontend || handle_error "Failed to create frontend directory"
cd frontend || handle_error "Failed to change to frontend directory"

# Set up React with Tailwind CSS
echo -e "\n${YELLOW}Setting up React with Tailwind CSS...${NC}"
npx create-react-app . --use-npm --no-git || handle_error "Failed to create React app"

# Install dependencies - Note: Using older versions of Tailwind that are known to work well
echo -e "\n${YELLOW}Installing necessary dependencies...${NC}"
npm install --save axios react-router-dom @headlessui/react @heroicons/react || handle_error "Failed to install React dependencies"
npm install --save-dev tailwindcss@3.3.3 postcss@8.4.27 autoprefixer@10.4.14 @tailwindcss/forms@0.5.4 || handle_error "Failed to install Tailwind dependencies"

# Initialize Tailwind - This creates tailwind.config.js and postcss.config.js with the right structure
echo -e "\n${YELLOW}Initializing Tailwind CSS...${NC}"
npx tailwindcss init -p || handle_error "Failed to initialize Tailwind CSS"

# Update the tailwind.config.js file with the proper content and theme settings
echo -e "\n${YELLOW}Configuring Tailwind CSS...${NC}"
cat > tailwind.config.js << 'EOFTAILWIND' || handle_error "Failed to create tailwind.config.js"
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#f0f9ff',
          100: '#e0f2fe',
          200: '#bae6fd',
          300: '#7dd3fc',
          400: '#38bdf8',
          500: '#0ea5e9',
          600: '#0284c7',
          700: '#0369a1',
          800: '#075985',
          900: '#0c4a6e',
        },
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
  ],
}
EOFTAILWIND
verify_file "tailwind.config.js"

# Verify postcss.config.js was created
verify_file "postcss.config.js"

# Add Tailwind directives to CSS
echo -e "\n${YELLOW}Adding Tailwind directives to CSS...${NC}"
cat > src/index.css << 'EOFCSS' || handle_error "Failed to create index.css"
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer components {
  .btn-primary {
    @apply px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500;
  }
  
  .btn-secondary {
    @apply px-4 py-2 bg-white text-gray-700 border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500;
  }
  
  .input-field {
    @apply mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500;
  }
  
  .card {
    @apply bg-white overflow-hidden shadow-md rounded-lg p-6;
  }
}
EOFCSS
verify_file "src/index.css"

# Create React component directories
echo -e "\n${YELLOW}Creating React components...${NC}"
mkdir -p src/{components,pages,context,services} || handle_error "Failed to create component directories"

# Create API service
echo -e "\n${YELLOW}Creating API service...${NC}"
cat > src/services/api.js << 'EOFAPI' || handle_error "Failed to create API service file"
import axios from 'axios';

const API_URL = 'http://localhost:8000/api';

const apiClient = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add token to requests if available
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

export const login = async (email, password) => {
  const response = await axios.post(`http://localhost:8000/token`, 
    new URLSearchParams({
      'username': email,
      'password': password,
    }),
    {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    }
  );
  return response.data;
};

export const register = async (userData) => {
  return apiClient.post('/users/', userData);
};

export const getCurrentUser = async () => {
  return apiClient.get('/users/me/');
};

export const upgradeToPremium = async () => {
  return apiClient.post('/users/me/premium/');
};

export const getTaxGuides = async () => {
  return apiClient.get('/tax-guides/');
};

export const getTaxGuide = async (id) => {
  return apiClient.get(`/tax-guides/${id}`);
};

export const getFaqs = async () => {
  return apiClient.get('/faqs/');
};

export const getFaqsByCategory = async (category) => {
  return apiClient.get(`/faqs/category/${category}`);
};

export const createConsultation = async (consultationData) => {
  return apiClient.post('/consultations/', consultationData);
};

export const getUserConsultations = async () => {
  return apiClient.get('/consultations/');
};

export default apiClient;
EOFAPI
verify_file "src/services/api.js"

# Create auth context
echo -e "\n${YELLOW}Creating authentication context...${NC}"
cat > src/context/AuthContext.js << 'EOFAUTH'
import React, { createContext, useState, useEffect, useContext } from 'react';
import { login as apiLogin, getCurrentUser } from '../services/api';

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const loadUser = async () => {
      const token = localStorage.getItem('token');
      if (token) {
        try {
          const response = await getCurrentUser();
          setUser(response.data);
        } catch (err) {
          console.error('Failed to load user:', err);
          localStorage.removeItem('token');
        }
      }
      setLoading(false);
    };

    loadUser();
  }, []);

  const login = async (email, password) => {
    try {
      setError(null);
      const data = await apiLogin(email, password);
      localStorage.setItem('token', data.access_token);
      const userResponse = await getCurrentUser();
      setUser(userResponse.data);
      return userResponse.data;
    } catch (err) {
      setError(err.response?.data?.detail || 'Login failed');
      throw err;
    }
  };

  const logout = () => {
    localStorage.removeItem('token');
    setUser(null);
  };

  const value = {
    user,
    loading,
    error,
    login,
    logout,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
EOFAUTH
verify_file "src/context/AuthContext.js"

# Create Header component
echo -e "\n${YELLOW}Creating Header component...${NC}"
cat > src/components/Header.js << 'EOFHEADER'
import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Disclosure, Menu, Transition } from '@headlessui/react';
import { Bars3Icon, XMarkIcon, UserCircleIcon } from '@heroicons/react/24/outline';

const navigation = [
  { name: 'Home', to: '/', current: true },
  { name: 'Tax Guides', to: '/tax-guides', current: false },
  { name: 'FAQs', to: '/faqs', current: false },
  { name: 'About', to: '/about', current: false },
];

function classNames(...classes) {
  return classes.filter(Boolean).join(' ');
}

const Header = () => {
  const { user, logout } = useAuth();

  return (
    <Disclosure as="nav" className="bg-primary-800">
      {({ open }) => (
        <>
          <div className="max-w-7xl mx-auto px-2 sm:px-6 lg:px-8">
            <div className="relative flex items-center justify-between h-16">
              <div className="absolute inset-y-0 left-0 flex items-center sm:hidden">
                {/* Mobile menu button*/}
                <Disclosure.Button className="inline-flex items-center justify-center p-2 rounded-md text-gray-200 hover:text-white hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-white">
                  <span className="sr-only">Open main menu</span>
                  {open ? (
                    <XMarkIcon className="block h-6 w-6" aria-hidden="true" />
                  ) : (
                    <Bars3Icon className="block h-6 w-6" aria-hidden="true" />
                  )}
                </Disclosure.Button>
              </div>
              <div className="flex-1 flex items-center justify-center sm:items-stretch sm:justify-start">
                <div className="flex-shrink-0 flex items-center">
                  <Link to="/" className="text-white font-bold text-xl">RyzeNRTax</Link>
                </div>
                <div className="hidden sm:block sm:ml-6">
                  <div className="flex space-x-4">
                    {navigation.map((item) => (
                      <Link
                        key={item.name}
                        to={item.to}
                        className={classNames(
                          item.current ? 'bg-primary-900 text-white' : 'text-gray-200 hover:bg-primary-700 hover:text-white',
                          'px-3 py-2 rounded-md text-sm font-medium'
                        )}
                        aria-current={item.current ? 'page' : undefined}
                      >
                        {item.name}
                      </Link>
                    ))}
                  </div>
                </div>
              </div>
              <div className="absolute inset-y-0 right-0 flex items-center pr-2 sm:static sm:inset-auto sm:ml-6 sm:pr-0">
                {user ? (
                  <Menu as="div" className="ml-3 relative">
                    <div>
                      <Menu.Button className="bg-primary-800 flex text-sm rounded-full focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-primary-800 focus:ring-white">
                        <span className="sr-only">Open user menu</span>
                        <UserCircleIcon className="h-8 w-8 text-white" aria-hidden="true" />
                      </Menu.Button>
                    </div>
                    <Transition
                      enter="transition ease-out duration-100"
                      enterFrom="transform opacity-0 scale-95"
                      enterTo="transform opacity-100 scale-100"
                      leave="transition ease-in duration-75"
                      leaveFrom="transform opacity-100 scale-100"
                      leaveTo="transform opacity-0 scale-95"
                    >
                      <Menu.Items className="origin-top-right absolute right-0 mt-2 w-48 rounded-md shadow-lg py-1 bg-white ring-1 ring-black ring-opacity-5 focus:outline-none">
                        <Menu.Item>
                          {({ active }) => (
                            <Link
                              to="/profile"
                              className={classNames(active ? 'bg-gray-100' : '', 'block px-4 py-2 text-sm text-gray-700')}
                            >
                              Your Profile
                            </Link>
                          )}
                        </Menu.Item>
                        <Menu.Item>
                          {({ active }) => (
                            <Link
                              to="/consultations"
                              className={classNames(active ? 'bg-gray-100' : '', 'block px-4 py-2 text-sm text-gray-700')}
                            >
                              Consultations
                            </Link>
                          )}
                        </Menu.Item>
                        <Menu.Item>
                          {({ active }) => (
                            <button
                              onClick={logout}
                              className={classNames(active ? 'bg-gray-100' : '', 'block w-full text-left px-4 py-2 text-sm text-gray-700')}
                            >
                              Sign out
                            </button>
                          )}
                        </Menu.Item>
                      </Menu.Items>
                    </Transition>
                  </Menu>
                ) : (
                  <div className="flex space-x-4">
                    <Link
                      to="/login"
                      className="text-gray-200 hover:bg-primary-700 hover:text-white px-3 py-2 rounded-md text-sm font-medium"
                    >
                      Login
                    </Link>
                    <Link
                      to="/register"
                      className="bg-white text-primary-600 hover:bg-gray-100 px-3 py-2 rounded-md text-sm font-medium"
                    >
                      Register
                    </Link>
                  </div>
                )}
              </div>
            </div>
          </div>

          <Disclosure.Panel className="sm:hidden">
            <div className="px-2 pt-2 pb-3 space-y-1">
              {navigation.map((item) => (
                <Disclosure.Button
                  key={item.name}
                  as={Link}
                  to={item.to}
                  className={classNames(
                    item.current ? 'bg-primary-900 text-white' : 'text-gray-200 hover:bg-primary-700 hover:text-white',
                    'block px-3 py-2 rounded-md text-base font-medium'
                  )}
                  aria-current={item.current ? 'page' : undefined}
                >
                  {item.name}
                </Disclosure.Button>
              ))}
            </div>
          </Disclosure.Panel>
        </>
      )}
    </Disclosure>
  );
};

export default Header;
EOFHEADER
verify_file "src/components/Header.js"

# Create Footer component
echo -e "\n${YELLOW}Creating Footer component...${NC}"
cat > src/components/Footer.js << 'EOFFOOTER'
import React from 'react';
import { Link } from 'react-router-dom';

const Footer = () => {
  return (
    <footer className="bg-primary-800 text-white">
      <div className="max-w-7xl mx-auto py-12 px-4 overflow-hidden sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div>
            <h3 className="text-lg font-semibold mb-4">RyzeNRTax</h3>
            <p className="text-gray-300 text-sm">
              Helping non-residents navigate US tax laws with confidence and clarity.
            </p>
          </div>
          <div>
            <h3 className="text-lg font-semibold mb-4">Quick Links</h3>
            <ul className="space-y-2">
              <li>
                <Link to="/tax-guides" className="text-gray-300 hover:text-white text-sm">
                  Tax Guides
                </Link>
              </li>
              <li>
                <Link to="/faqs" className="text-gray-300 hover:text-white text-sm">
                  FAQs
                </Link>
              </li>
              <li>
                <Link to="/pricing" className="text-gray-300 hover:text-white text-sm">
                  Pricing
                </Link>
              </li>
              <li>
                <Link to="/about" className="text-gray-300 hover:text-white text-sm">
                  About Us
                </Link>
              </li>
            </ul>
          </div>
          <div>
            <h3 className="text-lg font-semibold mb-4">Contact</h3>
            <p className="text-gray-300 text-sm mb-2">
              Have questions? Get in touch with our team.
            </p>
            <Link
              to="/contact"
              className="inline-block bg-white text-primary-800 px-4 py-2 rounded-md text-sm font-medium hover:bg-gray-100"
            >
              Contact Us
            </Link>
          </div>
        </div>
        <div className="mt-8 pt-8 border-t border-gray-700">
          <p className="text-center text-gray-300 text-sm">
            &copy; {new Date().getFullYear()} RyzeNRTax. All rights reserved.
          </p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
EOFFOOTER
verify_file "src/components/Footer.js"

# Create App.js for routing
echo -e "\n${YELLOW}Creating App.js with routing...${NC}"
cat > src/App.js << 'EOFAPP'
import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';

// Components
import Header from './components/Header';
import Footer from './components/Footer';

// Pages
import HomePage from './pages/HomePage';
import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';
import TaxGuidesPage from './pages/TaxGuidesPage';
import TaxGuideDetailPage from './pages/TaxGuideDetailPage';
import FAQsPage from './pages/FAQsPage';
import PricingPage from './pages/PricingPage';
import ConsultationFormPage from './pages/ConsultationFormPage';
import ConsultationsPage from './pages/ConsultationsPage';
import AboutPage from './pages/AboutPage';

function App() {
  return (
    <AuthProvider>
      <Router>
        <div className="flex flex-col min-h-screen">
          <Header />
          <main className="flex-grow">
            <Routes>
              <Route path="/" element={<HomePage />} />
              <Route path="/login" element={<LoginPage />} />
              <Route path="/register" element={<RegisterPage />} />
              <Route path="/tax-guides" element={<TaxGuidesPage />} />
              <Route path="/tax-guides/:id" element={<TaxGuideDetailPage />} />
              <Route path="/faqs" element={<FAQsPage />} />
              <Route path="/pricing" element={<PricingPage />} />
              <Route path="/consultations" element={<ConsultationsPage />} />
              <Route path="/consultations/new" element={<ConsultationFormPage />} />
              <Route path="/about" element={<AboutPage />} />
            </Routes>
          </main>
          <Footer />
        </div>
      </Router>
    </AuthProvider>
  );
}

export default App;
EOFAPP
verify_file "src/App.js"

# Create index.js
echo -e "\n${YELLOW}Creating index.js...${NC}"
cat > src/index.js << 'EOFINDEX'
import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOFINDEX
verify_file "src/index.js"

# Create React page components script 
echo -e "\n${YELLOW}Creating script to generate page components...${NC}"
cat > create_page_components.sh << 'EOFPAGES' || handle_error "Failed to create page components script"
#!/bin/bash

# Set text colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get project name from environment or use default
PROJECT_NAME=${PROJECT_NAME:-"ryze-nrtax"}

# Error handling function
handle_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}
echo -e "${GREEN}========================================================"
echo -e "       Creating ${PROJECT_NAME} Page Components"
echo -e "========================================================${NC}"

# Create HomePage
echo -e "\n${YELLOW}Creating HomePage...${NC}"
cat > src/pages/HomePage.js << 'EOF' || handle_error "Failed to create HomePage.js"
import React from 'react';
import { Link } from 'react-router-dom';

const HomePage = () => {
  return (
    <div className="flex flex-col min-h-screen">
      {/* Hero Section */}
      <div className="bg-primary-800 text-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
          <div className="text-center max-w-3xl mx-auto">
            <h1 className="text-4xl font-extrabold tracking-tight sm:text-5xl md:text-6xl">
              Non-Resident Tax Solutions
            </h1>
            <p className="mt-6 text-xl">
              Simplified tax guidance for international students, scholars, and professionals navigating the U.S. tax system.
            </p>
            <div className="mt-10 flex justify-center space-x-4">
              <Link
                to="/tax-guides"
                className="inline-flex items-center justify-center px-5 py-3 border border-transparent text-base font-medium rounded-md bg-white text-primary-800 hover:bg-gray-100"
              >
                Browse Tax Guides
              </Link>
              <Link
                to="/register"
                className="inline-flex items-center justify-center px-5 py-3 border border-white text-base font-medium rounded-md text-white hover:bg-primary-700"
              >
                Create Account
              </Link>
            </div>
          </div>
        </div>
      </div>

      {/* Features Section */}
      <div className="py-12 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <h2 className="text-3xl font-extrabold text-gray-900">
              Why Choose RyzeNRTax?
            </h2>
          </div>

          <div className="mt-10">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              <div className="card text-center">
                <div className="mx-auto flex items-center justify-center h-12 w-12 rounded-md bg-primary-600 text-white">
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                  </svg>
                </div>
                <h3 className="mt-4 text-lg font-medium text-gray-900">Expert Guidance</h3>
                <p className="mt-2 text-base text-gray-600">
                  Access clear, accurate information tailored specifically to non-resident tax situations.
                </p>
              </div>

              <div className="card text-center">
                <div className="mx-auto flex items-center justify-center h-12 w-12 rounded-md bg-primary-600 text-white">
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <h3 className="mt-4 text-lg font-medium text-gray-900">Tax Treaty Knowledge</h3>
                <p className="mt-2 text-base text-gray-600">
                  Understand how international tax treaties affect your specific situation and tax obligations.
                </p>
              </div>

              <div className="card text-center">
                <div className="mx-auto flex items-center justify-center h-12 w-12 rounded-md bg-primary-600 text-white">
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8h2a2 2 0 012 2v6a2 2 0 01-2 2h-2v4l-4-4H9a1.994 1.994 0 01-1.414-.586m0 0L11 14h4a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2v4l.586-.586z" />
                  </svg>
                </div>
                <h3 className="mt-4 text-lg font-medium text-gray-900">Personalized Consultation</h3>
                <p className="mt-2 text-base text-gray-600">
                  Get customized advice for your unique tax circumstances from our team of experienced professionals.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

     {/* Featured Tax Guides */}
      <div className="py-12 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <h2 className="text-3xl font-extrabold text-gray-900">
              Featured Tax Guides
            </h2>
            <p className="mt-4 max-w-2xl text-xl text-gray-600 mx-auto">
              Browse our most popular resources for non-resident taxpayers
            </p>
          </div>

          <div className="mt-10 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            <div className="card hover:shadow-lg transition-shadow duration-300">
              <h3 className="text-lg font-medium text-gray-900">US-China Tax Treaty Overview</h3>
              <p className="mt-2 text-base text-gray-600">
                Learn how the US-China tax treaty affects your tax obligations and benefits.
              </p>
              <div className="mt-4">
                <Link to="/tax-guides/1" className="text-primary-600 hover:text-primary-700">
                  Read More →
                </Link>
              </div>
            </div>

            <div className="card hover:shadow-lg transition-shadow duration-300">
              <h3 className="text-lg font-medium text-gray-900">Form 1040-NR Guide</h3>
              <p className="mt-2 text-base text-gray-600">
                Step-by-step guidance on completing Form 1040-NR for non-resident taxpayers.
              </p>
              <div className="mt-4">
                <Link to="/tax-guides/2" className="text-primary-600 hover:text-primary-700">
                  Read More →
                </Link>
              </div>
            </div>

            <div className="card hover:shadow-lg transition-shadow duration-300">
              <h3 className="text-lg font-medium text-gray-900">Scholarship Taxation</h3>
              <p className="mt-2 text-base text-gray-600">
                Understanding how scholarships and fellowships are taxed for non-residents.
              </p>
              <div className="mt-4">
                <Link to="/tax-guides/3" className="text-primary-600 hover:text-primary-700">
                  Read More →
                </Link>
              </div>
            </div>
          </div>

          <div className="mt-12 text-center">
            <Link
              to="/tax-guides"
              className="inline-flex items-center justify-center px-5 py-3 border border-transparent text-base font-medium rounded-md text-white bg-primary-600 hover:bg-primary-700"
            >
              View All Tax Guides
            </Link>
          </div>
        </div>
      </div>

      {/* Testimonials/CTA Section */}
      <div className="py-12 bg-primary-700 text-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h2 className="text-3xl font-extrabold">
            Ready to simplify your US tax filing?
          </h2>
          <p className="mt-4 text-xl">
            Join thousands of international students and professionals who trust RyzeNRTax.
          </p>
          <div className="mt-8">
            <Link
              to="/register"
              className="inline-flex items-center justify-center px-5 py-3 border border-transparent text-base font-medium rounded-md bg-white text-primary-700 hover:bg-gray-100"
            >
              Sign Up for Free
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default HomePage;
EOF

# Create LoginPage
echo -e "\n${YELLOW}Creating LoginPage...${NC}"
cat > src/pages/LoginPage.js << 'EOF'
import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const LoginPage = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [errorMessage, setErrorMessage] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setErrorMessage('');

    try {
      await login(email, password);
      navigate('/');
    } catch (error) {
      console.error('Login error:', error);
      setErrorMessage(error.response?.data?.detail || 'Failed to login. Please check your credentials.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">Sign in to your account</h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            Or{' '}
            <Link to="/register" className="font-medium text-primary-600 hover:text-primary-500">
              create a new account
            </Link>
          </p>
        </div>
        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          {errorMessage && (
            <div className="rounded-md bg-red-50 p-4">
              <div className="text-sm text-red-700">{errorMessage}</div>
            </div>
          )}
          <div className="rounded-md shadow-sm -space-y-px">
            <div>
              <label htmlFor="email-address" className="sr-only">
                Email address
              </label>
              <input
                id="email-address"
                name="email"
                type="email"
                autoComplete="email"
                required
                className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-primary-500 focus:border-primary-500 focus:z-10 sm:text-sm"
                placeholder="Email address"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            </div>
            <div>
              <label htmlFor="password" className="sr-only">
                Password
              </label>
              <input
                id="password"
                name="password"
                type="password"
                autoComplete="current-password"
                required
                className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-primary-500 focus:border-primary-500 focus:z-10 sm:text-sm"
                placeholder="Password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>
          </div>

          <div className="flex items-center justify-between">
            <div className="text-sm">
              <Link to="/forgot-password" className="font-medium text-primary-600 hover:text-primary-500">
                Forgot your password?
              </Link>
            </div>
          </div>

          <div>
            <button
              type="submit"
              disabled={isLoading}
              className="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
            >
              {isLoading ? 'Signing in...' : 'Sign in'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default LoginPage;
EOF

# Create RegisterPage
echo -e "\n${YELLOW}Creating RegisterPage...${NC}"
cat > src/pages/RegisterPage.js << 'EOF'
import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { register } from '../services/api';
import { useAuth } from '../context/AuthContext';

const RegisterPage = () => {
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    confirmPassword: '',
  });
  const [errors, setErrors] = useState({});
  const [isLoading, setIsLoading] = useState(false);
  const [serverError, setServerError] = useState('');
  const navigate = useNavigate();
  const { login } = useAuth();

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value,
    });
  };

  const validateForm = () => {
    const newErrors = {};
    if (!formData.email) newErrors.email = 'Email is required';
    else if (!/\S+@\S+\.\S+/.test(formData.email)) newErrors.email = 'Email is invalid';

    if (!formData.password) newErrors.password = 'Password is required';
    else if (formData.password.length < 8) newErrors.password = 'Password must be at least 8 characters';

    if (formData.password !== formData.confirmPassword) {
      newErrors.confirmPassword = 'Passwords do not match';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (validateForm()) {
      setIsLoading(true);
      setServerError('');

      try {
        await register({
          email: formData.email,
          password: formData.password,
        });
        
        // Automatically log in after registration
        await login(formData.email, formData.password);
        navigate('/');
      } catch (error) {
        console.error('Registration error:', error);
        setServerError(error.response?.data?.detail || 'Registration failed. Please try again.');
      } finally {
        setIsLoading(false);
      }
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">Create your account</h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            Or{' '}
            <Link to="/login" className="font-medium text-primary-600 hover:text-primary-500">
              sign in to your existing account
            </Link>
          </p>
        </div>
        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          {serverError && (
            <div className="rounded-md bg-red-50 p-4">
              <div className="text-sm text-red-700">{serverError}</div>
            </div>
          )}
          <div className="rounded-md shadow-sm -space-y-px">
            <div>
              <label htmlFor="email-address" className="sr-only">
                Email address
              </label>
              <input
                id="email-address"
                name="email"
                type="email"
                autoComplete="email"
                required
                className={`appearance-none rounded-none relative block w-full px-3 py-2 border ${
                  errors.email ? 'border-red-300' : 'border-gray-300'
                } placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-primary-500 focus:border-primary-500 focus:z-10 sm:text-sm`}
                placeholder="Email address"
                value={formData.email}
                onChange={handleChange}
              />
              {errors.email && <p className="mt-1 text-sm text-red-600">{errors.email}</p>}
            </div>
            <div>
              <label htmlFor="password" className="sr-only">
                Password
              </label>
              <input
                id="password"
                name="password"
                type="password"
                autoComplete="new-password"
                required
                className={`appearance-none rounded-none relative block w-full px-3 py-2 border ${
                  errors.password ? 'border-red-300' : 'border-gray-300'
                } placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-primary-500 focus:border-primary-500 focus:z-10 sm:text-sm`}
                placeholder="Password"
                value={formData.password}
                onChange={handleChange}
              />
              {errors.password && <p className="mt-1 text-sm text-red-600">{errors.password}</p>}
            </div>
            <div>
              <label htmlFor="confirmPassword" className="sr-only">
                Confirm Password
              </label>
              <input
                id="confirmPassword"
                name="confirmPassword"
                type="password"
                autoComplete="new-password"
                required
                className={`appearance-none rounded-none relative block w-full px-3 py-2 border ${
                  errors.confirmPassword ? 'border-red-300' : 'border-gray-300'
                } placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-primary-500 focus:border-primary-500 focus:z-10 sm:text-sm`}
                placeholder="Confirm Password"
                value={formData.confirmPassword}
                onChange={handleChange}
              />
              {errors.confirmPassword && (
                <p className="mt-1 text-sm text-red-600">{errors.confirmPassword}</p>
              )}
            </div>
          </div>

          <div>
            <button
              type="submit"
              disabled={isLoading}
              className="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
            >
              {isLoading ? 'Creating Account...' : 'Create Account'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default RegisterPage;
EOF

# Create AboutPage
echo -e "\n${YELLOW}Creating AboutPage...${NC}"
cat > src/pages/AboutPage.js << 'EOF'
import React from 'react';
import { Link } from 'react-router-dom';

const AboutPage = () => {
  return (
    <div className="bg-white py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Hero section */}
        <div className="text-center">
          <h1 className="text-3xl font-extrabold text-gray-900 sm:text-4xl">
            About RyzeNRTax
          </h1>
          <p className="mt-3 max-w-2xl mx-auto text-xl text-gray-500 sm:mt-4">
            Dedicated to simplifying U.S. tax compliance for non-residents
          </p>
        </div>

        {/* Mission section */}
        <div className="mt-12 bg-primary-50 rounded-lg overflow-hidden shadow">
          <div className="px-4 py-5 sm:p-6">
            <h2 className="text-2xl font-bold text-primary-800 mb-4">Our Mission</h2>
            <p className="text-primary-700">
              At RyzeNRTax, we believe that navigating the complex U.S. tax system shouldn't be a barrier for international students, scholars, and professionals pursuing opportunities in the United States. Our mission is to provide clear, accessible, and reliable tax guidance to help non-residents confidently manage their U.S. tax obligations.
            </p>
          </div>
        </div>

        {/* What we do section */}
        <div className="mt-12">
          <h2 className="text-2xl font-bold text-gray-900 mb-6">What We Do</h2>
          <div className="grid grid-cols-1 gap-8 md:grid-cols-3">
            <div className="bg-white overflow-hidden shadow rounded-lg">
              <div className="px-4 py-5 sm:p-6">
                <div className="flex items-center justify-center h-12 w-12 rounded-md bg-primary-600 text-white mx-auto">
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                  </svg>
                </div>
                <h3 className="mt-4 text-lg font-medium text-gray-900 text-center">Educational Resources</h3>
                <p className="mt-2 text-base text-gray-500 text-center">
                  We create comprehensive tax guides tailored to non-resident situations, explaining complex concepts in clear, understandable language.
                </p>
              </div>
            </div>

            <div className="bg-white overflow-hidden shadow rounded-lg">
              <div className="px-4 py-5 sm:p-6">
                <div className="flex items-center justify-center h-12 w-12 rounded-md bg-primary-600 text-white mx-auto">
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8h2a2 2 0 012 2v6a2 2 0 01-2 2h-2v4l-4-4H9a1.994 1.994 0 01-1.414-.586m0 0L11 14h4a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2v4l.586-.586z" />
                  </svg>
                </div>
                <h3 className="mt-4 text-lg font-medium text-gray-900 text-center">Expert Consultations</h3>
                <p className="mt-2 text-base text-gray-500 text-center">
                  Our team of tax professionals provides personalized guidance for your specific non-resident tax situation.
                </p>
              </div>
            </div>

            <div className="bg-white overflow-hidden shadow rounded-lg">
              <div className="px-4 py-5 sm:p-6">
                <div className="flex items-center justify-center h-12 w-12 rounded-md bg-primary-600 text-white mx-auto">
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
                  </svg>
                </div>
                <h3 className="mt-4 text-lg font-medium text-gray-900 text-center">Tax Compliance Support</h3>
                <p className="mt-2 text-base text-gray-500 text-center">
                  We help you understand filing requirements and navigate treaty benefits to ensure compliance with U.S. tax laws.
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* CTA section */}
        <div className="mt-12 bg-primary-700 rounded-lg shadow-xl overflow-hidden">
          <div className="px-4 py-8 sm:px-6 sm:py-12 text-center">
            <h2 className="text-2xl font-bold text-white">
              Ready to simplify your U.S. tax experience?
            </h2>
            <p className="mt-2 text-lg leading-6 text-primary-100">
              Join thousands of non-residents who trust RyzeNRTax for reliable tax guidance.
            </p>
            <div className="mt-8 flex justify-center">
              <div className="inline-flex rounded-md shadow">
                <Link
                  to="/register"
                  className="inline-flex items-center justify-center px-5 py-3 border border-transparent text-base font-medium rounded-md text-primary-600 bg-white hover:bg-gray-50"
                >
                  Get Started
                </Link>
              </div>
              <div className="ml-3 inline-flex">
                <Link
                  to="/contact"
                  className="inline-flex items-center justify-center px-5 py-3 border border-transparent text-base font-medium rounded-md text-white bg-primary-800 hover:bg-primary-900"
                >
                  Contact Us
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AboutPage;
EOF

# Create Placeholder Pages for the rest of the required pages
echo -e "\n${YELLOW}Creating TaxGuidesPage...${NC}"
cat > src/pages/TaxGuidesPage.js << 'EOF'
import React from 'react';
import { Link } from 'react-router-dom';

const TaxGuidesPage = () => {
  return (
    <div className="bg-white py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center">
          <h1 className="text-3xl font-extrabold text-gray-900 sm:text-4xl">
            Non-Resident Tax Guides
          </h1>
          <p className="mt-3 max-w-2xl mx-auto text-xl text-gray-500 sm:mt-4">
            Comprehensive resources to help you understand and navigate U.S. tax laws for non-residents.
          </p>
        </div>

        <div className="mt-12 grid gap-8 md:grid-cols-2 lg:grid-cols-3">
          {/* Placeholder tax guides */}
          <div className="card hover:shadow-lg transition-shadow duration-300">
            <h2 className="text-xl font-semibold text-gray-900">US-China Tax Treaty Overview</h2>
            <p className="mt-2 text-gray-600">
              Learn how the US-China tax treaty affects your tax obligations and benefits.
            </p>
            <div className="mt-4">
              <Link to="/tax-guides/1" className="text-primary-600 hover:text-primary-700">
                Read More →
              </Link>
            </div>
          </div>

          <div className="card hover:shadow-lg transition-shadow duration-300">
            <h2 className="text-xl font-semibold text-gray-900">Form 1040-NR Guide</h2>
            <p className="mt-2 text-gray-600">
              Step-by-step guidance on completing Form 1040-NR for non-resident taxpayers.
            </p>
            <div className="mt-4">
              <Link to="/tax-guides/2" className="text-primary-600 hover:text-primary-700">
                Read More →
              </Link>
            </div>
          </div>

          <div className="card hover:shadow-lg transition-shadow duration-300">
            <h2 className="text-xl font-semibold text-gray-900">Scholarship Taxation</h2>
            <p className="mt-2 text-gray-600">
              Understanding how scholarships and fellowships are taxed for non-residents.
            </p>
            <div className="mt-4">
              <Link to="/tax-guides/3" className="text-primary-600 hover:text-primary-700">
                Read More →
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default TaxGuidesPage;
EOF

echo -e "\n${YELLOW}Creating TaxGuideDetailPage...${NC}"
cat > src/pages/TaxGuideDetailPage.js << 'EOF'
import React from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';

const TaxGuideDetailPage = () => {
  const { id } = useParams();
  const navigate = useNavigate();

  // Placeholder data
  const guide = {
    id: id,
    title: id === '1' ? 'US-China Tax Treaty Overview' : 
           id === '2' ? 'Form 1040-NR Guide' : 
           'Scholarship Taxation',
    content: "This is a placeholder for the tax guide content. In a real application, this would be fetched from an API."
  };

  return (
    <div className="bg-white py-8">
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="mb-6">
          <button
            onClick={() => navigate('/tax-guides')}
            className="text-primary-600 hover:text-primary-800 flex items-center"
          >
            <svg className="h-5 w-5 mr-1" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M9.707 16.707a1 1 0 01-1.414 0l-6-6a1 1 0 010-1.414l6-6a1 1 0 011.414 1.414L5.414 9H17a1 1 0 110 2H5.414l4.293 4.293a1 1 0 010 1.414z" clipRule="evenodd" />
            </svg>
            Back to Tax Guides
          </button>
        </div>

        <div className="prose prose-lg max-w-none">
          <h1>{guide.title}</h1>
          <div className="mt-6">
            <p>{guide.content}</p>
            <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed euismod, nisl quis aliquam ultricies, nisl nisl aliquet nisl, quis aliquam nisl nisl sit amet nisl. Sed euismod, nisl quis aliquam ultricies, nisl nisl aliquet nisl, quis aliquam nisl nisl sit amet nisl.</p>
            <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed euismod, nisl quis aliquam ultricies, nisl nisl aliquet nisl, quis aliquam nisl nisl sit amet nisl. Sed euismod, nisl quis aliquam ultricies, nisl nisl aliquet nisl, quis aliquam nisl nisl sit amet nisl.</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default TaxGuideDetailPage;
EOF

echo -e "\n${YELLOW}Creating FAQsPage...${NC}"
cat > src/pages/FAQsPage.js << 'EOF'
import React from 'react';

const FAQsPage = () => {
  const faqs = [
    {
      id: 1,
      question: "Who needs to file a U.S. tax return?",
      answer: "Generally, non-residents who earned U.S. source income are required to file a U.S. tax return. This includes international students with scholarships or fellowships, foreign workers with U.S. income, and anyone with income from U.S. investments."
    },
    {
      id: 2,
      question: "What forms do I need to file as a non-resident?",
      answer: "Most non-residents will need to file Form 1040-NR. Depending on your situation, you may also need to file additional forms like Form 8843 for students and scholars, or Form 1042-S for certain types of income."
    },
    {
      id: 3,
      question: "How do tax treaties affect my tax obligations?",
      answer: "Tax treaties between the U.S. and your home country may reduce or eliminate tax on certain types of income. Each treaty is different, so it's important to understand the specific provisions that apply to your situation."
    }
  ];

  return (
    <div className="bg-white py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center">
          <h1 className="text-3xl font-extrabold text-gray-900 sm:text-4xl">
            Frequently Asked Questions
          </h1>
          <p className="mt-3 max-w-2xl mx-auto text-xl text-gray-500 sm:mt-4">
            Find answers to common questions about non-resident tax obligations in the U.S.
          </p>
        </div>

        <div className="mt-12 space-y-6">
          {faqs.map((faq) => (
            <div key={faq.id} className="card">
              <h3 className="text-lg font-medium text-gray-900 flex items-start">
                <span className="text-primary-600 mr-2">Q:</span>
                <span>{faq.question}</span>
              </h3>
              <p className="mt-2 text-gray-600 ml-6">
                <span className="text-primary-600 mr-2">A:</span>
                {faq.answer}
              </p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default FAQsPage;
EOF

echo -e "\n${YELLOW}Creating PricingPage...${NC}"
cat > src/pages/PricingPage.js << 'EOF'
import React from 'react';
import { Link } from 'react-router-dom';

const PricingPage = () => {
  const features = {
    free: [
      'Access to basic tax guides',
      'General FAQ answers',
      'Understanding tax forms',
      'Basic treaty information',
    ],
    premium: [
      'All Free features',
      'Advanced tax planning guides',
      'Premium FAQ content',
      'Tax liability calculators',
      'Personalized tax consultations',
      'Document review service',
      'Priority support',
    ],
  };

  return (
    <div className="bg-gray-50 py-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center">
          <h1 className="text-3xl font-extrabold text-gray-900 sm:text-4xl">
            Simple, Transparent Pricing
          </h1>
          <p className="mt-3 max-w-2xl mx-auto text-xl text-gray-500 sm:mt-4">
            Choose the plan that works best for your non-resident tax needs
          </p>
        </div>

        <div className="mt-12 space-y-4 sm:mt-16 sm:space-y-0 sm:grid sm:grid-cols-2 sm:gap-6 lg:max-w-4xl lg:mx-auto xl:max-w-none xl:mx-0 xl:grid-cols-2">
          {/* Free Plan */}
          <div className="border border-gray-200 rounded-lg shadow-sm divide-y divide-gray-200 bg-white">
            <div className="p-6">
              <h2 className="text-lg leading-6 font-medium text-gray-900">Free</h2>
              <p className="mt-4 text-sm text-gray-500">
                Essential resources for understanding non-resident tax basics.
              </p>
              <p className="mt-8">
                <span className="text-4xl font-extrabold text-gray-900">$0</span>
                <span className="text-base font-medium text-gray-500">/mo</span>
              </p>
              <Link
                to="/register"
                className="mt-8 block w-full bg-primary-50 border border-primary-100 rounded-md py-2 text-sm font-semibold text-primary-700 text-center hover:bg-primary-100"
              >
                Get Started
              </Link>
            </div>
            <div className="pt-6 pb-8 px-6">
              <h3 className="text-xs font-medium text-gray-900 tracking-wide uppercase">
                What's included
              </h3>
              <ul role="list" className="mt-6 space-y-4">
                {features.free.map((feature) => (
                  <li key={feature} className="flex space-x-3">
                    <svg
                      className="flex-shrink-0 h-5 w-5 text-green-500"
                      xmlns="http://www.w3.org/2000/svg"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        fillRule="evenodd"
                        d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                        clipRule="evenodd"
                      />
                    </svg>
                    <span className="text-sm text-gray-500">{feature}</span>
                  </li>
                ))}
              </ul>
            </div>
          </div>

          {/* Premium Plan */}
          <div className="border border-primary-200 rounded-lg shadow-sm divide-y divide-gray-200 bg-white">
            <div className="p-6 bg-primary-50 rounded-t-lg">
              <h2 className="text-lg leading-6 font-medium text-primary-900">Premium</h2>
              <p className="mt-4 text-sm text-primary-700">
                Advanced guidance and personalized support for your tax situation.
              </p>
              <p className="mt-8">
                <span className="text-4xl font-extrabold text-primary-900">$29.99</span>
                <span className="text-base font-medium text-primary-700">/mo</span>
              </p>
              <Link
                to="/register"
                className="mt-8 block w-full bg-primary-600 border border-transparent rounded-md py-2 text-sm font-semibold text-white text-center hover:bg-primary-700"
              >
                Get Started
              </Link>
            </div>
            <div className="pt-6 pb-8 px-6">
              <h3 className="text-xs font-medium text-gray-900 tracking-wide uppercase">
                What's included
              </h3>
              <ul role="list" className="mt-6 space-y-4">
                {features.premium.map((feature) => (
                  <li key={feature} className="flex space-x-3">
                    <svg
                      className="flex-shrink-0 h-5 w-5 text-green-500"
                      xmlns="http://www.w3.org/2000/svg"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        fillRule="evenodd"
                        d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                        clipRule="evenodd"
                      />
                    </svg>
                    <span className="text-sm text-gray-500">{feature}</span>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PricingPage;
EOF

echo -e "\n${YELLOW}Creating ConsultationFormPage...${NC}"
cat > src/pages/ConsultationFormPage.js << 'EOF'
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';

const ConsultationFormPage = () => {
  const [formData, setFormData] = useState({
    subject: '',
    message: '',
  });
  const [errors, setErrors] = useState({});
  const navigate = useNavigate();

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value,
    });
  };

  const validateForm = () => {
    const newErrors = {};
    if (!formData.subject.trim()) newErrors.subject = 'Subject is required';
    if (!formData.message.trim()) newErrors.message = 'Message is required';
    else if (formData.message.trim().length < 20) {
      newErrors.message = 'Message should be at least 20 characters';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (validateForm()) {
      // In a real app, this would submit to an API
      alert('Consultation request submitted!');
      navigate('/');
    }
  };

  return (
    <div className="bg-white py-8">
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-extrabold text-gray-900">
            Request a Tax Consultation
          </h1>
          <p className="mt-2 text-lg text-gray-600">
            Submit your questions and our tax experts will help you navigate your non-resident tax situation.
          </p>
        </div>

        <div className="bg-white shadow rounded-lg p-6">
          <form onSubmit={handleSubmit}>
            <div className="mb-6">
              <label htmlFor="subject" className="block text-sm font-medium text-gray-700">
                Subject
              </label>
              <input
                type="text"
                id="subject"
                name="subject"
                value={formData.subject}
                onChange={handleChange}
                className={`mt-1 block w-full rounded-md shadow-sm ${
                  errors.subject
                    ? 'border-red-300 focus:ring-red-500 focus:border-red-500'
                    : 'border-gray-300 focus:ring-primary-500 focus:border-primary-500'
                }`}
                placeholder="e.g., Tax treaty questions, Scholarship taxation"
              />
              {errors.subject && <p className="mt-1 text-sm text-red-600">{errors.subject}</p>}
            </div>

            <div className="mb-6">
              <label htmlFor="message" className="block text-sm font-medium text-gray-700">
                Your Question or Concern
              </label>
              <textarea
                id="message"
                name="message"
                rows="6"
                value={formData.message}
                onChange={handleChange}
                className={`mt-1 block w-full rounded-md shadow-sm ${
                  errors.message
                    ? 'border-red-300 focus:ring-red-500 focus:border-red-500'
                    : 'border-gray-300 focus:ring-primary-500 focus:border-primary-500'
                }`}
                placeholder="Please describe your tax situation and questions in detail..."
              ></textarea>
              {errors.message && <p className="mt-1 text-sm text-red-600">{errors.message}</p>}
            </div>

            <div className="flex justify-end">
              <button
                type="button"
                className="bg-white py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 mr-3"
                onClick={() => navigate('/')}
              >
                Cancel
              </button>
              <button
                type="submit"
                className="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
              >
                Submit Request
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default ConsultationFormPage;
EOF

echo -e "\n${YELLOW}Creating ConsultationsPage...${NC}"
cat > src/pages/ConsultationsPage.js << 'EOF'
import React from 'react';
import { Link } from 'react-router-dom';

const ConsultationsPage = () => {
  // Placeholder consultations data
  const consultations = [];

  return (
    <div className="bg-white py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-2xl font-bold text-gray-900">Your Consultations</h1>
          <Link
            to="/consultations/new"
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-primary-600 hover:bg-primary-700"
          >
            New Consultation
          </Link>
        </div>

        {consultations.length === 0 ? (
          <div className="text-center py-10 bg-gray-50 rounded-lg">
            <svg
              className="mx-auto h-12 w-12 text-gray-400"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z"
              ></path>
            </svg>
            <h3 className="mt-2 text-sm font-medium text-gray-900">No consultations</h3>
            <p className="mt-1 text-sm text-gray-500">Get started by requesting a new consultation.</p>
            <div className="mt-6">
              <Link
                to="/consultations/new"
                className="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
              >
                <svg
                  className="-ml-1 mr-2 h-5 w-5"
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path
                    fillRule="evenodd"
                    d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z"
                    clipRule="evenodd"
                  />
                </svg>
                New Consultation
              </Link>
            </div>
          </div>
        ) : (
          <div className="overflow-hidden shadow ring-1 ring-black ring-opacity-5 md:rounded-lg">
            <table className="min-w-full divide-y divide-gray-300">
              <thead className="bg-gray-50">
                <tr>
                  <th
                    scope="col"
                    className="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6"
                  >
                    Subject
                  </th>
                  <th
                    scope="col"
                    className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900"
                  >
                    Date
                  </th>
                  <th
                    scope="col"
                    className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900"
                  >
                    Status
                  </th>
                  <th scope="col" className="relative py-3.5 pl-3 pr-4 sm:pr-6">
                    <span className="sr-only">View</span>
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 bg-white">
                {consultations.map((consultation) => (
                  <tr key={consultation.id}>
                    <td className="py-4 pl-4 pr-3 text-sm sm:pl-6">
                      <div className="font-medium text-gray-900">{consultation.subject}</div>
                      <div className="text-gray-500 line-clamp-1">{consultation.message.substring(0, 100)}...</div>
                    </td>
                    <td className="px-3 py-4 text-sm text-gray-500">
                      {consultation.created_at}
                    </td>
                    <td className="px-3 py-4 text-sm text-gray-500">
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                        {consultation.status}
                      </span>
                    </td>
                    <td className="py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6">
                      <a href="#" className="text-primary-600 hover:text-primary-900">
                        View
                      </a>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};

export default ConsultationsPage;
EOF

chmod +x create_page_components.sh
echo -e "${GREEN}Page components script created successfully!${NC}"
EOFPAGES

# Make the page components script executable
chmod +x create_page_components.sh || handle_error "Failed to make create_page_components.sh executable"

# Automatically run the page components script
echo -e "\n${YELLOW}Executing page components script...${NC}"
./create_page_components.sh || handle_error "Failed to create page components"

# Verify Tailwind is working properly
echo -e "\n${YELLOW}Verifying Tailwind CSS installation...${NC}"
if grep -q "tailwindcss" package.json && [ -f "tailwind.config.js" ] && [ -f "postcss.config.js" ]; then
    echo -e "${GREEN}Tailwind CSS is properly installed and configured!${NC}"
else
    echo -e "${YELLOW}Warning: Tailwind CSS might not be properly configured. Please check your setup.${NC}"
fi

echo -e "\n${GREEN}${PROJECT_NAME} frontend setup completed successfully!${NC}"
echo -e "\nYou can now start the development server by running:"
echo -e "${YELLOW}cd $(pwd)"
echo -e "npm start${NC}"

cd .. || handle_error "Failed to return to parent directory"

