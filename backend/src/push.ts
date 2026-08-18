import { initializeApp, applicationDefault, cert, type App } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

// Inicializa só se houver credencial (GOOGLE_APPLICATION_CREDENTIALS ou FIREBASE_SERVICE_ACCOUNT)
let app: App | null = null;
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  app = initializeApp({ credential: cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)) });
} else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  app = initializeApp({ credential: applicationDefault() });
}

/** Retorna true se a notificação foi entregue ao FCM. */
export async function sendPush(fcmToken: string, title: string, body: string): Promise<boolean> {
  if (!app) {
    console.warn('[push] FCM não configurado, notificação descartada:', title);
    return false;
  }
  try {
    await getMessaging(app).send({ token: fcmToken, notification: { title, body } });
    return true;
  } catch (err) {
    console.error('[push]', err);
    return false;
  }
}
