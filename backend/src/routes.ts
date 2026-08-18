import { Router } from 'express';
import { eq, and } from 'drizzle-orm';
import Stripe from 'stripe';
import { db } from './db.js';
import { alerts, users, subscriptions } from './schema.js';
import { getGoldPrice, getHistoricalGram } from './gold.js';
import { requireAuth, requirePremium, type AuthedRequest } from './auth.js';

export const router = Router();

router.get('/prices/gold', async (_req, res) => {
  try {
    res.json(await getGoldPrice());
  } catch {
    res.status(503).json({ error: 'Preço indisponível no momento, tente novamente em instantes' });
  }
});

const PERIODS: Record<string, number> = { '1d': 1, '7d': 7, '30d': 30, '120d': 120, '1y': 365 };

router.get('/history', async (req, res) => {
  const period = String(req.query.period ?? '7d');
  const days = PERIODS[period];
  if (!days) return res.status(400).json({ error: 'Período inválido. Use 1d, 7d, 30d, 120d ou 1y' });

  // Histórico vem direto da GoldAPI (1 request por data útil, cacheado p/ sempre).
  // ponytail: plano free tem ~100 requests/mês — 120d/1y só preenchem parcialmente até a quota voltar.
  const dates: string[] = [];
  for (let i = days; i >= 1; i--) {
    const d = new Date(Date.now() - i * 86_400_000);
    const dow = d.getUTCDay();
    if (dow === 0 || dow === 6) continue; // LBMA fecha no fim de semana
    dates.push(d.toISOString().slice(0, 10).replace(/-/g, ''));
  }

  const out: { priceBrl: number; recordedAt: string }[] = [];
  for (let i = 0; i < dates.length; i += 5) {
    const batch = dates.slice(i, i + 5);
    const prices = await Promise.all(batch.map(getHistoricalGram));
    batch.forEach((ds, j) => {
      const p = prices[j];
      if (p != null)
        out.push({
          priceBrl: p,
          recordedAt: `${ds.slice(0, 4)}-${ds.slice(4, 6)}-${ds.slice(6)}T12:00:00.000Z`,
        });
    });
  }

  // Fecha a série com o preço atual
  try {
    const cur = await getGoldPrice();
    out.push({ priceBrl: cur.priceBrl, recordedAt: cur.fetchedAt });
  } catch { /* série segue sem o ponto de hoje */ }

  res.json(out);
});

router.post('/alerts', requireAuth, requirePremium, async (req: AuthedRequest, res) => {
  const { targetPrice, direction } = req.body ?? {};
  const price = Number(targetPrice);
  if (!Number.isFinite(price) || price <= 0)
    return res.status(400).json({ error: 'Preço alvo inválido' });
  if (direction !== 'above' && direction !== 'below')
    return res.status(400).json({ error: "Direção deve ser 'above' ou 'below'" });

  const [alert] = await db
    .insert(alerts)
    .values({ userId: req.userId!, targetPrice: price.toFixed(2), direction })
    .returning();
  res.status(201).json(alert);
});

router.get('/alerts', requireAuth, requirePremium, async (req: AuthedRequest, res) => {
  res.json(await db.select().from(alerts).where(eq(alerts.userId, req.userId!)));
});

router.delete('/alerts/:id', requireAuth, requirePremium, async (req: AuthedRequest, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id)) return res.status(400).json({ error: 'ID inválido' });
  const deleted = await db
    .delete(alerts)
    .where(and(eq(alerts.id, id), eq(alerts.userId, req.userId!)))
    .returning();
  if (!deleted.length) return res.status(404).json({ error: 'Alerta não encontrado' });
  res.status(204).end();
});

router.patch('/account/fcm-token', requireAuth, async (req: AuthedRequest, res) => {
  const token = req.body?.fcmToken;
  if (typeof token !== 'string' || !token) return res.status(400).json({ error: 'Token FCM inválido' });
  await db.update(users).set({ fcmToken: token }).where(eq(users.id, req.userId!));
  res.status(204).end();
});

// --- Stripe ---
const stripe = process.env.STRIPE_SECRET_KEY ? new Stripe(process.env.STRIPE_SECRET_KEY) : null;

router.post('/subscriptions/checkout', requireAuth, async (req: AuthedRequest, res) => {
  if (!stripe) return res.status(503).json({ error: 'Pagamentos não configurados' });
  const plan = req.body?.plan === 'annual' ? process.env.STRIPE_PRICE_ANNUAL : process.env.STRIPE_PRICE_MONTHLY;
  if (!plan) return res.status(503).json({ error: 'Plano não configurado' });

  const [user] = await db.select().from(users).where(eq(users.id, req.userId!));
  let customerId = user.stripeCustomerId;
  if (!customerId) {
    const customer = await stripe.customers.create({ email: user.email, metadata: { userId: String(user.id) } });
    customerId = customer.id;
    await db.update(users).set({ stripeCustomerId: customerId }).where(eq(users.id, user.id));
  }

  // Stripe exige URLs http(s); app detecta o retorno via refresh no resume
  const base = process.env.PUBLIC_URL ?? 'http://localhost:3000';
  const session = await stripe.checkout.sessions.create({
    customer: customerId,
    mode: 'subscription',
    line_items: [{ price: plan, quantity: 1 }],
    success_url: `${base}/checkout/done`,
    cancel_url: `${base}/checkout/cancel`,
  });
  res.json({ url: session.url });
});

router.get('/checkout/done', (_req, res) =>
  res.send('<h2>Pagamento concluído ✅</h2><p>Volte ao app My Gold — seu premium será ativado em instantes.</p>'));
router.get('/checkout/cancel', (_req, res) =>
  res.send('<h2>Pagamento cancelado</h2><p>Você pode voltar ao app My Gold.</p>'));

// Webhook: raw body exigido — montado em index.ts antes do json parser.
export async function stripeWebhook(rawBody: Buffer, signature: string): Promise<void> {
  if (!stripe) throw new Error('Stripe não configurado');
  const event = stripe.webhooks.constructEvent(rawBody, signature, process.env.STRIPE_WEBHOOK_SECRET ?? '');

  if (event.type === 'customer.subscription.created' || event.type === 'customer.subscription.updated' || event.type === 'customer.subscription.deleted') {
    const sub = event.data.object as Stripe.Subscription;
    const customerId = typeof sub.customer === 'string' ? sub.customer : sub.customer.id;
    const [user] = await db.select().from(users).where(eq(users.stripeCustomerId, customerId));
    if (!user) return;

    const active = sub.status === 'active' || sub.status === 'trialing';
    const periodEnd = sub.items.data[0]?.current_period_end;
    await db
      .insert(subscriptions)
      .values({
        userId: user.id,
        stripeSubscriptionId: sub.id,
        status: sub.status,
        currentPeriodEnd: periodEnd ? new Date(periodEnd * 1000) : null,
      })
      .onConflictDoUpdate({
        target: subscriptions.stripeSubscriptionId,
        set: { status: sub.status, currentPeriodEnd: periodEnd ? new Date(periodEnd * 1000) : null },
      });
    await db.update(users).set({ isPremium: active }).where(eq(users.id, user.id));
  }
}
