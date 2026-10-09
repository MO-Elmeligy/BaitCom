CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE account_role AS ENUM ('buyer', 'seller', 'project_manager');
CREATE TYPE listing_status AS ENUM ('draft', 'pending_review', 'published', 'paused', 'sold', 'rejected');
CREATE TYPE project_status AS ENUM ('draft', 'pending_review', 'open', 'funding_complete', 'in_progress', 'completed', 'cancelled');
CREATE TYPE join_status AS ENUM ('pending', 'approved', 'declined', 'withdrawn');

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone VARCHAR(24) UNIQUE NOT NULL,
  display_name VARCHAR(120) NOT NULL,
  role account_role NOT NULL DEFAULT 'buyer',
  verified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE properties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES users(id),
  title VARCHAR(180) NOT NULL,
  description TEXT NOT NULL,
  property_type VARCHAR(32) NOT NULL,
  city VARCHAR(100) NOT NULL,
  district VARCHAR(120) NOT NULL,
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
CREATE INDEX properties_location_idx ON properties USING GIST(location);
CREATE INDEX properties_search_idx ON properties(city, district, price_egp, status);

CREATE TABLE property_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  media_url TEXT NOT NULL,
  media_type VARCHAR(16) NOT NULL DEFAULT 'image',
  sort_order SMALLINT NOT NULL DEFAULT 0
);

CREATE TABLE partnership_projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  manager_id UUID NOT NULL REFERENCES users(id),
  title VARCHAR(180) NOT NULL,
  description TEXT NOT NULL,
  city VARCHAR(100) NOT NULL,
  district VARCHAR(120) NOT NULL,
  location GEOGRAPHY(POINT, 4326),
  land_price_egp NUMERIC(14,2) NOT NULL CHECK (land_price_egp > 0),
  build_cost_egp NUMERIC(14,2) NOT NULL CHECK (build_cost_egp >= 0),
  additional_costs_egp NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (additional_costs_egp >= 0),
  total_units SMALLINT NOT NULL CHECK (total_units > 0),
  target_members SMALLINT NOT NULL CHECK (target_members > 0),
  expected_duration_months SMALLINT NOT NULL CHECK (expected_duration_months > 0),
  allocation_method VARCHAR(32) NOT NULL,
  status project_status NOT NULL DEFAULT 'draft',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
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

CREATE TABLE project_updates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES partnership_projects(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES users(id),
  title VARCHAR(180) NOT NULL,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
