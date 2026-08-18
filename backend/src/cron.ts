import cron from 'node-cron';
import { eq, and } from 'drizzle-orm';
import { db } from './db.js';
import { alerts, users } from './schema.js';
import { getGoldPrice } from './gold.js';
import { sendPush } from './push.js';

export function startCronJobs() {
  // A cada minuto: verifica alertas ativos (one-shot: triggered=true após disparo)
  cron.schedule('* * * * *', async () => {
    try {
      const p = await getGoldPrice();
      const pending = await db
        .select({ alert: alerts, fcmToken: users.fcmToken })
        .from(alerts)
        .innerJoin(users, eq(alerts.userId, users.id))
        .where(and(eq(alerts.triggered, false), eq(users.isPremium, true)));

      for (const { alert, fcmToken } of pending) {
        const target = Number(alert.targetPrice);
        const hit = alert.direction === 'above' ? p.priceBrl >= target : p.priceBrl <= target;
        if (!hit) continue;
        // Push primeiro; só consome o alerta se entregou. Falha transitória do
        // FCM → alerta continua ativo e tenta de novo no próximo minuto.
        // Sem token não há como notificar: consome para não ficar em loop.
        let delivered = true;
        if (fcmToken) {
          const fmt = (v: number) => v.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
          delivered = await sendPush(
            fcmToken,
            'Alerta de preço do ouro',
            `Ouro atingiu ${fmt(p.priceBrl)}/g (alvo: ${fmt(target)} ${alert.direction === 'above' ? 'acima' : 'abaixo'})`,
          );
        }
        if (delivered || !fcmToken) {
          await db.update(alerts).set({ triggered: true }).where(eq(alerts.id, alert.id));
        }
      }
    } catch (err) {
      console.error('[cron:alerts]', err);
    }
  });
}
