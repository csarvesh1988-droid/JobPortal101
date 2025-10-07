# JobPortal101 - Next.js Routing & Rendering Strategy

## 🎯 Hybrid Rendering Approach

Our routing strategy optimizes for **SEO performance** on public pages and **real-time interactivity** on user-specific pages.

## 📋 Route Mapping & Rendering Strategy

### 🌍 Public Pages (SEO Critical) - **SSG/ISR**

| Route | Strategy | Revalidation | Purpose |
|-------|----------|--------------|---------|
| `/` | **SSG** | Build time | Homepage with featured jobs |
| `/jobs` | **ISR** | 60 seconds | Job listings with search |
| `/jobs/[slug]` | **ISR** | 300 seconds | Individual job pages |
| `/companies` | **ISR** | 3600 seconds | Company directory |
| `/companies/[slug]` | **ISR** | 1800 seconds | Company profiles |
| `/candidates/[slug]` | **ISR** | 1800 seconds | Public candidate profiles |
| `/about` | **SSG** | Build time | Static about page |
| `/pricing` | **SSG** | Build time | Points pricing info |
| `/help` | **SSG** | Build time | Help documentation |

### 🔐 Authenticated Pages - **CSR**

| Route | Strategy | Purpose |
|-------|----------|---------|
| `/dashboard` | **CSR** | User dashboard with real-time data |
| `/dashboard/profile` | **CSR** | Profile management |
| `/dashboard/applications` | **CSR** | Application tracking |
| `/dashboard/points` | **CSR** | Points history and usage |
| `/dashboard/saved-jobs` | **CSR** | Saved jobs management |

### 👥 Recruiter Pages - **CSR**

| Route | Strategy | Purpose |
|-------|----------|---------|
| `/recruiter/dashboard` | **CSR** | Recruiter analytics |
| `/recruiter/jobs` | **CSR** | Job management |
| `/recruiter/jobs/new` | **CSR** | Create new job |
| `/recruiter/jobs/[id]/edit` | **CSR** | Edit job posting |
| `/recruiter/applications` | **CSR** | Application management |
| `/recruiter/company` | **CSR** | Company profile management |

### 🔧 Admin Pages - **CSR**

| Route | Strategy | Purpose |
|-------|----------|---------|
| `/admin/*` | **CSR** | All admin functionality |
| `/admin/dashboard` | **CSR** | Admin analytics |
| `/admin/users` | **CSR** | User management |
| `/admin/points` | **CSR** | Points system configuration |
| `/admin/filters` | **CSR** | Premium filter management |
| `/admin/smtp` | **CSR** | Email configuration |

### 🔍 Search & Filters - **SSR**

| Route | Strategy | Purpose |
|-------|----------|---------|
| `/search` | **SSR** | Dynamic search with SEO |
| `/jobs/search` | **SSR** | Advanced job search |
| `/companies/search` | **SSR** | Company search |

### 🔑 Auth Pages - **CSR**

| Route | Strategy | Purpose |
|-------|----------|---------|
| `/auth/login` | **CSR** | Login form |
| `/auth/register` | **CSR** | Registration |
| `/auth/forgot-password` | **CSR** | Password reset |
| `/auth/verify` | **CSR** | Email verification |

## 🚀 Performance Optimizations

### Static Generation (SSG)
```typescript
// For homepage and static pages
export async function generateStaticParams() {
  return []
}

export default async function HomePage() {
  // Static content at build time
  const featuredJobs = await getFeaturedJobs()
  return <HomePageComponent jobs={featuredJobs} />
}
```

### Incremental Static Regeneration (ISR)
```typescript
// For job and company pages
export const revalidate = 300 // 5 minutes

export default async function JobPage({ params }: { params: { slug: string } }) {
  const job = await getJobBySlug(params.slug)
  return <JobDetailsComponent job={job} />
}
```

### Server-Side Rendering (SSR)
```typescript
// For search pages
export default async function SearchPage({ searchParams }: { searchParams: any }) {
  const results = await searchJobs(searchParams)
  return <SearchResultsComponent results={results} />
}
```

### Client-Side Rendering (CSR)
```typescript
'use client'
// For interactive dashboards
export default function UserDashboard() {
  const { data, loading } = useUserData()
  return <DashboardComponent data={data} loading={loading} />
}
```

## 📱 API Route Strategy

### Public API Routes (Cached)
```
GET /api/jobs - Cache: 60s
GET /api/jobs/[slug] - Cache: 300s
GET /api/companies - Cache: 3600s
GET /api/companies/[slug] - Cache: 1800s
```

### Private API Routes (No Cache)
```
POST /api/auth/login
GET /api/user/profile
POST /api/applications
GET /api/user/points
```

### Search API Routes (Short Cache)
```
GET /api/search/jobs - Cache: 30s
GET /api/search/companies - Cache: 60s
```

## 🎨 Component Architecture

### Layout Hierarchy
```
app/
├── layout.tsx (Root layout)
├── page.tsx (Homepage - SSG)
├── jobs/
│   ├── layout.tsx (Jobs layout)
│   ├── page.tsx (Jobs listing - ISR)
│   └── [slug]/
│       └── page.tsx (Job details - ISR)
├── dashboard/
│   ├── layout.tsx (Auth required)
│   ├── page.tsx (Dashboard - CSR)
│   └── [...pages]/
│       └── page.tsx (Sub-pages - CSR)
└── admin/
    ├── layout.tsx (Admin auth)
    └── [...pages]/
        └── page.tsx (Admin pages - CSR)
```

### Shared Components
```typescript
// SEO Component for static pages
export function SEOHead({ title, description, canonical }) {
  return (
    <Head>
      <title>{title}</title>
      <meta name="description" content={description} />
      <link rel="canonical" href={canonical} />
      <meta property="og:title" content={title} />
      <meta property="og:description" content={description} />
    </Head>
  )
}

// Loading states for CSR pages
export function LoadingSpinner() {
  return <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
}
```

## 🔄 Data Fetching Patterns

### Static Data (Build Time)
```typescript
// Used in SSG pages
async function getStaticData() {
  const res = await fetch(`${API_URL}/static-data`)
  return res.json()
}
```

### Dynamic Data (Request Time)
```typescript
// Used in ISR/SSR pages
async function getDynamicData(params: any) {
  const res = await fetch(`${API_URL}/dynamic-data?${new URLSearchParams(params)}`)
  return res.json()
}
```

### Client Data (Runtime)
```typescript
// Used in CSR pages
function useClientData() {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  
  useEffect(() => {
    fetchData().then(setData).finally(() => setLoading(false))
  }, [])
  
  return { data, loading }
}
```

## 🔒 Authentication Flow

### Protected Routes
```typescript
// middleware.ts
export function middleware(request: NextRequest) {
  const token = request.cookies.get('auth-token')
  
  if (request.nextUrl.pathname.startsWith('/dashboard') && !token) {
    return NextResponse.redirect(new URL('/auth/login', request.url))
  }
  
  if (request.nextUrl.pathname.startsWith('/admin') && !isAdmin(token)) {
    return NextResponse.redirect(new URL('/dashboard', request.url))
  }
}
```

### Auth Context
```typescript
// Context for managing auth state across CSR pages
export const AuthContext = createContext({
  user: null,
  login: () => {},
  logout: () => {},
  loading: false
})
```

## 📊 SEO & Meta Management

### Dynamic Meta Tags
```typescript
// For ISR pages
export async function generateMetadata({ params }: { params: { slug: string } }) {
  const job = await getJobBySlug(params.slug)
  
  return {
    title: `${job.title} at ${job.company_name} | JobPortal101`,
    description: job.description.substring(0, 160),
    openGraph: {
      title: job.title,
      description: job.description,
      images: [job.company_logo],
    },
  }
}
```

### Structured Data
```typescript
// JSON-LD for job postings
export function JobStructuredData({ job }) {
  const structuredData = {
    "@context": "https://schema.org/",
    "@type": "JobPosting",
    "title": job.title,
    "description": job.description,
    "hiringOrganization": {
      "@type": "Organization",
      "name": job.company_name
    }
  }
  
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(structuredData) }}
    />
  )
}
```

## 🎯 Performance Metrics Target

- **First Contentful Paint**: < 1.5s
- **Largest Contentful Paint**: < 2.5s  
- **First Input Delay**: < 100ms
- **Cumulative Layout Shift**: < 0.1
- **Time to Interactive**: < 3.5s

## 🚦 Caching Strategy

### Browser Caching
- Static assets: 1 year
- API responses: Based on route type
- Images: 1 week with proper versioning

### CDN Caching  
- Static pages: 1 hour
- ISR pages: Based on revalidation time
- API routes: Custom per endpoint

This routing strategy ensures optimal performance for both SEO and user experience while maintaining the scalability needed for high concurrent usage.