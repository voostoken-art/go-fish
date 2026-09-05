/** Tampilan pancing per tier: dipakai model 3D di tangan dan kartu di toko. */
export interface RodLook {
  grip: string;
  blank: string;
  tip: string;
  accent: string;
  glow: number;
}

export const ROD_LOOKS: Record<string, RodLook> = {
  starter: { grip: "#5d3a22", blank: "#22303c", tip: "#2c3d4c", accent: "#b9c1c8", glow: 0 },
  uncommon: { grip: "#3f5a2e", blank: "#1f4030", tip: "#2a5a40", accent: "#8fd18f", glow: 0 },
  rare: { grip: "#1f3352", blank: "#16345e", tip: "#1f4e8c", accent: "#6db4ff", glow: 0.15 },
  epic: { grip: "#3a2154", blank: "#2c1a52", tip: "#5b2d8e", accent: "#c58cff", glow: 0.35 },
  legendary: { grip: "#5c3a10", blank: "#6b3d0f", tip: "#b06a1e", accent: "#ffcf5c", glow: 0.6 },
  mythic: { grip: "#4a0f22", blank: "#520f2e", tip: "#8c1445", accent: "#ff5c8a", glow: 1 },
};

export const rodLook = (id: string | null | undefined): RodLook =>
  (id ? ROD_LOOKS[id] : undefined) ?? ROD_LOOKS["starter"]!;
