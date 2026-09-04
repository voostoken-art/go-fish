ALTER TABLE public.rod_tiers
  ADD COLUMN IF NOT EXISTS luck_percent numeric NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS speed_percent numeric NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS price_coins numeric NOT NULL DEFAULT 0;

-- Seed / update rod tiers. Existing rows are overwritten; new rows are inserted.
INSERT INTO public.rod_tiers (id, name, max_catch_weight_kg, luck_percent, speed_percent, price_coins)
VALUES
  ('starter', 'Starter Rod', 10, 0, 0, 0),
  ('uncommon', 'Uncommon Rod', 40, 10, 5, 1000),
  ('rare', 'Rare Rod', 100, 25, 12, 10000),
  ('epic', 'Epic Rod', 250, 50, 22, 60000),
  ('legendary', 'Legendary Rod', 600, 80, 35, 250000),
  ('mythic', 'Mythic Rod', 1500, 130, 50, 1000000)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  max_catch_weight_kg = EXCLUDED.max_catch_weight_kg,
  luck_percent = EXCLUDED.luck_percent,
  speed_percent = EXCLUDED.speed_percent,
  price_coins = EXCLUDED.price_coins;

CREATE TABLE public.player_rods (
  wallet_address text NOT NULL REFERENCES public.profiles(wallet_address) ON DELETE CASCADE,
  rod_id text NOT NULL REFERENCES public.rod_tiers(id) ON DELETE RESTRICT,
  equipped boolean NOT NULL DEFAULT false,
  purchased_at timestamp with time zone NOT NULL DEFAULT now(),
  PRIMARY KEY (wallet_address, rod_id)
);

GRANT ALL ON public.player_rods TO service_role;
GRANT SELECT ON public.player_rods TO authenticated;

ALTER TABLE public.player_rods ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role manages player rods"
  ON public.player_rods
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Authenticated users read own rods"
  ON public.player_rods
  FOR SELECT
  TO authenticated
  USING (wallet_address = auth.uid()::text);

CREATE OR REPLACE FUNCTION public.buy_rod(_wallet text, _rod_id text)
RETURNS public.profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  rod public.rod_tiers;
  me public.profiles;
BEGIN
  SELECT * INTO rod FROM public.rod_tiers WHERE id = _rod_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Rod not found';
  END IF;

  IF EXISTS (SELECT 1 FROM public.player_rods WHERE wallet_address = _wallet AND rod_id = _rod_id) THEN
    RAISE EXCEPTION 'Rod already owned';
  END IF;

  SELECT * INTO me FROM public.profiles WHERE wallet_address = _wallet FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Profile not found';
  END IF;

  IF me.coins < rod.price_coins THEN
    RAISE EXCEPTION 'Not enough coins';
  END IF;

  UPDATE public.profiles
     SET coins = coins - rod.price_coins,
         updated_at = now()
   WHERE wallet_address = _wallet;

  INSERT INTO public.player_rods (wallet_address, rod_id, equipped)
  VALUES (_wallet, _rod_id, NOT EXISTS (SELECT 1 FROM public.player_rods WHERE wallet_address = _wallet));

  RETURN (SELECT * FROM public.profiles WHERE wallet_address = _wallet);
END;
$$;

CREATE OR REPLACE FUNCTION public.equip_rod(_wallet text, _rod_id text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.player_rods WHERE wallet_address = _wallet AND rod_id = _rod_id) THEN
    RAISE EXCEPTION 'Rod not owned';
  END IF;

  UPDATE public.player_rods SET equipped = false WHERE wallet_address = _wallet;
  UPDATE public.player_rods SET equipped = true WHERE wallet_address = _wallet AND rod_id = _rod_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_player_rods(_wallet text)
RETURNS TABLE (
  rod_id text,
  name text,
  max_catch_weight_kg numeric,
  luck_percent numeric,
  speed_percent numeric,
  price_coins numeric,
  equipped boolean,
  purchased_at timestamp with time zone
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    rt.id AS rod_id,
    rt.name,
    rt.max_catch_weight_kg,
    rt.luck_percent,
    rt.speed_percent,
    rt.price_coins,
    COALESCE(pr.equipped, false) AS equipped,
    pr.purchased_at
  FROM public.rod_tiers rt
  LEFT JOIN public.player_rods pr ON pr.rod_id = rt.id AND pr.wallet_address = _wallet
  ORDER BY rt.price_coins;
$$;

-- Ensure every new profile gets a free Starter Rod.
CREATE OR REPLACE FUNCTION public.ensure_starter_rod()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.player_rods (wallet_address, rod_id, equipped)
  VALUES (NEW.wallet_address, 'starter', true)
  ON CONFLICT (wallet_address, rod_id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER tr_ensure_starter_rod
AFTER INSERT ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.ensure_starter_rod();
