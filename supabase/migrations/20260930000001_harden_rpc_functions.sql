-- ============================================================================
-- ADIM 1: RPC / SECURITY DEFINER sertlestirme
-- Dosya yolu: supabase/migrations/20260930000001_harden_rpc_functions.sql
-- Istemci (Flutter) kodunda DEGISIKLIK GEREKTIRMEZ: imzalar aynı kaliyor.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) Kimlik taklidi kapatma: toggle_post_like
--    p_user_id artik yalnizca auth.uid() ile ayni ise kabul edilir.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.toggle_post_like(p_post_id bigint, p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $function$
DECLARE
  v_is_liked boolean;
  v_like_count integer;
BEGIN
  IF auth.uid() IS NULL OR p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = '42501';
  END IF;

  SELECT EXISTS(
    SELECT 1 FROM post_likes
    WHERE post_id = p_post_id AND user_id = auth.uid()
  ) INTO v_is_liked;

  IF v_is_liked THEN
    DELETE FROM post_likes
    WHERE post_id = p_post_id AND user_id = auth.uid();

    DELETE FROM notifications
    WHERE type = 'like'
      AND post_id = p_post_id
      AND sender_id = auth.uid();
  ELSE
    INSERT INTO post_likes (post_id, user_id)
    VALUES (p_post_id, auth.uid())
    ON CONFLICT (user_id, post_id) DO NOTHING;
  END IF;

  SELECT COUNT(*)::integer INTO v_like_count
  FROM post_likes
  WHERE post_id = p_post_id;

  RETURN jsonb_build_object(
    'is_liked', NOT v_is_liked,
    'like_count', v_like_count
  );
END;
$function$;

-- ---------------------------------------------------------------------------
-- 2) Sadece sunucu icinden (trigger / cron) cagrilmasi gerekenler:
--    hic kimse RPC ile cagiramasin.
--    (Trigger'lar fonksiyon sahibi yetkisiyle calistigi icin etkilenmez.)
-- ---------------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.handle_new_user()          FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_new_like()          FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_new_comment()       FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_new_follow()        FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.update_tag_counts()        FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.delete_expired_stories()   FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.send_push_notification(uuid, uuid, bigint, text, text)
                                                             FROM PUBLIC, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3) Sadece giris yapmis kullanicilarin cagirabilecegi RPC'ler:
--    anon'dan al, authenticated'da birak.
-- ---------------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.delete_user_account()               FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.get_or_create_chat(uuid)            FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.toggle_post_like(bigint, uuid)      FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.upsert_tag(text)                    FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.decrease_tag_count(text)            FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.get_featured_users(integer)         FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.get_leaderboard(integer, text)      FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.delete_user_account()               TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_or_create_chat(uuid)            TO authenticated;
GRANT EXECUTE ON FUNCTION public.toggle_post_like(bigint, uuid)      TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_tag(text)                    TO authenticated;
GRANT EXECUTE ON FUNCTION public.decrease_tag_count(text)            TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_featured_users(integer)         TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_leaderboard(integer, text)      TO authenticated;

-- ---------------------------------------------------------------------------
-- 4) Scrabble RPC'leri: public semasinda scrabble_* tablolari gorunmuyor
--    (fonksiyonlar bos calisiyor / bozuk). Oyun yazilana kadar kapat.
--    Oyun eklenirken auth.uid() kontroluyle yeniden ac.
-- ---------------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.start_scrabble_game(bigint, uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.make_scrabble_move(bigint, bigint, text, text, jsonb, integer)
                                                                    FROM PUBLIC, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 5) search_path'i sabit olmayan TUM public fonksiyonlara uygula.
--    '' yerine 'public, extensions' kullaniyoruz: mevcut fonksiyonlar
--    tablolari semasiz yazdigi icin '' olsaydi bozulurdu.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT p.oid::regprocedure AS fn
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prokind = 'f'
      AND NOT EXISTS (
        SELECT 1 FROM unnest(coalesce(p.proconfig, '{}')) c
        WHERE c LIKE 'search_path=%'
      )
  LOOP
    EXECUTE format('ALTER FUNCTION %s SET search_path = public, extensions', r.fn);
  END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- 6) login_sessions: RLS acik ama policy yok (kimse erisemiyor).
--    Kullanmiyorsan asagidaki satirin yorumunu kaldirip tabloyu sil.
--    (Kolonlar: session_token, is_authenticated... eski ozel oturum sistemi
--     gibi duruyor; Supabase Auth zaten bunu yapiyor.)
-- ---------------------------------------------------------------------------
-- DROP TABLE public.login_sessions;