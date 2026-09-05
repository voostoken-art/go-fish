REVOKE EXECUTE ON FUNCTION public.record_catch(text, text, text, numeric, text) FROM anon, authenticated, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.sell_fish(text, uuid, text, boolean) FROM anon, authenticated, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.buy_rod(text, text) FROM anon, authenticated, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.equip_rod(text, text) FROM anon, authenticated, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_player_rods(text) FROM anon, authenticated, PUBLIC;