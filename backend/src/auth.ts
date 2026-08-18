import { Router, type Request, type Response, type NextFunction } from 'express';
import { scrypt, randomBytes, timingSafeEqual } from 'node:crypto';
import { promisify } from 'node:util';
import jwt from 'jsonwebtoken';
import { eq } from 'drizzle-orm';
import { db } from './db.js';
import { users } from './schema.js';

const scryptAsync = promisify(scrypt) as (pw: string, salt: string, len: number) => Promise<Buffer>;
const JWT_SECRET = process.env.JWT_SECRET ?? '';
if (!JWT_SECRET) {
  if (process.env.NODE_ENV === 'production') throw new Error('JWT_SECRET é obrigatório em produção');
  console.warn('[auth] JWT_SECRET ausente — usando segredo de dev inseguro');
}
const SECRET = JWT_SECRET || 'dev-secret-change-me';

async function hashPassword(pw: string): Promise<string> {
  const salt = randomBytes(16).toString('hex');
  const hash = await scryptAsync(pw, salt, 64);
  return `${salt}:${hash.toString('hex')}`;
}

async function verifyPassword(pw: string, stored: string): Promise<boolean> {
  const [salt, hash] = stored.split(':');
  const candidate = await scryptAsync(pw, salt, 64);
  return timingSafeEqual(candidate, Buffer.from(hash, 'hex'));
}

export interface AuthedRequest extends Request {
  userId?: number;
  isPremium?: boolean;
}

export async function requireAuth(req: AuthedRequest, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.replace(/^Bearer /, '');
  if (!token) return res.status(401).json({ error: 'Token ausente' });
  try {
    const payload = jwt.verify(token, SECRET) as { sub: string };
    const [user] = await db.select().from(users).where(eq(users.id, Number(payload.sub)));
    if (!user) return res.status(401).json({ error: 'Usuário não encontrado' });
    req.userId = user.id;
    req.isPremium = user.isPremium;
    next();
  } catch {
    return res.status(401).json({ error: 'Token inválido ou expirado' });
  }
}

export function requirePremium(req: AuthedRequest, res: Response, next: NextFunction) {
  if (!req.isPremium) return res.status(403).json({ error: 'Recurso exclusivo para assinantes premium' });
  next();
}

export const authRouter = Router();

authRouter.post('/register', async (req, res) => {
  const { email, password } = req.body ?? {};
  if (typeof email !== 'string' || !/^\S+@\S+\.\S+$/.test(email))
    return res.status(400).json({ error: 'E-mail inválido' });
  if (typeof password !== 'string' || password.length < 8)
    return res.status(400).json({ error: 'Senha deve ter no mínimo 8 caracteres' });

  const [existing] = await db.select().from(users).where(eq(users.email, email.toLowerCase()));
  if (existing) return res.status(409).json({ error: 'E-mail já cadastrado' });

  const [user] = await db
    .insert(users)
    .values({ email: email.toLowerCase(), passwordHash: await hashPassword(password) })
    .returning();
  const token = jwt.sign({ sub: String(user.id) }, SECRET, { expiresIn: '30d' });
  res.status(201).json({ token });
});

authRouter.post('/login', async (req, res) => {
  const { email, password } = req.body ?? {};
  if (typeof email !== 'string' || typeof password !== 'string')
    return res.status(400).json({ error: 'E-mail e senha são obrigatórios' });

  const [user] = await db.select().from(users).where(eq(users.email, email.toLowerCase()));
  if (!user || !(await verifyPassword(password, user.passwordHash)))
    return res.status(401).json({ error: 'E-mail ou senha incorretos' });

  const token = jwt.sign({ sub: String(user.id) }, SECRET, { expiresIn: '30d' });
  res.json({ token });
});

authRouter.get('/me', requireAuth, async (req: AuthedRequest, res) => {
  const [user] = await db.select().from(users).where(eq(users.id, req.userId!));
  res.json({
    id: user.id,
    email: user.email,
    isPremium: user.isPremium,
    createdAt: user.createdAt,
  });
});
