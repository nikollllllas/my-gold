// Smoke test: exige Postgres rodando (DATABASE_URL) e servidor em SMOKE_URL (default localhost:3000).
import assert from 'node:assert';
import { eq } from 'drizzle-orm';
import { db, pool } from './db.js';
import { users } from './schema.js';

const BASE = process.env.SMOKE_URL ?? 'http://localhost:3000';
const email = `smoke-${Date.now()}@test.com`;

const j = (r: Response) => r.json() as Promise<any>;

// health
assert.equal((await fetch(`${BASE}/health`)).status, 200);

// register + validações
assert.equal((await fetch(`${BASE}/auth/register`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ email: 'ruim', password: '12345678' }) })).status, 400);
assert.equal((await fetch(`${BASE}/auth/register`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ email, password: 'curta' }) })).status, 400);
const reg = await fetch(`${BASE}/auth/register`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ email, password: 'senha-forte-123' }) });
assert.equal(reg.status, 201);
const { token } = await j(reg);
const auth = { authorization: `Bearer ${token}`, 'content-type': 'application/json' };

// duplicado
assert.equal((await fetch(`${BASE}/auth/register`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ email, password: 'senha-forte-123' }) })).status, 409);

// login errado / certo
assert.equal((await fetch(`${BASE}/auth/login`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ email, password: 'errada12345' }) })).status, 401);
assert.equal((await fetch(`${BASE}/auth/login`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ email, password: 'senha-forte-123' }) })).status, 200);

// me
const me = await j(await fetch(`${BASE}/auth/me`, { headers: auth }));
assert.equal(me.email, email);
assert.equal(me.isPremium, false);

// premium gate fecha para free
assert.equal((await fetch(`${BASE}/alerts`, { headers: auth })).status, 403);

// promove a premium direto no banco e testa CRUD de alertas
await db.update(users).set({ isPremium: true }).where(eq(users.email, email));
const created = await fetch(`${BASE}/alerts`, { method: 'POST', headers: auth, body: JSON.stringify({ targetPrice: 550.5, direction: 'above' }) });
assert.equal(created.status, 201);
const alert = await j(created);
assert.equal((await fetch(`${BASE}/alerts`, { method: 'POST', headers: auth, body: JSON.stringify({ targetPrice: -1, direction: 'above' }) })).status, 400);
assert.equal((await fetch(`${BASE}/alerts`, { method: 'POST', headers: auth, body: JSON.stringify({ targetPrice: 550, direction: 'sideways' }) })).status, 400);
const list = await j(await fetch(`${BASE}/alerts`, { headers: auth }));
assert.equal(list.length, 1);
assert.equal((await fetch(`${BASE}/alerts/${alert.id}`, { method: 'DELETE', headers: auth })).status, 204);
assert.equal((await fetch(`${BASE}/alerts/${alert.id}`, { method: 'DELETE', headers: auth })).status, 404);

// history
assert.equal((await fetch(`${BASE}/history?period=nope`)).status, 400);
const hist = await fetch(`${BASE}/history?period=7d`);
assert.equal(hist.status, 200);
assert.ok(Array.isArray(await j(hist)));

// prices: sem GOLDAPI_KEY → 503 com mensagem
const price = await fetch(`${BASE}/prices/gold`);
assert.ok([200, 503].includes(price.status));
console.log('SMOKE OK');
await pool.end();
