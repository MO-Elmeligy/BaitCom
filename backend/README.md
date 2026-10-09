# بيت كو API

## Local setup

1. Prepare PostgreSQL with PostGIS and create a database named `bayt_co`.
2. Apply the schema from the project root: `psql -d bayt_co -f backend/schema.sql`.
3. Copy `.env.example` to `.env` and update `DATABASE_URL`.
4. Run `npm install`, then `npm start` from this folder.
5. Check `GET http://localhost:3000/health`.

For the Android emulator, run Flutter with `--dart-define=API_BASE_URL=http://10.0.2.2:3000`.

## Routes

- `GET /api/properties`: published feed with optional `q`, `city`, `district`, `type`, and `maxPrice` filters.
- `POST /api/properties`: create a property in `pending_review` state.
- `GET /api/partnership-projects`: open project feed with optional `q` and `city` filters.
- `POST /api/partnership-projects`: create a project in `pending_review` state.
- `GET /api/dev/session`, `/api/dev/my-properties`, and `/api/dev/my-partnership-projects`: development-only demo session and records.

The development endpoints are disabled when `NODE_ENV=production`. The API is an MVP scaffold: production use still needs real authentication, authorization, rate limits, secure HTTPS, reviewed CORS origins, and operational database backups. It does not move money.
