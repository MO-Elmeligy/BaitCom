CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE account_role AS ENUM ('buyer', 'seller', 'project_manager');
CREATE TYPE listing_status AS ENUM ('draft', 'pending_review', 'published', 'paused', 'sold', 'rejected');
CREATE TYPE project_status AS ENUM ('draft', 'pending_review', 'open', 'funding_complete', 'in_progress', 'completed', 'cancelled', 'rejected');
ALTER TYPE project_status ADD VALUE IF NOT EXISTS 'rejected';
CREATE TYPE join_status AS ENUM ('pending', 'approved', 'declined', 'withdrawn');

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_uid VARCHAR(128),
  phone VARCHAR(24) UNIQUE,
  email VARCHAR(320),
  display_name VARCHAR(120) NOT NULL,
  role account_role NOT NULL DEFAULT 'buyer',
  verified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE users ADD COLUMN IF NOT EXISTS firebase_uid VARCHAR(128);
ALTER TABLE users ALTER COLUMN phone DROP NOT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(320);
CREATE UNIQUE INDEX IF NOT EXISTS users_firebase_uid_idx
  ON users(firebase_uid) WHERE firebase_uid IS NOT NULL;

CREATE TABLE properties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES users(id),
  title VARCHAR(180) NOT NULL,
  description TEXT NOT NULL,
  property_type VARCHAR(32) NOT NULL,
  city VARCHAR(100) NOT NULL,
  district VARCHAR(120) NOT NULL,
  contact_phone VARCHAR(24),
  location GEOGRAPHY(POINT, 4326),
  price_egp NUMERIC(14,2) NOT NULL CHECK (price_egp > 0),
  area_m2 NUMERIC(9,2) NOT NULL CHECK (area_m2 > 0),
  bedrooms SMALLINT CHECK (bedrooms >= 0),
  bathrooms SMALLINT CHECK (bathrooms >= 0),
  commission BOOLEAN NOT NULL DEFAULT false,
  negotiable BOOLEAN NOT NULL DEFAULT true,
  status listing_status NOT NULL DEFAULT 'draft',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE properties ADD COLUMN IF NOT EXISTS contact_phone VARCHAR(24);
CREATE INDEX properties_location_idx ON properties USING GIST(location);
CREATE INDEX properties_search_idx ON properties(city, district, price_egp, status);

CREATE TABLE property_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  media_url TEXT NOT NULL,
  media_type VARCHAR(16) NOT NULL DEFAULT 'image',
  sort_order SMALLINT NOT NULL DEFAULT 0
);
CREATE INDEX property_media_property_sort_idx
  ON property_media(property_id, sort_order);

CREATE TABLE partnership_projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  manager_id UUID NOT NULL REFERENCES users(id),
  title VARCHAR(180) NOT NULL,
  description TEXT NOT NULL,
  city VARCHAR(100) NOT NULL,
  district VARCHAR(120) NOT NULL,
  contact_phone VARCHAR(24),
  location GEOGRAPHY(POINT, 4326),
  land_price_egp NUMERIC(14,2) NOT NULL CHECK (land_price_egp > 0),
  build_cost_egp NUMERIC(14,2) NOT NULL CHECK (build_cost_egp >= 0),
  minimum_contribution_egp NUMERIC(14,2) NOT NULL CHECK (minimum_contribution_egp > 0),
  additional_costs_egp NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (additional_costs_egp >= 0),
  total_units SMALLINT NOT NULL CHECK (total_units > 0),
  target_members SMALLINT NOT NULL CHECK (target_members > 0),
  expected_duration_months SMALLINT NOT NULL CHECK (expected_duration_months > 0),
  allocation_method VARCHAR(32) NOT NULL,
  status project_status NOT NULL DEFAULT 'draft',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE partnership_projects ADD COLUMN IF NOT EXISTS contact_phone VARCHAR(24);
ALTER TABLE partnership_projects ADD COLUMN IF NOT EXISTS minimum_contribution_egp NUMERIC(14,2);
UPDATE partnership_projects
SET minimum_contribution_egp = GREATEST(1, CEIL((land_price_egp + build_cost_egp + additional_costs_egp) / target_members))
WHERE minimum_contribution_egp IS NULL;
ALTER TABLE partnership_projects ALTER COLUMN minimum_contribution_egp SET NOT NULL;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'partnership_projects_minimum_contribution_check'
  ) THEN
    ALTER TABLE partnership_projects
      ADD CONSTRAINT partnership_projects_minimum_contribution_check
      CHECK (minimum_contribution_egp > 0);
  END IF;
END $$;

CREATE INDEX projects_city_status_idx ON partnership_projects(city, status);
CREATE INDEX projects_location_idx ON partnership_projects USING GIST(location);

CREATE TABLE partnership_units (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES partnership_projects(id) ON DELETE CASCADE,
  unit_label VARCHAR(40) NOT NULL,
  area_m2 NUMERIC(9,2),
  floor_number SMALLINT,
  estimated_share_egp NUMERIC(14,2) NOT NULL CHECK (estimated_share_egp > 0),
  UNIQUE(project_id, unit_label)
);

CREATE TABLE partnership_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES partnership_projects(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id),
  unit_id UUID REFERENCES partnership_units(id),
  requested_contribution_egp NUMERIC(14,2) NOT NULL CHECK (requested_contribution_egp > 0),
  status join_status NOT NULL DEFAULT 'pending',
  requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(project_id, user_id)
);

CREATE TABLE admin_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id UUID NOT NULL REFERENCES users(id),
  target_type VARCHAR(32) NOT NULL,
  target_id UUID NOT NULL,
  decision VARCHAR(16) NOT NULL CHECK (decision IN ('approve', 'reject')),
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX admin_audit_log_target_idx ON admin_audit_log(target_type, target_id, created_at);

CREATE TABLE project_updates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES partnership_projects(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES users(id),
  title VARCHAR(180) NOT NULL,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
