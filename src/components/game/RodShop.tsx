import { useEffect } from "react";
import { Coins, Loader2 } from "lucide-react";
import { useProfileStore } from "@/hooks/useProfileStore";
import { useRodStore } from "@/hooks/useRodStore";

/** Old Bram's rod stock: stats, price, buy and equip. */
export function RodShop() {
  const proof = useProfileStore((s) => s.proof);
  const coins = Math.round(Number(useProfileStore((s) => s.profile?.coins) ?? 0));
  const rods = useRodStore((s) => s.rods);
  const loading = useRodStore((s) => s.loading);
  const busyId = useRodStore((s) => s.busyId);
  const error = useRodStore((s) => s.error);
  const refresh = useRodStore((s) => s.refresh);
  const buy = useRodStore((s) => s.buy);
  const equip = useRodStore((s) => s.equip);

  useEffect(() => {
    if (proof) void refresh();
  }, [proof, refresh]);

  if (!proof) {
    return (
      <p className="text-sm text-slate-300">
        "Connect your wallet first — I don't hand out carbon on credit."
      </p>
    );
  }

  if (loading && rods.length === 0) {
    return (
      <p className="flex items-center gap-2 text-sm text-slate-400">
        <Loader2 className="h-4 w-4 animate-spin" /> Pulling rods off the rack…
      </p>
    );
  }

  return (
    <div className="space-y-2">
      {rods.map((rod) => {
        const busy = busyId === rod.rod_id;
        const affordable = coins >= rod.price_coins;
        return (
          <div
            key={rod.rod_id}
            className={`rounded-xl border px-3 py-2.5 ${
              rod.equipped
                ? "border-amber-300/60 bg-amber-300/10"
                : "border-white/10 bg-white/[0.03]"
            }`}
          >
            <div className="flex items-center gap-2">
              <p className="flex-1 text-sm font-semibold text-slate-100">
                {rod.name}
                {rod.equipped && (
                  <span className="ml-2 rounded bg-amber-400/20 px-1.5 py-0.5 text-[10px] font-bold uppercase text-amber-200">
                    In use
                  </span>
                )}
              </p>
              {rod.owned ? (
                <button
                  type="button"
                  disabled={busy || rod.equipped}
                  onClick={() => void equip(rod.rod_id)}
                  className="rounded-md border border-white/15 px-2.5 py-1 text-[11px] font-semibold text-amber-300 transition-colors hover:bg-white/10 disabled:opacity-40"
                >
                  {rod.equipped ? "Equipped" : busy ? "Switching…" : "Use rod"}
                </button>
              ) : (
                <button
                  type="button"
                  disabled={busy || !affordable}
                  onClick={() => void buy(rod.rod_id)}
                  className="flex items-center gap-1 rounded-md bg-amber-400/90 px-2.5 py-1 text-[11px] font-semibold text-slate-900 transition-colors hover:bg-amber-300 disabled:opacity-40"
                >
                  <Coins className="h-3 w-3" aria-hidden />
                  {busy ? "Buying…" : rod.price_coins.toLocaleString()}
                </button>
              )}
            </div>
            <p className="mt-1 flex flex-wrap gap-x-3 text-[11px] text-slate-400">
              <span>Luck {rod.luck_percent}%</span>
              <span>Reel speed {rod.speed_percent}%</span>
              <span>Max {rod.max_catch_weight_kg.toLocaleString()} kg</span>
              {!rod.owned && !affordable && (
                <span className="text-rose-400">Not enough coins</span>
              )}
            </p>
          </div>
        );
      })}
      {error && <p className="text-xs text-rose-400">{error}</p>}
    </div>
  );
}
