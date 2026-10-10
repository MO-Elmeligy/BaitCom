import express from 'express';
import pg from 'pg';
import { createHash, randomUUID } from 'node:crypto';
import { applicationDefault, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

const { Pool } = pg;
const app = express();
const port = Number(process.env.PORT || 3000);
const isProduction = process.env.NODE_ENV === 'production';
const corsOrigin = process.env.CORS_ORIGIN;
if (isProduction && (!corsOrigin || corsOrigin === '*')) {
  throw new Error('Production requires CORS_ORIGIN to be set to the deployed web app origin.');
}
const firebaseProjectId = process.env.FIREBASE_PROJECT_ID || process.env.GOOGLE_CLOUD_PROJECT;
if (isProduction && !firebaseProjectId) {
  throw new Error('Production requires FIREBASE_PROJECT_ID or GOOGLE_CLOUD_PROJECT.');
}
if (firebaseProjectId && getApps().length === 0) {
  initializeApp({ credential: applicationDefault(), projectId: firebaseProjectId });
}
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const propertyMediaSelect = `COALESCE(
  (SELECT json_agg(json_build_object('url', pm.media_url, 'type', pm.media_type) ORDER BY pm.sort_order)
   FROM property_media pm WHERE pm.property_id = properties.id),
  '[]'::json
) AS media`;
let devUserId;

app.disable('x-powered-by');

const trustedProxyHops = process.env.TRUST_PROXY_HOPS
  ? Number(process.env.TRUST_PROXY_HOPS)
  : 0;
if (!Number.isInteger(trustedProxyHops) || trustedProxyHops < 0 || trustedProxyHops > 5) {
  throw new Error('TRUST_PROXY_HOPS must be an integer from 0 to 5.');
}
app.set('trust proxy', trustedProxyHops);

const rateLimitWindowMs = 60_000;
const rateLimitBuckets = new Map();
const rateLimitLimits = { read: 120, write: 20 };
const rateLimitCleanup = setInterval(() => {
  const cutoff = Date.now() - rateLimitWindowMs;
  for (const [key, bucket] of rateLimitBuckets) {
    if (bucket.startedAt <= cutoff) rateLimitBuckets.delete(key);
  }
}, rateLimitWindowMs);
rateLimitCleanup.unref();

function apiRateLimit(req, res, next) {
  if (!req.path.startsWith('/api/')) return next();

  const category = req.method === 'GET' ? 'read' : 'write';
  const limit = rateLimitLimits[category];
  const key = req.ip + ':' + category;
  const now = Date.now();
  let bucket = rateLimitBuckets.get(key);

  if (!bucket || now - bucket.startedAt >= rateLimitWindowMs) {
    if (rateLimitBuckets.size >= 50_000) {
      const cutoff = now - rateLimitWindowMs;
      for (const [existingKey, existingBucket] of rateLimitBuckets) {
        if (existingBucket.startedAt <= cutoff) rateLimitBuckets.delete(existingKey);
      }
    }
    if (rateLimitBuckets.size >= 50_000 && !bucket) {
      return res.status(503).json({ message: 'Request limiting is temporarily unavailable.' });
    }
    bucket = { startedAt: now, count: 0 };
  }

  bucket.count += 1;
  rateLimitBuckets.set(key, bucket);
  const remaining = Math.max(0, limit - bucket.count);
  const resetSeconds = Math.ceil((bucket.startedAt + rateLimitWindowMs - now) / 1000);
  res.setHeader('RateLimit-Limit', String(limit));
  res.setHeader('RateLimit-Remaining', String(remaining));
  res.setHeader('RateLimit-Reset', String(Math.max(0, resetSeconds)));
  if (bucket.count > limit) {
    res.setHeader('Retry-After', String(Math.max(1, resetSeconds)));
    return res.status(429).json({ message: 'Too many requests. Please try again shortly.' });
  }
  next();
}
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', corsOrigin || '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PATCH,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type,Authorization');
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
});
app.use(apiRateLimit);
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
    media: Array.isArray(row.media) ? row.media : [],
  };
}

function validatePropertyMedia(value) {
  if (value === undefined) return [];
  if (!Array.isArray(value) || value.length > 10) {
    const error = new Error('A property can have at most 10 media files.');
    error.status = 400;
    throw error;
  }

  const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
  return value.map((item, index) => {
    if (!item || !['image', 'video'].includes(item.type) || typeof item.url !== 'string') {
      const error = new Error(`Invalid property media item at position ${index + 1}.`);
      error.status = 400;
      throw error;
    }
    let url;
    try {
      url = new URL(item.url);
    } catch {
      const error = new Error(`Invalid property media URL at position ${index + 1}.`);
      error.status = 400;
      throw error;
    }
    const path = url.pathname.split('/');
    if (
      !cloudName ||
      url.protocol !== 'https:' ||
      url.hostname !== 'res.cloudinary.com' ||
      path[1] !== cloudName ||
      path[2] !== item.type ||
      path[3] !== 'upload'
    ) {
      const error = new Error('Property media must be uploaded to the configured Cloudinary account.');
      error.status = 400;
      throw error;
    }
    return { url: url.toString(), type: item.type };
  });
}

function toProject(row) {
  return {
    id: row.id,
    title: row.title,
    description: row.description,
    city: row.city,
    district: row.district,
    targetMembers: Number(row.target_members),
    minimumContributionEgp: Number(row.minimum_contribution_egp),
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

async function authenticateFirebase(req) {
  const authorization = req.get('authorization') || '';
  const match = authorization.match(/^Bearer\s+(.+)$/i);
  if (!match || getApps().length === 0) {
    const error = new Error('Authentication required');
    error.status = 401;
    throw error;
  }
  try {
    const decoded = await getAuth().verifyIdToken(match[1], true);
    if (!decoded.uid || !decoded.phone_number) {
      const error = new Error('A verified phone number is required');
      error.status = 403;
      throw error;
    }
    return decoded;
  } catch (cause) {
    if (cause.status) throw cause;
    const error = new Error('Invalid or expired Firebase ID token');
    error.status = 401;
    throw error;
  }
}

async function getDatabaseUser(decoded) {
  const phone = decoded.phone_number;
  const displayName = String(decoded.name || phone).slice(0, 120);
  const result = await pool.query(
    `INSERT INTO users (firebase_uid, phone, display_name, verified_at)
     VALUES ($1, $2, $3, now())
     ON CONFLICT (phone) DO UPDATE
       SET firebase_uid = COALESCE(users.firebase_uid, EXCLUDED.firebase_uid),
           display_name = EXCLUDED.display_name,
           verified_at = COALESCE(users.verified_at, now())
       WHERE users.firebase_uid IS NULL OR users.firebase_uid = EXCLUDED.firebase_uid
     RETURNING id, firebase_uid, phone, display_name, role`,
    [decoded.uid, phone, displayName],
  );
  if (result.rowCount === 0) {
    const error = new Error('This phone number is linked to another account');
    error.status = 409;
    throw error;
  }
  return result.rows[0];
}

async function currentUser(req) {
  return getDatabaseUser(await authenticateFirebase(req));
}
async function requireAdmin(req) {
  const decoded = await authenticateFirebase(req);
  if (decoded.admin !== true) {
    const error = new Error('Administrator access required');
    error.status = 403;
    throw error;
  }
  return getDatabaseUser(decoded);
}

async function requireOwner(req, developmentUserId) {
  if (!isProduction && developmentUserId) {
    requireDevelopmentMode();
    if (developmentUserId !== devUserId) {
      const error = new Error('Start a development session before creating records');
      error.status = 401;
      throw error;
    }
    return devUserId;
  }
  return (await currentUser(req)).id;
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


app.get('/health', asyncRoute(async (_req, res) => {
  await pool.query('SELECT 1');
  res.json({ status: 'ok', database: 'connected' });
}));

app.get('/api/dev/session', asyncRoute(async (_req, res) => {
  const user = await getDevUser();
  res.json({ data: { userId: user.id, displayName: user.display_name, role: user.role } });
}));

app.post('/api/media/signature', asyncRoute(async (req, res) => {
  await currentUser(req);
  const { CLOUDINARY_CLOUD_NAME: cloudName, CLOUDINARY_API_KEY: apiKey, CLOUDINARY_API_SECRET: apiSecret } = process.env;
  if (!cloudName || !apiKey || !apiSecret) {
    const error = new Error('Cloudinary media uploads are not configured on the API.');
    error.status = 503;
    throw error;
  }

  const resourceType = req.body.resourceType;
  if (!['image', 'video'].includes(resourceType)) {
    return res.status(400).json({ message: 'Resource type must be image or video.' });
  }

  const timestamp = Math.floor(Date.now() / 1000);
  const folder = 'baitco/properties';
  const publicId = `property_media_${randomUUID()}`;
  const params = { folder, public_id: publicId, timestamp };
  const signaturePayload = Object.keys(params)
    .sort()
    .map((key) => `${key}=${params[key]}`)
    .join('&');
  const signature = createHash('sha1')
    .update(signaturePayload + apiSecret)
    .digest('hex');

  res.json({
    data: {
      cloudName,
      apiKey,
      folder,
      publicId,
      timestamp,
      signature,
    },
  });
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
    `SELECT id, title, description, city, district, property_type, price_egp, area_m2, bedrooms, status,
            ${propertyMediaSelect}
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
    `SELECT p.id, p.title, p.description, p.city, p.district, p.target_members, p.minimum_contribution_egp,
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
  const userId = await requireOwner(req, String(req.query.userId || ''));
  const result = await pool.query(
    `SELECT id, title, description, city, district, property_type, price_egp, area_m2, bedrooms, status,
            ${propertyMediaSelect}
     FROM properties WHERE owner_id = $1 ORDER BY created_at DESC LIMIT 100`,
    [userId],
  );
  res.json({ data: result.rows.map(toProperty) });
}));

app.get('/api/dev/my-partnership-projects', asyncRoute(async (req, res) => {
  const userId = await requireOwner(req, String(req.query.userId || ''));
  const result = await pool.query(
    `SELECT p.id, p.title, p.description, p.city, p.district, p.target_members, p.minimum_contribution_egp,
            p.expected_duration_months, p.total_units, p.land_price_egp,
            p.build_cost_egp, p.status,
            COUNT(m.id) FILTER (WHERE m.status = 'approved') AS current_member_count,
            0::numeric AS funding_progress
     FROM partnership_projects p
     LEFT JOIN partnership_members m ON m.project_id = p.id
     WHERE p.manager_id = $1 GROUP BY p.id ORDER BY p.created_at DESC LIMIT 100`,
    [userId],
  );
  res.json({ data: result.rows.map(toProject) });
}));

app.get('/api/me', asyncRoute(async (req, res) => {
  const user = await currentUser(req);
  res.json({ data: { id: user.id, phone: user.phone, displayName: user.display_name, role: user.role } });
}));

app.get('/api/me/properties', asyncRoute(async (req, res) => {
  const user = await currentUser(req);
  const result = await pool.query(
    `SELECT id, title, description, city, district, property_type, price_egp, area_m2, bedrooms, status,
            ${propertyMediaSelect}
     FROM properties WHERE owner_id = $1 ORDER BY created_at DESC LIMIT 100`,
    [user.id],
  );
  res.json({ data: result.rows.map(toProperty) });
}));

app.get('/api/me/partnership-projects', asyncRoute(async (req, res) => {
  const user = await currentUser(req);
  const result = await pool.query(
    `SELECT p.id, p.title, p.description, p.city, p.district, p.target_members, p.minimum_contribution_egp,
            p.expected_duration_months, p.total_units, p.land_price_egp,
            p.build_cost_egp, p.status,
            COUNT(m.id) FILTER (WHERE m.status = 'approved') AS current_member_count,
            0::numeric AS funding_progress
     FROM partnership_projects p
     LEFT JOIN partnership_members m ON m.project_id = p.id
     WHERE p.manager_id = $1 GROUP BY p.id ORDER BY p.created_at DESC LIMIT 100`,
    [user.id],
  );
  res.json({ data: result.rows.map(toProject) });
}));

app.post('/api/partnership-projects/:id/join', asyncRoute(async (req, res) => {
  const user = await currentUser(req);
  const requestedContributionEgp = numberField(
    req.body.requestedContributionEgp,
    'requestedContributionEgp',
    { min: 0.01 },
  );
  const unitId = req.body.unitId ? String(req.body.unitId) : null;
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const projectResult = await client.query(
      'SELECT id, status, target_members, minimum_contribution_egp FROM partnership_projects WHERE id = $1 FOR UPDATE',
      [req.params.id],
    );
    if (projectResult.rowCount === 0) {
      const error = new Error('Partnership project not found');
      error.status = 404;
      throw error;
    }
    const project = projectResult.rows[0];
    if (project.status !== 'open') {
      const error = new Error('This project is not accepting join requests');
      error.status = 409;
      throw error;
    }
    if (requestedContributionEgp < Number(project.minimum_contribution_egp)) {
      const error = new Error('Contribution is below this project minimum');
      error.status = 400;
      throw error;
    }
    if (unitId) {
      const unitResult = await client.query(
        'SELECT id FROM partnership_units WHERE id = $1 AND project_id = $2 FOR UPDATE',
        [unitId, project.id],
      );
      if (unitResult.rowCount === 0) {
        const error = new Error('The selected unit does not belong to this project');
        error.status = 400;
        throw error;
      }
      const reservedUnit = await client.query(
        "SELECT 1 FROM partnership_members WHERE unit_id = $1 AND status IN ('pending', 'approved') LIMIT 1",
        [unitId],
      );
      if (reservedUnit.rowCount > 0) {
        const error = new Error('The selected unit already has a join request');
        error.status = 409;
        throw error;
      }
    }
    const memberCount = await client.query(
      "SELECT COUNT(*)::int AS count FROM partnership_members WHERE project_id = $1 AND status IN ('pending', 'approved')",
      [project.id],
    );
    if (memberCount.rows[0].count >= project.target_members) {
      const error = new Error('This project has no remaining places');
      error.status = 409;
      throw error;
    }
    const result = await client.query(
      "INSERT INTO partnership_members (project_id, user_id, unit_id, requested_contribution_egp, status) " +
      "VALUES ($1, $2, $3, $4, 'pending') " +
      "RETURNING id, project_id, unit_id, requested_contribution_egp, status, requested_at",
      [project.id, user.id, unitId, requestedContributionEgp],
    );
    await client.query('COMMIT');
    res.status(201).json({ data: result.rows[0] });
  } catch (error) {
    await client.query('ROLLBACK');
    if (error.code === '23505') {
      error.status = 409;
      error.message = 'You have already requested to join this project';
    }
    throw error;
  } finally {
    client.release();
  }
}));

app.post('/api/properties', asyncRoute(async (req, res) => {
  const ownerId = await requireOwner(req, String(req.body.ownerId || ''));
  const media = validatePropertyMedia(req.body.media);
  const { title, description, city, district, propertyType } = req.body;
  if (![title, description, city, district, propertyType].every((value) => typeof value === 'string' && value.trim())) {
    return res.status(400).json({ message: 'Title, description, location, and property type are required.' });
  }
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await client.query(
      `INSERT INTO properties (owner_id, title, description, property_type, city, district, price_egp, area_m2, bedrooms, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'pending_review')
       RETURNING id, title, description, city, district, property_type, price_egp, area_m2, bedrooms, status`,
      [ownerId, title.trim(), description.trim(), propertyType, city.trim(), district.trim(),
        numberField(req.body.priceEgp, 'priceEgp', { min: 0.01 }),
        numberField(req.body.areaM2, 'areaM2', { min: 0.01 }),
        numberField(req.body.bedrooms, 'bedrooms', { integer: true })],
    );
    const property = result.rows[0];
    for (const [index, item] of media.entries()) {
      await client.query(
        'INSERT INTO property_media (property_id, media_url, media_type, sort_order) VALUES ($1, $2, $3, $4)',
        [property.id, item.url, item.type, index],
      );
    }
    await client.query('COMMIT');
    res.status(201).json({
      data: toProperty({ ...property, media }),
    });
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}));

app.post('/api/partnership-projects', asyncRoute(async (req, res) => {
  const managerId = await requireOwner(req, String(req.body.managerId || ''));
  const { title, description, city, district } = req.body;
  if (![title, description, city, district].every((value) => typeof value === 'string' && value.trim())) {
    return res.status(400).json({ message: 'Title, description, city, and district are required.' });
  }
  const result = await pool.query(
    `INSERT INTO partnership_projects
       (manager_id, title, description, city, district, land_price_egp, build_cost_egp,
        minimum_contribution_egp, total_units, target_members, expected_duration_months, allocation_method, status)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'unit_based', 'pending_review')
     RETURNING id, title, description, city, district, target_members, minimum_contribution_egp, expected_duration_months,
               total_units, land_price_egp, build_cost_egp, status`,
    [managerId, title.trim(), description.trim(), city.trim(), district.trim(),
      numberField(req.body.landPriceEgp, 'landPriceEgp', { min: 0.01 }),
      numberField(req.body.estimatedBuildCostEgp, 'estimatedBuildCostEgp'),
      numberField(req.body.minimumContributionEgp, 'minimumContributionEgp', { min: 0.01 }),
      numberField(req.body.totalUnits, 'totalUnits', { min: 1, integer: true }),
      numberField(req.body.targetMembers, 'targetMembers', { min: 2, integer: true }),
      numberField(req.body.expectedDurationMonths, 'expectedDurationMonths', { min: 1, integer: true })],
  );
  res.status(201).json({ data: toProject({ ...result.rows[0], current_member_count: 0, funding_progress: 0 }) });
}));

app.get('/api/admin/review-queue', asyncRoute(async (req, res) => {
  await requireAdmin(req);
  const [properties, projects] = await Promise.all([
    pool.query(
      `SELECT id, title, city, district, property_type, price_egp, created_at
       FROM properties WHERE status = 'pending_review' ORDER BY created_at ASC LIMIT 100`,
    ),
    pool.query(
      `SELECT id, title, city, district, land_price_egp, minimum_contribution_egp, created_at
       FROM partnership_projects WHERE status = 'pending_review' ORDER BY created_at ASC LIMIT 100`,
    ),
  ]);
  const joinRequests = await pool.query(
    `SELECT pm.id, pm.project_id, p.title AS project_title, p.city, p.district,
            pm.user_id, u.phone, pu.unit_label, pm.requested_contribution_egp, pm.requested_at
     FROM partnership_members pm
     JOIN partnership_projects p ON p.id = pm.project_id
     JOIN users u ON u.id = pm.user_id
     LEFT JOIN partnership_units pu ON pu.id = pm.unit_id
     WHERE pm.status = 'pending' ORDER BY pm.requested_at ASC LIMIT 100`,
  );
  res.json({ data: { properties: properties.rows, projects: projects.rows, joinRequests: joinRequests.rows } });
}));

function reviewPendingContent(table, targetType, approvedStatus) {
  return asyncRoute(async (req, res) => {
    const admin = await requireAdmin(req);
    const decision = req.body.decision;
    if (!['approve', 'reject'].includes(decision)) {
      return res.status(400).json({ message: 'Decision must be approve or reject.' });
    }
    const reason = String(req.body.reason || '').trim();
    if (decision === 'reject' && !reason) {
      return res.status(400).json({ message: 'A reason is required when rejecting content.' });
    }
    const status = decision === 'approve' ? approvedStatus : 'rejected';
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const result = await client.query(
        'UPDATE ' + table + ' SET status = $1 WHERE id = $2 AND status = $3 RETURNING id',
        [status, req.params.id, 'pending_review'],
      );
      if (result.rowCount === 0) {
        const error = new Error('Pending content was not found or was already reviewed');
        error.status = 409;
        throw error;
      }
      await client.query(
        `INSERT INTO admin_audit_log (admin_user_id, target_type, target_id, decision, reason)
         VALUES ($1, $2, $3, $4, $5)`,
        [admin.id, targetType, req.params.id, decision, reason || null],
      );
      await client.query('COMMIT');
      res.json({ data: { id: req.params.id, status } });
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  });
}

app.patch('/api/admin/properties/:id/review', reviewPendingContent('properties', 'property', 'published'));
app.patch('/api/admin/partnership-projects/:id/review', reviewPendingContent('partnership_projects', 'partnership_project', 'open'));

app.patch('/api/admin/join-requests/:id/review', asyncRoute(async (req, res) => {
  const admin = await requireAdmin(req);
  const decision = req.body.decision;
  if (!['approve', 'reject'].includes(decision)) {
    return res.status(400).json({ message: 'Decision must be approve or reject.' });
  }
  const reason = String(req.body.reason || '').trim();
  if (decision === 'reject' && !reason) {
    return res.status(400).json({ message: 'A reason is required when rejecting a join request.' });
  }
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const request = await client.query(
      `SELECT pm.id, pm.project_id, pm.status, p.status AS project_status, p.target_members
       FROM partnership_members pm
       JOIN partnership_projects p ON p.id = pm.project_id
       WHERE pm.id = $1 FOR UPDATE OF pm, p`,
      [req.params.id],
    );
    if (request.rowCount === 0 || request.rows[0].status !== 'pending') {
      const error = new Error('Pending join request was not found or was already reviewed');
      error.status = 409;
      throw error;
    }
    const row = request.rows[0];
    if (decision === 'approve' && row.project_status !== 'open') {
      const error = new Error('The project is not open');
      error.status = 409;
      throw error;
    }
    const status = decision === 'approve' ? 'approved' : 'declined';
    await client.query('UPDATE partnership_members SET status = $1 WHERE id = $2', [status, req.params.id]);
    await client.query(
      `INSERT INTO admin_audit_log (admin_user_id, target_type, target_id, decision, reason)
       VALUES ($1, $2, $3, $4, $5)`,
      [admin.id, 'partnership_join_request', req.params.id, decision, reason || null],
    );
    await client.query('COMMIT');
    res.json({ data: { id: req.params.id, status } });
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}));

app.use((error, _req, res, _next) => {
  console.error(error);
  res.status(error.status || 500).json({ message: error.status ? error.message : 'Internal server error' });
});

const server = app.listen(port, () => console.log(`BaitCo API listening on :${port}`));
for (const signal of ['SIGINT', 'SIGTERM']) {
  process.on(signal, () => server.close(async () => { await pool.end(); process.exit(0); }));
}
