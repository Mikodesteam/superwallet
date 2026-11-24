// Excerpt from SuperWallet (functions/src/pro_crypto_plans.ts). Shown for illustration only.
// The full source code is available at https://store.mikodes.com/p/superwallet/
//
// Server-side pricing for paying for PRO with crypto. The caller only names a plan;
// the price and the length come from the operator settings, an unknown plan is refused,
// and a small tolerance absorbs price moves between sending and confirming.

export type ProCryptoPlanId = "proWeekly" | "proMonthly" | "proAnnual";

/** How long PRO lasts per plan, in days. */
export const PRO_CRYPTO_PLAN_DAYS: Readonly<Record<ProCryptoPlanId, number>> = {
  proWeekly: 7,
  proMonthly: 30,
  proAnnual: 365,
};

// (price keys: one operator setting per plan, in EUR)

/**
 * Maps every spelling of a plan id in use (the app's `MembershipPlanId`
 * names, snake_case from older records, and "yearly") to one id. Anything
 * else is null and is refused: an unknown id must never fall back to a plan.
 */
export function normalizeProCryptoPlanId(raw: unknown): ProCryptoPlanId | null {
  // … maps every spelling in use to one id; anything else returns null
}

function positiveNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  const n = Number(value);
  return Number.isFinite(n) && n > 0 ? n : null;
}

export type ProCryptoPlanTerms =
  | { ok: true; planId: ProCryptoPlanId; days: number; requiredEur: number }
  | { ok: false; code: "invalid-argument" | "failed-precondition"; message: string };

export function proCryptoPlanTerms(
  config: Record<string, unknown>,
  rawPlanId: unknown,
): ProCryptoPlanTerms {
  const planId = normalizeProCryptoPlanId(rawPlanId);
  if (!planId) {
    return {
      ok: false,
      code: "invalid-argument",
      message: "That PRO plan does not exist.",
    };
  }
  const key = PRO_CRYPTO_PLAN_PRICE_KEYS[planId];
  const raw = config[key];
  const requiredEur =
    planId === "proWeekly"
      ? raw === undefined || raw === null
        ? 1
        : positiveNumber(raw)
      : positiveNumber(raw);
  if (requiredEur === null) {
    return planId === "proWeekly"
      ? {
          ok: false,
          code: "failed-precondition",
          message: "The PRO price in EUR is not configured.",
        }
      : {
          ok: false,
          code: "failed-precondition",
          message: "This PRO plan is not sold for crypto in this app.",
        };
  }
  return { ok: true, planId, days: PRO_CRYPTO_PLAN_DAYS[planId], requiredEur };
}

/** 2% tolerance covers the price moving between sending and confirming. */
export function proCryptoPaymentCovers(
  paidEur: number,
  requiredEur: number,
): boolean {
  return Number.isFinite(paidEur) && paidEur >= requiredEur * 0.98;
}
