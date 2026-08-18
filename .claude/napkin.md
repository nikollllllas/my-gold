# Napkin Runbook

## Curation Rules
- Re-prioritize on every read.
- Keep recurring, high-value notes only.
- Max 10 items per category.
- Each item includes date + "Do instead".

## Execution & Validation (Highest Priority)
1. **[2026-07-17] Emulador Android bloqueado: SVM desabilitado na BIOS**
   Do instead: até usuário habilitar SVM na BIOS, testar via `flutter run -d chrome --dart-define=API_URL=http://localhost:3000`. AVD `my_gold_pixel` (android-36, x86_64) já criado, pronto quando `/dev/kvm` existir.
2. **[2026-07-17] Backend precisa de DATABASE_URL na 5433**
   Do instead: `DATABASE_URL='postgres://postgres:postgres@localhost:5433/mygold' ENABLE_CRON=false npm start` em `backend/` (default do db.ts é 5432, errado p/ dev).
3. **[2026-07-17] App usa `API_URL` via dart-define, default `http://10.0.2.2:3000`**
   Do instead: web/desktop passar `--dart-define=API_URL=http://localhost:3000`; emulador Android usa default.

## Shell & Command Reliability
1. **[2026-07-17] zsh quebra em globs tipo `--include=*.dart` sem aspas**
   Do instead: quote patterns: `--include='*.dart'`.
2. **[2026-07-17] `sudo` não roda nesta sessão (sem TTY p/ senha)**
   Do instead: pedir p/ usuário rodar em terminal próprio.

## Domain Behavior Guardrails
1. **[2026-07-17] GoldAPI plano free: sem open/low/high no payload atual, ~100 requests/mês**
   Do instead: `gold.ts` deriva open/low/high de `price`/`ch`; `/history` busca da API por data (cache em memória, sem DB) — períodos 120d/1y estouram quota, preenchem parcial.
1. **[2026-07-17] CORS do backend é middleware manual em index.ts (dev, `*`)**
   Do instead: restringir origin antes de deploy prod.
