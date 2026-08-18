import express from 'express';
import { authRouter } from './auth.js';
import { router, stripeWebhook } from './routes.js';
import { startCronJobs } from './cron.js';

const app = express();

// CORS liberado para dev (Flutter web em localhost)
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PUT,PATCH,DELETE,OPTIONS');
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
});

// Webhook Stripe precisa do body cru — antes do json parser
app.post('/subscriptions/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  try {
    await stripeWebhook(req.body, req.headers['stripe-signature'] as string);
    res.json({ received: true });
  } catch (err) {
    console.error('[webhook]', err);
    res.status(400).json({ error: 'Webhook inválido' });
  }
});

app.use(express.json());
app.use('/auth', authRouter);
app.use('/', router);

app.get('/health', (_req, res) => res.json({ ok: true }));

const port = Number(process.env.PORT ?? 3000);
app.listen(port, () => {
  console.log(`my-gold backend na porta ${port}`);
  if (process.env.ENABLE_CRON !== 'false') startCronJobs();
});
