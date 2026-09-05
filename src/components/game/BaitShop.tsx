import { useEffect } from "react";
import { Coins, Loader2 } from "lucide-react";
import { useProfileStore } from "@/hooks/useProfileStore";
import { useBaitStore } from "@/hooks/useBaitStore";
import { baitLook } from "@/lib/baitLooks";

/** Bola umpan 2D per tier, warna dan cahayanya sama dengan model di air. */
function BaitOrb({ baitId }: { baitId: string }) {
  const look = baitLook(baitId);
  const id = `bait-${baitId}`;
  return (
    <svg viewBox="0 0 100 100" className="h-full w-full" aria-hidden>
      <defs>
        <radialGradient id={id} cx="40%" cy="35%">
          <stop offset="0%" stopColor={look.accent} />
          <stop offset="55%" stopColor={look.core} />
          <stop offset="100%" stopColor={look.shell} />
        </radialGradient>
      </defs>
      {look.glow > 0 && (
        <circle cx="50" cy="52" r={30 + look.glow * 14} fill={look.core} opacity={0.1 + look.glow * 0.18} />
      )}
      <circle cx="50" cy="52" r="26" fill={`url(#${id})`} />
      <circle cx="50" cy="52" r="26" fill="none" stroke={look.accent} strokeWidth="1.5" opacity="0.6" />
      <ellipse cx="41" cy="42" rx="7" ry="5" fill="#ffffff" opacity="0.55" />
    </svg>
  );
}

/** Pip's bait stock: kartu horizontal — luck, harga, beli, pakai. */
export function BaitShop() {
  const proof = useProfileStore((s) => s.proof);
  const coins = Math.round(Number(useProfileStore((s) => s.profile?.coins) ?? 0));
  const baits = useBaitStore((s) => s.baits);
  const loading = useBaitStore((s) => s.loading);
  const busyId = useBaitStore((s) => s.busyId);
  const error = useBaitStore((s) => s.error);
  const refresh = useBaitStore((s) => s.refresh);
  const buy = useBaitStore((s) => s.buy);
  const equip = useBaitStore((s) => s.equip);

  useEffect(() => {
    if (proof) void refresh();
  }, [proof, refresh]);

  if (!proof) {
    return (
      <p className="text-sm text-slate-300">
        "Connect your wallet first — worms aren't free, friend."
      </p>
    );
  }

  if (loading && baits.length === 0) {
    return (
      <p className="flex items-center gap-2 text-sm text-slate-400">
        <Loader2 className="h-4 w-4 animate-spin" /> Digging through the bait crates…
      </p>
    );
  }

  return (
    <div>
      <div className="flex gap-3 overflow-x-auto pb-2">
        {baits.map((bait) => {
          const busy = busyId === bait.bait_id;
          const affordable = coins >= bait.price_coins;
          const look = baitLook(bait.bait_id);
          return (
            <div
              key={bait.bait_id}
              className={`flex w-44 shrink-0 flex-col rounded-xl border-2 p-2.5 ${
                bait.equipped
                  ? "border-amber-300/80 bg-amber-300/10"
                  : bait.owned
                    ? "border-white/25 bg-white/[0.05]"
                    : "border-white/15 bg-white/[0.03]"
              }`}
            >
              <p className="text-center text-sm font-bold text-slate-100">{bait.name}</p>
              {bait.owned ? (
                <p className="text-center text-[11px] font-extrabold uppercase tracking-wide text-emerald-400">
                  {bait.equipped ? "In use" : "Owned"}
                </p>
              ) : (
                <p className="flex items-center justify-center gap-1 text-[12px] font-bold text-amber-300">
                  <Coins className="h-3.5 w-3.5" aria-hidden />
                  {bait.price_coins.toLocaleString()}
                </p>
              )}

              <div
                className="my-2 h-28 rounded-lg"
                style={{
                  background: `radial-gradient(circle at 50% 50%, ${look.core}33, rgba(0,0,0,0.35) 70%)`,
                }}
              >
                <BaitOrb baitId={bait.bait_id} />
              </div>

              <div className="rounded-lg bg-black/40 px-2.5 py-1.5 text-[11px] font-semibold leading-5 text-slate-200">
                <p>
                  Luck: <span className="text-emerald-400">{bait.luck_percent}%</span>
                </p>
              </div>

              {bait.owned ? (
                <button
                  type="button"
                  disabled={busy || bait.equipped}
                  onClick={() => void equip(bait.bait_id)}
                  className="mt-2 w-full rounded-lg bg-emerald-500 py-1.5 text-xs font-extrabold text-slate-950 transition-colors hover:bg-emerald-400 disabled:opacity-40"
                >
                  {bait.equipped ? "Equipped" : busy ? "Switching…" : "Use bait"}
                </button>
              ) : (
                <button
                  type="button"
                  disabled={busy || !affordable}
                  onClick={() => void buy(bait.bait_id)}
                  className="mt-2 w-full rounded-lg bg-emerald-500 py-1.5 text-xs font-extrabold text-slate-950 transition-colors hover:bg-emerald-400 disabled:opacity-40"
                >
                  {busy ? "Buying…" : affordable ? "Buy" : "Not enough coins"}
                </button>
              )}
            </div>
          );
        })}
      </div>
      {error && <p className="mt-1 text-xs text-rose-400">{error}</p>}
    </div>
  );
}
