ALTER TABLE public.bait_tiers
  ADD COLUMN IF NOT EXISTS luck_percent numeric NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS price_coins numeric NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS sort_order integer NOT NULL DEFAULT 0;

INSERT INTO public.bait_tiers (id, name, rarity_multiplier, luck_percent, price_coins, sort_order) VALUES
  ('basic_bait', 'Basic Bait', '{}'::jsonb, 0, 0, 0),
  ('uncommon_bait', 'Uncommon Bait', '{}'::jsonb, 20, 1000, 1),
  ('rare_bait', 'Rare Bait', '{}'::jsonb, 50, 15000, 2),
  ('epic_bait', 'Epic Bait', '{}'::jsonb, 95, 120000, 3),
  ('legendary_bait', 'Legendary Bait', '{}'::jsonb, 160, 600000, 4),
  ('mythic_bait', 'Mythic Bait', '{}'::jsonb, 250, 2000000, 5)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  luck_percent = EXCLUDED.luck_percent,
  price_coins = EXCLUDED.price_coins,
  sort_order = EXCLUDED.sort_order;

CREATE TABLE IF NOT EXISTS public.player_baits (
  wallet_address text NOT NULL REFERENCES public.profiles(wallet_address) ON DELETE CASCADE,
  bait_id text NOT NULL REFERENCES public.bait_tiers(id),
  equipped boolean NOT NULL DEFAULT false,
  purchased_at timestamp with time zone NOT NULL DEFAULT now(),
  PRIMARY KEY (wallet_address, bait_id)
);

GRANT SELECT ON public.player_baits TO authenticated;
GRANT ALL ON public.player_baits TO service_role;

ALTER TABLE public.player_baits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users read own baits"
  ON public.player_baits FOR SELECT TO authenticated
  USING (wallet_address = (auth.uid())::text);

CREATE POLICY "Service role manages player baits"
  ON public.player_baits FOR ALL TO service_role
  USING (true) WITH CHECK (true);

CREATE OR REPLACE FUNCTION public.ensure_starter_rod()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  INSERT INTO public.player_rods (wallet_address, rod_id, equipped)
  VALUES (NEW.wallet_address, 'starter', true)
  ON CONFLICT (wallet_address, rod_id) DO NOTHING;

  INSERT INTO public.player_baits (wallet_address, bait_id, equipped)
  VALUES (NEW.wallet_address, 'basic_bait', true)
  ON CONFLICT (wallet_address, bait_id) DO NOTHING;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_player_baits(_wallet text)
RETURNS TABLE(bait_id text, name text, luck_percent numeric, price_coins numeric, equipped boolean, purchased_at timestamp with time zone)
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT
    bt.id AS bait_id,
    bt.name,
    bt.luck_percent,
    bt.price_coins,
    COALESCE(pb.equipped, false) AS equipped,
    pb.purchased_at
  FROM public.bait_tiers bt
  LEFT JOIN public.player_baits pb ON pb.bait_id = bt.id AND pb.wallet_address = _wallet
  ORDER BY bt.sort_order, bt.price_coins;
$$;

CREATE OR REPLACE FUNCTION public.buy_bait(_wallet text, _bait_id text)
RETURNS public.profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  bait public.bait_tiers;
  me public.profiles;
BEGIN
  SELECT * INTO bait FROM public.bait_tiers WHERE id = _bait_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Bait not found';
  END IF;

  IF EXISTS (SELECT 1 FROM public.player_baits WHERE wallet_address = _wallet AND bait_id = _bait_id) THEN
    RAISE EXCEPTION 'Bait already owned';
  END IF;

  SELECT * INTO me FROM public.profiles WHERE wallet_address = _wallet FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Profile not found';
  END IF;

  IF me.coins < bait.price_coins THEN
    RAISE EXCEPTION 'Not enough coins';
  END IF;

  UPDATE public.profiles
     SET coins = coins - bait.price_coins,
         updated_at = now()
   WHERE wallet_address = _wallet;

  INSERT INTO public.player_baits (wallet_address, bait_id, equipped)
  VALUES (_wallet, _bait_id, NOT EXISTS (SELECT 1 FROM public.player_baits WHERE wallet_address = _wallet));

  RETURN (SELECT * FROM public.profiles WHERE wallet_address = _wallet);
END;
$$;

CREATE OR REPLACE FUNCTION public.equip_bait(_wallet text, _bait_id text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.player_baits WHERE wallet_address = _wallet AND bait_id = _bait_id) THEN
    RAISE EXCEPTION 'Bait not owned';
  END IF;

  UPDATE public.player_baits SET equipped = false WHERE wallet_address = _wallet;
  UPDATE public.player_baits SET equipped = true WHERE wallet_address = _wallet AND bait_id = _bait_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_player_baits(text) FROM anon, authenticated, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.buy_bait(text, text) FROM anon, authenticated, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.equip_bait(text, text) FROM anon, authenticated, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.ensure_starter_rod() FROM anon, authenticated, PUBLIC;

INSERT INTO public.player_baits (wallet_address, bait_id, equipped)
SELECT p.wallet_address, 'basic_bait', true FROM public.profiles p
ON CONFLICT (wallet_address, bait_id) DO NOTHING;