# JobPortal101 Frontend

## 🚀 Next.js Application with Hybrid Rendering

This is the frontend application for JobPortal101, built with Next.js 14+ and optimized for performance, SEO, and user experience.

## 📋 Architecture Overview

### Rendering Strategy
- **SSG** (Static Site Generation): Homepage, about, pricing pages
- **ISR** (Incremental Static Regeneration): Job listings, company pages, candidate profiles
- **SSR** (Server-Side Rendering): Search pages with dynamic filters
- **CSR** (Client-Side Rendering): User dashboards, admin panels, interactive features

### Tech Stack
- **Framework**: Next.js 14+ with App Router
- **Styling**: Tailwind CSS with custom design system
- **State Management**: React Context for auth, local state for UI
- **API Client**: Custom fetch wrapper with TypeScript
- **Authentication**: JWT with automatic token refresh
- **PWA**: Service Worker with offline capabilities
- **Animations**: Framer Motion for smooth transitions

## 🗂️ Project Structure

```
src/
├── app/                    # App Router pages
│   ├── (public)/          # Public routes (SSG/ISR)
│   ├── dashboard/         # User dashboard (CSR)
│   ├── recruiter/         # Recruiter panel (CSR)
│   ├── admin/            # Admin panel (CSR)
│   └── api/              # API routes
├── components/           # Reusable components
│   ├── ui/               # Base UI components
│   ├── layout/           # Layout components
│   ├── job/              # Job-related components
│   ├── company/          # Company components
│   └── dashboard/        # Dashboard components
├── lib/                  # Utilities and configurations
│   ├── api/              # API client and endpoints
│   ├── auth/             # Authentication logic
│   ├── types/            # TypeScript definitions
│   └── utils/            # Helper functions
└── hooks/               # Custom React hooks
```

## 🎯 Performance Optimizations

### 1. Image Optimization
- Next.js Image component with WebP/AVIF support
- Responsive images with multiple device sizes
- Lazy loading with intersection observer

### 2. Bundle Optimization
- Code splitting at route level
- Dynamic imports for heavy components
- Tree shaking for unused code elimination

### 3. Caching Strategy
- Static assets: 1 year cache
- API responses: Per-endpoint cache rules
- ISR pages: Custom revalidation intervals

### 4. SEO Features
- Dynamic meta tags generation
- Open Graph and Twitter Cards
- JSON-LD structured data for jobs
- Canonical URLs and proper redirects

## 🔐 Authentication Flow

### JWT Token Management
1. Login/Register → Receive JWT token
2. Store in localStorage (httpOnly alternative for production)
3. Auto-refresh on API calls
4. Middleware protection for private routes

### Route Protection
- **Public**: `/`, `/jobs`, `/companies`, `/auth/*`
- **Authenticated**: `/dashboard/*`
- **Recruiter**: `/recruiter/*`
- **Admin**: `/admin/*`

## 📱 Progressive Web App (PWA)

### Features
- Offline job browsing
- Push notifications for application updates
- App-like experience on mobile
- Custom splash screen and icons

### Service Worker
- Caches critical assets
- Background sync for applications
- Push notification handling

## 🎨 Design System

### Colors
- Primary: Blue (600/700 variants)
- Secondary: Gray (50-900 scale)
- Success: Green (500/600)
- Warning: Yellow (500/600)
- Error: Red (500/600)

### Typography
- Font: Inter (web optimized)
- Headings: Font weights 600-800
- Body: Font weight 400-500

### Components
- Consistent spacing (Tailwind scale)
- Accessibility-first design
- Mobile-responsive layouts

## 🚀 Getting Started

### Prerequisites
- Node.js 18+
- npm or yarn
- Backend API running on port 8080

### Installation
```bash
# Install dependencies
npm install

# Set environment variables
cp .env.example .env.local

# Start development server
npm run dev
```

### Environment Variables
```bash
# API Configuration
NEXT_PUBLIC_API_URL=http://localhost:8080
NEXT_PUBLIC_APP_URL=http://localhost:3000

# Feature flags
NEXT_PUBLIC_ENABLE_PWA=true
NEXT_PUBLIC_ENABLE_PUSH_NOTIFICATIONS=true

# SEO
NEXT_PUBLIC_SITE_URL=https://jobportal101.com
```

## 📊 Performance Targets

### Core Web Vitals
- **LCP** (Largest Contentful Paint): < 2.5s
- **FID** (First Input Delay): < 100ms
- **CLS** (Cumulative Layout Shift): < 0.1

### Additional Metrics
- **FCP** (First Contentful Paint): < 1.5s
- **TTI** (Time to Interactive): < 3.5s
- **Speed Index**: < 3.0s

## 🧪 Testing Strategy

### Unit Tests
- Component testing with React Testing Library
- Utility function tests
- API client tests

### Integration Tests
- Page-level testing
- API integration tests
- Authentication flow tests

### E2E Tests
- Critical user journeys
- Cross-browser compatibility
- Mobile responsive tests

## 🚀 Deployment

### Build Process
```bash
# Production build
npm run build

# Start production server
npm start
```

### Optimization Checklist
- [ ] Environment variables configured
- [ ] Image domains whitelisted
- [ ] PWA manifest and icons ready
- [ ] Service worker registered
- [ ] Analytics configured
- [ ] Error monitoring setup

### Performance Monitoring
- Core Web Vitals tracking
- Real User Monitoring (RUM)
- API response time monitoring
- Error rate tracking

## 🔧 Development Commands

```bash
# Development
npm run dev              # Start dev server
npm run build           # Production build
npm run start           # Start production server
npm run lint            # ESLint
npm run type-check      # TypeScript check

# Testing
npm run test            # Run tests
npm run test:watch      # Watch mode
npm run test:coverage   # Coverage report

# Analysis
npm run analyze         # Bundle analyzer
npm run lighthouse      # Performance audit
```

## 📈 Monitoring & Analytics

### Metrics to Track
- Page load times
- User engagement
- Conversion rates
- Error rates
- API performance

### Tools Integration
- Google Analytics 4
- Sentry for error tracking
- Web Vitals monitoring
- Custom performance metrics

---

## 🤝 Contributing

This frontend is part of the larger JobPortal101 project. Follow the established patterns and ensure all changes maintain performance and accessibility standards.

### Code Standards
- TypeScript for all new code
- ESLint + Prettier for formatting
- Accessibility guidelines (WCAG 2.1)
- Performance budgets enforced

For questions or issues, refer to the main project documentation.