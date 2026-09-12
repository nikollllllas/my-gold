# My Gold 🪙

App de monitoramento do preço do ouro (XAU/BRL) com histórico de cotações, alertas de preço e notificações push. Backend em Node/TypeScript e app mobile em Flutter.

> Spec completa: `docs/superpowers/specs/2026-06-08-gold-price-app-design.md`

## Funcionalidades

- 📈 Cotação do ouro atualizada em tempo real (cache de 60s)
- 🕒 Histórico de preços via cron job
- 🔔 Alertas de preço configuráveis
- 📱 Notificações push (Firebase Cloud Messaging)
- 💳 Assinaturas/pagamentos via Stripe
- 📊 Gráficos de indicadores (SMA/RSI) no app

## Estrutura

- `backend/` — Express + TypeScript, Drizzle (PostgreSQL), cache 60s, cron de histórico/alertas, Stripe, FCM
- `app/` — Flutter (Riverpod, Dio, fl_chart)

## Tech Stack

**Backend:** Node.js, TypeScript, Express, Drizzle ORM, PostgreSQL, Stripe, Firebase Cloud Messaging

**Mobile:** Flutter, Riverpod, Dio, fl_chart

## Como rodar

### Backend

```bash
cd backend
cp .env.example .env   # preencha GOLDAPI_KEY etc.
docker run -d --name mygold-pg -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=mygold -p 5433:5432 postgres:16-alpine
npx drizzle-kit push   # cria as tabelas
pnpm run dev           # porta 3000
```

Verificação: `npm run check` (typecheck) e `npm test` (smoke test — exige servidor + banco rodando):

```bash
ENABLE_CRON=false npm run dev &   # ou start
pnpm test                         # imprime SMOKE OK
```

### App Flutter

Requer Flutter SDK. Os diretórios de plataforma (`android/`, `ios/`) ainda não existem:

```bash
cd app
flutter create . --platforms android,ios --org digital.ecode
flutter pub get
flutter test           # testes de indicadores (SMA/RSI)
flutter run --dart-define=API_URL=http://10.0.2.2:3000
```

Push notifications exigem `flutterfire configure` (gera `google-services.json` / `GoogleService-Info.plist`) e descomentar init do Firebase em `lib/main.dart`.

## Licença

Ainda não definida.
