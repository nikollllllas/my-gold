# My Gold

App de monitoramento do preço do ouro em BRL. Spec: `docs/superpowers/specs/2026-06-08-gold-price-app-design.md`.

## Estrutura

- `backend/` — Express + TypeScript, Drizzle (PostgreSQL), cache 60s, cron de histórico/alertas, Stripe, FCM
- `app/` — Flutter (riverpod, dio, fl_chart)

## Backend

```bash
cd backend
cp .env.example .env   # preencha GOLDAPI_KEY etc.
docker run -d --name mygold-pg -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=mygold -p 5433:5432 postgres:16-alpine
npx drizzle-kit push   # cria as tabelas
npm run dev            # porta 3000
```

Verificação: `npm run check` (typecheck) e `npm test` (smoke test — exige servidor + banco rodando):

```bash
ENABLE_CRON=false npm run dev &   # ou start
npm test                          # imprime SMOKE OK
```

## App Flutter

Requer Flutter SDK. Os diretórios de plataforma (android/, ios/) ainda não existem:

```bash
cd app
flutter create . --platforms android,ios --org digital.ecode
flutter pub get
flutter test           # testes de indicadores (SMA/RSI)
flutter run --dart-define=API_URL=http://10.0.2.2:3000
```

Push notifications exigem `flutterfire configure` (gera google-services.json / GoogleService-Info.plist) e descomentar init do Firebase em `lib/main.dart`.
