import NodeCache from 'node-cache';

export interface GoldPrice {
  priceBrl: number;
  openBrl: number;
  changeBrl: number;
  changePct: number;
  lowBrl: number;
  highBrl: number;
  fetchedAt: string;
}

const cache = new NodeCache({ stdTTL: 60 });
const KEY = 'gold';
let stale: GoldPrice | null = null;

// Histórico é imutável — cache em memória por data, sem TTL.
// null = data sem cotação (fim de semana/feriado LBMA).
const histCache = new Map<string, number | null>();

export async function getHistoricalGram(date: string): Promise<number | null> {
  const hit = histCache.get(date);
  if (hit !== undefined) return hit;
  try {
    const res = await fetch(`https://www.goldapi.io/api/XAU/BRL/${date}`, {
      headers: { 'x-access-token': process.env.GOLDAPI_KEY ?? '' },
    });
    if (res.status === 403 || res.status === 429) return null; // quota — não cacheia, tenta depois
    const d = res.ok ? await res.json() : null;
    const v =
      d && typeof d.price_gram_24k === 'number' && Number.isFinite(d.price_gram_24k) && d.price_gram_24k > 0
        ? d.price_gram_24k
        : null;
    histCache.set(date, v);
    return v;
  } catch {
    return null; // erro de rede — não cacheia
  }
}

export async function getGoldPrice(): Promise<GoldPrice> {
  const hit = cache.get<GoldPrice>(KEY);
  if (hit) return hit;

  try {
    const res = await fetch('https://www.goldapi.io/api/XAU/BRL', {
      headers: { 'x-access-token': process.env.GOLDAPI_KEY ?? '' },
    });
    if (!res.ok) throw new Error(`GoldAPI ${res.status}`);
    const d = await res.json();
    // Plano free da GoldAPI não manda open/low/high — só price, ch e price_gram_24k.
    const ok = (n: unknown): n is number => typeof n === 'number' && Number.isFinite(n) && n > 0;
    if (!ok(d.price_gram_24k) || !ok(d.price) || typeof d.ch !== 'number' || !Number.isFinite(d.ch))
      throw new Error('GoldAPI: payload inválido');
    const OZ = 31.1034768;
    const open = ok(d.open_price) ? d.open_price : d.price - d.ch;
    const low = ok(d.low_price) ? d.low_price : Math.min(open, d.price);
    const high = ok(d.high_price) ? d.high_price : Math.max(open, d.price);
    const price: GoldPrice = {
      priceBrl: d.price_gram_24k,
      openBrl: open / OZ,
      changeBrl: d.price_gram_24k - open / OZ,
      changePct: ((d.price - open) / open) * 100,
      lowBrl: low / OZ,
      highBrl: high / OZ,
      fetchedAt: new Date().toISOString(),
    };
    cache.set(KEY, price);
    stale = price;
    return price;
  } catch (err) {
    if (stale) return stale;
    throw err;
  }
}
