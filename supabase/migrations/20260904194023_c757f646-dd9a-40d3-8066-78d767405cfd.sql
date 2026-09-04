REVOKE EXECUTE ON FUNCTION public.buy_rod(text, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.equip_rod(text, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_player_rods(text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.record_catch(text, text, text, numeric, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.sell_fish(text, uuid, text, boolean) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.ensure_starter_rod() FROM PUBLIC, anon, authenticated;