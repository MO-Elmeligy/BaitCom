import express from 'express';
import pg from 'pg';

const { Pool } = pg;
const app = express();
const port = Number(process.env.PORT || 3000);
const isProduction = process.env.NODE_ENV === 'production';
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
let devUserId;

app.disable('x-powered-by');
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', process.env.CORS_ORIGIN || '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type,Authorization');
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
});
app.use(express.json({ limit: '1mb' }));

const asyncRoute = (handler) => (req, res, next) =>
  Promise.resolve(handler(req, res, next)).catch(next);

function toProperty(row) {
  return {
    id: row.id,
    title: row.title,
    description: row.description,
    city: row.city,
    district: row.district,
    propertyType: row.property_type,
    priceEgp: Number(row.price_egp),
    areaM2: Number(row.area_m2),
    bedrooms: Number(row.bedrooms || 0),
    status: row.status,
  };
}

function toProject(row) {
  return {
    id: row.id,
    title: row.title,
    description: row.description,
    city: row.city,
    district: row.district,
    targetMembers: Number(row.target_members),
    expectedDurationMonths: Number(row.expected_duration_months),
    totalUnits: Number(row.total_units),
    landPriceEgp: Number(row.land_price_egp),
    estimatedBuildCostEgp: Number(row.build_cost_egp),
    currentMemberCount: Number(row.current_member_count || 0),
    fundingProgress: Number(row.funding_progress || 0),
    status: row.status,
  };
}

function numberField(value, field, { min = 0, integer = false } = {}) {
  const number = Number(value);
  if (!Number.isFinite(number) || number < min || (integer && !Number.isInteger(number))) {
    const error = new Error(`Invalid ${field}`);
    error.status = 400;
    throw error;
  }
  return number;
}

function requireDevelopmentMode() {
  if (isProduction) {
    const error = new Error('Development-only endpoint');
    error.status = 404;
    throw error;
  }
}

async function getDevUser() {
  requireDevelopmentMode();
  const result = await pool.query(
    `INSERT INTO users (phone, display_name, role)
     VALUES ($1, $2, 'seller')
     ON CONFLICT (phone) DO UPDATE SET display_name = EXCLUDED.display_name
     RETURNING id, display_name, role`,
    [process.env.DEV_USER_PHONE || '+200000000001', process.env.DEV_USER_NAME || 'مستخدم تجريبي'],
  );
  devUserId = result.rows[0].id;
  return result.rows[0];
}

function requireOwner(userId) {
  requireDevelopmentMode();
  if (!devUserId || userId !== devUserId) {
    const error = new Error('Start a development session before creating records');
    error.status = 401;
    throw error;
  }
}

app.get('/health', asyncRoute(async (_req, res) => {
  await pool.query('SELECT 1');
  res.json({ status: 'ok', database: 'connected' });
}));

app.get('/api/dev/session', asyncRoute(async (_req, res) => {
  const user = await getDevUser();
  res.json({ data: { userId: user.id, displayName: user.display_name, role: user.role } });
}));

app.get('/api/properties', asyncRoute(async (req, res) => {
  const values = [];
  const clauses = ["status = 'published'"];
  const add = (sql, value) => { values.push(value); clauses.push(sql.replace('?', `$${values.length}`)); };
  if (req.query.city) add('city ILIKE ?', `%${String(req.query.city).trim()}%`);
  if (req.query.district) add('district ILIKE ?', `%${String(req.query.district).trim()}%`);
  if (req.query.type) add('property_type = ?', String(req.query.type));
  if (req.query.maxPrice) add('price_egp <= ?', numberField(req.query.maxPrice, 'maxPrice'));
  if (req.query.q) {
    values.push(`%${String(req.query.q).trim()}%`);
    clauses.push(`(title ILIKE $${values.length} OR description ILIKE $${values.length} OR city ILIKE $${values.length} OR district ILIKE $${values.length})`);
  }
  const result = await pool.query(
    `SELECT id, title, description, city, district, property_type, price_egp, area_m2, bedrooms, status
     FROM properties WHERE ${clauses.join(' AND ')} ORDER BY created_at DESC LIMIT 100`,
    values,
  );
  res.json({ data: result.rows.map(toProperty) });
}));

app.get('/api/partnership-projects', asyncRoute(async (req, res) => {
  const values = [];
  const clauses = ["p.status = 'open'"];
  if (req.query.city) {
    values.push(`%${String(req.query.city).trim()}%`);
    clauses.push(`p.city ILIKE $${values.length}`);
  }
  if (req.query.q) {
    values.push(`%${String(req.query.q).trim()}%`);
    clauses.push(`(p.title ILIKE $${values.length} OR p.description ILIKE $${values.length} OR p.district ILIKE $${values.length})`);
  }
  const result = await pool.query(
    `SELECT p.id, p.title, p.description, p.city, p.district, p.target_members,
            p.expected_duration_months, p.total_units, p.land_price_egp,
            p.build_cost_egp, p.status,
            COUNT(m.id) FILTER (WHERE m.status = 'approved') AS current_member_count,
            0::numeric AS funding_progress
     FROM partnership_projects p
     LEFT JOIN partnership_members m ON m.project_id = p.id
     WHERE ${clauses.join(' AND ')}
     GROUP BY p.id ORDER BY p.created_at DESC LIMIT 100`,
    values,
  );
  res.json({ data: result.rows.map(toProject) });
}));

app.get('/api/dev/my-properties', asyncRoute(async (req, res) => {
  requireOwner(String(req.query.userId || ''));
  const result = await pool.query(
    `SELECT id, title, description, city, district, property_type, price_egp, area_m2, bedrooms, status
     FROM properties WHERE owner_id = $1 ORDER BY created_at DESC LIMIT 100`,
    [devUserId],
  );
  res.json({ data: result.rows.map(toProperty) });
}));

app.get('/api/dev/my-partnership-projects', asyncRoute(async (req, res) => {
  requireOwner(String(req.query.userId || ''));
  const result = await pool.query(
    `SELECT p.id, p.title, p.description, p.city, p.district, p.target_members,
            p.expected_duration_months, p.total_units, p.land_price_egp,
            p.build_cost_egp, p.status,
            COUNT(m.id) FILTER (WHERE m.status = 'approved') AS current_member_count,
            0::numeric AS funding_progress
     FROM partnership_projects p
     LEFT JOIN partnership_members m ON m.project_id = p.id
     WHERE p.manager_id = $1 GROUP BY p.id ORDER BY p.created_at DESC LIMIT 100`,
    [devUserId],
  );
  res.json({ data: result.rows.map(toProject) });
}));

app.post('/api/properties', asyncRoute(async (req, res) => {
  requireOwner(String(req.body.ownerId || ''));
  const { title, description, city, district, propertyType } = req.body;
  if (![title, description, city, district, propertyType].every((value) => typeof value === 'string' && value.trim())) {
    return res.status(400).json({ message: 'Title, description, location, and property type are required.' });
  }
  const result = await pool.query(
    `INSERT INTO properties (owner_id, title, description, property_type, city, district, price_egp, area_m2, bedrooms, status)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'pending_review')
     RETURNING id, title, description, city, district, property_type, price_egp, area_m2, bedrooms, status`,
    [devUserId, title.trim(), description.trim(), propertyType, city.trim(), district.trim(),
      numberField(req.body.priceEgp, 'priceEgp', { min: 0.01 }),
      numberField(req.body.areaM2, 'areaM2', { min: 0.01 }),
      numberField(req.body.bedrooms, 'bedrooms', { integer: true })],
  );
  res.status(201).json({ data: toProperty(result.rows[0]) });
}));

app.post('/api/partnership-projects', asyncRoute(async (req, res) => {
  requireOwner(String(req.body.managerId || ''));
  const { title, description, city, district } = req.body;
  if (![title, description, city, district].every((value) => typeof value === 'string' && value.trim())) {
    return res.status(400).json({ message: 'Title, description, city, and district are required.' });
  }
  const result = await pool.query(
    `INSERT INTO partnership_projects
       (manager_id, title, description, city, district, land_price_egp, build_cost_egp,
        total_units, target_members, expected_duration_months, allocation_method, status)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 'unit_based', 'pending_review')
     RETURNING id, title, description, city, district, target_members, expected_duration_months,
               total_units, land_price_egp, build_cost_egp, status`,
    [devUserId, title.trim(), description.trim(), city.trim(), district.trim(),
      numberField(req.body.landPriceEgp, 'landPriceEgp', { min: 0.01 }),
      numberField(req.body.estimatedBuildCostEgp, 'estimatedBuildCostEgp'),
      numberField(req.body.totalUnits, 'totalUnits', { min: 1, integer: true }),
      numberField(req.body.targetMembers, 'targetMembers', { min: 2, integer: true }),
      numberField(req.body.expectedDurationMonths, 'expectedDurationMonths', { min: 1, integer: true })],
  );
  res.status(201).json({ data: toProject({ ...result.rows[0], current_member_count: 0, funding_progress: 0 }) });
}));

app.use((error, _req, res, _next) => {
  console.error(error);
  res.status(error.status || 500).json({ message: error.status ? error.message : 'Internal server error' });
});

const server = app.listen(port, () => console.log(`Bayt Co API listening on :${port}`));
for (const signal of ['SIGINT', 'SIGTERM']) {
  process.on(signal, () => server.close(async () => { await pool.end(); process.exit(0); }));
}
