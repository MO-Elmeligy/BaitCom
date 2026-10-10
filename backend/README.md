# بيت كو API

## Local setup

1. Install PostgreSQL with PostGIS and create a database named `bayt_co`.
2. Apply the schema from the project root: `psql -d bayt_co -f backend/schema.sql`.
3. Copy `.env.example` to `.env` and update `DATABASE_URL`.
4. Run `npm install`, then `npm start` from this folder.
5. Check `GET http://localhost:3000/health`.

For the easiest local setup, install Docker Desktop and run `docker compose up --build` from the project root. Compose starts PostGIS, initializes an empty database from `schema.sql`, and starts the API. Its default credentials and development-only routes must not be used for production. The schema initialization script runs only when the database volume is first created; after a schema change, use a migration or recreate the local volume only if its data can be discarded.

For the Android emulator, run Flutter with `--dart-define=API_BASE_URL=http://10.0.2.2:3000`.

## Routes

- `GET /api/me`, `GET /api/me/properties`, and `GET /api/me/partnership-projects`: authenticated account routes requiring a Firebase ID token.

- `GET /api/properties`: published feed with optional `q`, `city`, `district`, `type`, and `maxPrice` filters.
- `POST /api/properties`: create a property in `pending_review` state.
- `POST /api/media/signature`: authenticated Cloudinary upload signature for a property image or video. The API secret remains on the server.
- `GET /api/partnership-projects`: open project feed with optional `q` and `city` filters.
- `POST /api/partnership-projects`: create a project in `pending_review` state.
- POST /api/partnership-projects/:id/join: authenticated transactional join request with seat and optional unit locking; no money is collected.
- `GET /api/dev/session`, `/api/dev/my-properties`, and `/api/dev/my-partnership-projects`: development-only demo session and records.

The development endpoints are disabled when `NODE_ENV=production`. The API verifies Firebase ID tokens for account and write routes. The API applies per-process IP limits of 120 GET requests and 20 other API requests per minute, with 429 responses and rate-limit headers. Set TRUST_PROXY_HOPS to the exact number of trusted reverse-proxy hops when deployed behind a proxy; leave it at 0 for direct connections. These limits are local to one Node process and are defense in depth; production deployments with multiple replicas must also configure shared throttling at the gateway or WAF. Production still needs HTTPS termination, reviewed CORS origins, monitoring, and operational database backups. It does not move money.

## Property photos and videos

Create a Cloudinary account and configure `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, and `CLOUDINARY_API_SECRET` on the API service (for local Compose, put them in the project-root `.env`). Never add the API secret to Flutter or commit it. Signed uploads require a Firebase-authenticated user. The app accepts up to 10 files per listing, with a 25 MB per-file limit; uploaded URLs and media types are saved transactionally in `property_media`. Cloudinary plan quotas and terms apply.


## Firebase phone authentication

Set `FIREBASE_PROJECT_ID` (or `GOOGLE_CLOUD_PROJECT`) and provide Google Application Default Credentials to the server using the hosting provider's workload identity or an equivalent managed service account. Do not commit service-account JSON keys. Production startup fails if the Firebase project ID or an explicit web CORS_ORIGIN is missing. Authenticated clients send their Firebase ID token as Authorization: Bearer <token>; the API verifies it and uses the verified Firebase UID and phone number, never a client-supplied owner ID. Apply the updated schema to existing databases before deploying.

## Administration and moderation

Grant trusted administrators the Firebase custom claim admin=true using a privileged Firebase Admin SDK environment. Never expose an endpoint that grants this claim to ordinary app users. GET /api/admin/review-queue lists pending properties, projects, and join requests. PATCH /api/admin/properties/:id/review and PATCH /api/admin/partnership-projects/:id/review and PATCH /api/admin/join-requests/:id/review accept decision=approve or reject; rejection requires a reason. Updates and audit records are committed in one database transaction. Apply the new audit table and rejected project status migration to existing databases before enabling these endpoints.
For an existing database, apply these additive migration statements manually before deploying; do not rerun the bootstrap schema against a database that already has the schema:

ALTER TYPE project_status ADD VALUE IF NOT EXISTS 'rejected';
ALTER TABLE users ADD COLUMN IF NOT EXISTS firebase_uid VARCHAR(128);
CREATE UNIQUE INDEX IF NOT EXISTS users_firebase_uid_idx ON users(firebase_uid) WHERE firebase_uid IS NOT NULL;
ALTER TABLE partnership_projects ADD COLUMN IF NOT EXISTS minimum_contribution_egp NUMERIC(14,2);
UPDATE partnership_projects SET minimum_contribution_egp = GREATEST(1, CEIL((land_price_egp + build_cost_egp + additional_costs_egp) / target_members)) WHERE minimum_contribution_egp IS NULL;
ALTER TABLE partnership_projects ALTER COLUMN minimum_contribution_egp SET NOT NULL;
ALTER TABLE partnership_projects ADD CONSTRAINT partnership_projects_minimum_contribution_check CHECK (minimum_contribution_egp > 0);
CREATE TABLE IF NOT EXISTS property_media (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE, media_url TEXT NOT NULL, media_type VARCHAR(16) NOT NULL DEFAULT 'image', sort_order SMALLINT NOT NULL DEFAULT 0);
CREATE INDEX IF NOT EXISTS property_media_property_sort_idx ON property_media(property_id, sort_order);
CREATE TABLE admin_audit_log (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), admin_user_id UUID NOT NULL REFERENCES users(id), target_type VARCHAR(32) NOT NULL, target_id UUID NOT NULL, decision VARCHAR(16) NOT NULL CHECK (decision IN ('approve', 'reject')), reason TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE INDEX admin_audit_log_target_idx ON admin_audit_log(target_type, target_id, created_at);
