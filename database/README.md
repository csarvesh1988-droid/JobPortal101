# JobPortal101 Database Schema

## Overview
High-performance PostgreSQL schema designed for concurrent job portal operations with integrated points/rewards economy.

## Key Features
- **Scalability**: Optimized indexes for fast queries even with millions of records
- **Concurrency**: Race condition handling for points transactions
- **Audit Trail**: Immutable transaction ledger for financial integrity
- **Flexibility**: JSONB fields for extensible configuration
- **Performance**: Minimal JOINs, strategic denormalization

## Core Tables

### User Management
- `users` - Core user accounts with roles (candidate/recruiter/admin)
- `user_profiles` - Extended candidate information and preferences
- `user_skills` - Skills with proficiency levels
- `skills` - Master skills catalog

### Company & Jobs
- `companies` - Company profiles and verification status
- `company_members` - Recruiter-company relationships
- `jobs` - Job postings with full search optimization
- `job_skills` - Required skills per job
- `job_applications` - Application tracking

### Points Economy (Critical)
- `user_points` - Current balance and totals (fast lookups)
- `points_transactions` - Immutable ledger (audit trail)
- `premium_filters` - Configurable paid features
- `premium_filter_usage` - Usage tracking for limits

### Administration
- `system_config` - Runtime configuration (SMTP, limits, etc.)
- `admin_audit_log` - All admin actions logged

## Performance Optimizations

### Indexes
- Composite indexes on common query patterns
- Full-text search on job titles/descriptions
- Partial indexes for active records
- GIN indexes for JSONB and text search

### Triggers
- Automatic timestamp updates
- Real-time points balance maintenance
- Data consistency enforcement

## Security Features
- Email validation constraints
- Positive balance enforcement
- Admin action audit trail
- Encrypted sensitive config values

## Development Setup

```sql
-- Create database
CREATE DATABASE jobportal101;

-- Run schema
\i /app/database/schema.sql

-- Verify installation
SELECT COUNT(*) FROM premium_filters; -- Should return 6 default filters
```

## Default Configuration
- Premium filters cost: **0 points** (configurable via admin)
- Signup bonus: **50 points**
- Profile completion: **100 points**  
- Referral bonus: **200 points**
- Default admin: admin@jobportal101.com (password: admin123)

## Points System Logic

### Transaction Integrity
All points changes MUST:
1. Create entry in `points_transactions` 
2. Update `user_points.points_balance` atomically
3. Include reference_id for traceability

### Premium Filter Flow
1. User requests premium filter
2. Check points balance >= cost
3. Create debit transaction (atomic)
4. Execute filter query
5. Log usage in `premium_filter_usage`

### Audit Requirements
- All admin config changes logged
- Points transactions are immutable
- Failed transactions recorded with reason

## Scaling Considerations
- Partition `points_transactions` by date for large volumes
- Read replicas for job search queries
- Redis cache for frequently accessed data
- Connection pooling for high concurrency

---
**Next Step**: Run SQLC generation to create type-safe Go database layer