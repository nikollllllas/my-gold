# My Gold — Spec de Design
**Data:** 2026-06-08  
**Status:** Aprovado

---

## Visão Geral

App mobile (iOS + Android) em Flutter para monitoramento do preço do ouro em tempo real, voltado ao investidor/trader brasileiro. Exibe preço atual em BRL, histórico em múltiplos períodos e oferece ferramentas premium de análise e alertas. Monetização via assinatura + afiliados contextuais.

---

## Arquitetura Geral

```
┌─────────────────────────────────────────┐
│           Flutter App (mobile)          │
│                                         │
│  Home Screen  │  Chart  │  Premium UI  │
└──────────────────────┬──────────────────┘
                       │ REST/JSON
                       ▼
┌─────────────────────────────────────────┐
│         Express Backend (Node.js)       │
│                                         │
│  /prices   /history   /auth   /alerts  │
│                                         │
│  Cache em memória (node-cache, 1 min)  │
└───────────┬─────────────────┬───────────┘
            │                 │
            ▼                 ▼
      GoldAPI.io          PostgreSQL
    (preço do ouro)   (users, alerts,
                       subscriptions)
```

**Fluxo principal:**
1. Flutter chama `GET /prices/gold` a cada 60s
2. Express verifica cache — se fresco retorna; se expirado busca na GoldAPI
3. Histórico (`/history?period=7d`) retorna dados do banco, populados por cron job a cada hora
4. Auth via JWT — apenas rotas premium exigem token válido

---

## Frontend — Flutter

### Stack
- Flutter (iOS + Android)
- `fl_chart` para gráficos
- `riverpod` para gerenciamento de estado
- `dio` para HTTP
- `firebase_messaging` para push notifications
- `flutter_stripe` para checkout de assinatura

### Telas

**Home (livre)**
- Header: data/hora atual + status do mercado (aberto/fechado)
- `GoldPriceCard`: preço atual em BRL/grama, variação do dia (valor + %) em verde/vermelho, range baixo/alto
- `PeriodSelector`: abas `1D | 7D | 30D | 120D | 1A`
- `GoldChart`: gráfico de linha interativo com área preenchida abaixo
- `AffiliateBanner`: banner fixo no rodapé, discreto, link para corretora parceira
- Bottom nav: **Início | Mercado | Calculadora | Conta**

**Calculadora (premium)**
- Input: quantidade em gramas ou onças
- Input: data de compra
- Output: valor atual, variação desde a compra, rentabilidade %

**Alertas (premium)**
- Lista de alertas configurados pelo usuário
- Criar alerta: preço alvo + direção (acima/abaixo)
- Push notification via FCM quando alerta é disparado

**Conta**
- Free: CTA de upgrade com lista de benefícios do premium
- Premium: dados da conta, gerenciar assinatura, toggle para ocultar banner de afiliado, cancelar

### Tema
- Segue `ThemeMode.system` mas dark como padrão
- Design system próprio (não usa Material puro nem pacotes de UI de terceiros)

---

## Design System

### Tokens de Cor

| Token | Valor | Uso |
|---|---|---|
| Background | `#0A0A0F` | Fundo principal |
| Surface | `#12121A` | Cards e painéis |
| Border | `#1E1E2E` | Separadores |
| Gold Primary | `#D4AF37` | Cor identitária, CTAs |
| Gold Light | `#F0D060` | Hover / highlights |
| Up Green | `#00C896` | Alta de preço |
| Down Red | `#FF4D6A` | Queda de preço |
| Text Primary | `#F0F0F0` | Texto principal |
| Text Secondary | `#8888A0` | Labels, subtextos |

### Tipografia
- Família: `Inter`
- Variantes: Regular, Medium, SemiBold, Bold

### Componentes do UI Kit

| Componente | Descrição |
|---|---|
| `GoldPriceCard` | Card principal com preço + variação |
| `PriceTag` | Valor com cor dinâmica (verde/vermelho) |
| `GoldChart` | Wrapper do fl_chart com tema unificado |
| `PeriodSelector` | Abas de período 1D/7D/30D/120D/1A |
| `AffiliateBanner` | Banner rodapé discreto com link de afiliado |
| `PremiumGate` | Wrapper que bloqueia conteúdo com CTA de upgrade |
| `GoldButton` | Botão primário com cor gold |
| `GoldTextField` | Input estilizado |

---

## Backend — Express

### Stack
- Express + TypeScript
- Drizzle ORM (PostgreSQL)
- `node-cache` (cache em memória)
- `stripe` (pagamentos e assinaturas)
- `firebase-admin` (push notifications via FCM)
- `jsonwebtoken` (auth JWT)
- `node-cron` (jobs periódicos)

### Endpoints

```
GET  /prices/gold                        → preço atual (cache 60s)
GET  /history?period=1d|7d|30d|120d|1y  → histórico de preços
POST /auth/register                      → cadastro (necessário para premium)
POST /auth/login                         → login, retorna JWT
GET  /auth/me                            → dados do usuário autenticado
POST /alerts                             → criar alerta (premium)
GET  /alerts                             → listar alertas do usuário (premium)
DELETE /alerts/:id                       → remover alerta (premium)
POST /subscriptions/checkout             → iniciar checkout Stripe
POST /subscriptions/webhook              → webhook Stripe (ativar/cancelar premium)
```

### Cron Jobs
- **A cada hora:** busca histórico na GoldAPI e persiste no PostgreSQL
- **A cada minuto:** verifica alertas ativos contra preço atual; dispara push via FCM se condição atingida

### Banco de Dados (PostgreSQL via Drizzle)

Tabelas principais:
- `users` — id, email, password_hash, is_premium, stripe_customer_id, created_at
- `price_history` — id, price_brl, recorded_at
- `alerts` — id, user_id, target_price, direction (above/below), triggered, created_at
- `subscriptions` — id, user_id, stripe_subscription_id, status, current_period_end

---

## Monetização

### Assinatura Premium (Stripe)
- Plano mensal: **R$14,90/mês**
- Plano anual: **R$119,90/ano** (~20% de desconto)
- Free tier: tela principal + gráficos completos
- Premium desbloqueia: alertas de preço, calculadora de investimento, análise técnica (médias móveis + RSI), remoção do banner de afiliado

### Afiliados
- Um único `AffiliateBanner` fixo no rodapé da Home
- Parceiros: corretoras e plataformas de metais preciosos relevantes ao contexto brasileiro
- Links com UTM para rastreamento de comissão
- Usuários premium podem desativar o banner nas configurações da conta

**Princípio:** zero popups, zero interstitials, zero banners no meio de conteúdo. O banner é contextual e único.

---

## Análise Técnica (Premium)

Indicadores exibidos sobrepostos ao `GoldChart`:
- **Média Móvel Simples (SMA):** períodos 9 e 21
- **RSI (Relative Strength Index):** período 14, exibido em painel separado abaixo do gráfico
- Calculados no frontend a partir dos dados históricos já carregados

---

## Fonte de Dados

- **GoldAPI.io** — preço em tempo real do ouro
  - Free tier: 100 req/mês (para desenvolvimento)
  - Plano básico: ~$10/mês (produção, tempo real)
- Moeda: exclusivamente **BRL (Real Brasileiro)**
- Unidade: preço por grama

---

## Fora de Escopo (v1)

- Suporte a outras moedas (USD, EUR)
- Outros metais preciosos (prata, platina)
- Versão web
- Notícias e conteúdo editorial
- Social features (compartilhamento, rankings)
