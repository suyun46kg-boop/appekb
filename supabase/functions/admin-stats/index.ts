import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

import {
  corsHeaders,
  isAdminRequest,
  jsonResponse,
} from '../_shared/fcm.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (!isAdminRequest(req)) {
    return jsonResponse({ error: 'Unauthorized' }, 401);
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const { data: tokens, error: tokensError } = await supabase
      .from('device_tokens')
      .select('fcm_token, platform, user_id, category_ids, updated_at');
    if (tokensError) throw tokensError;

    const { data: categories, error: categoriesError } = await supabase
      .from('categories')
      .select('id1, name, parent_id1')
      .is('parent_id1', null)
      .order('id1');
    if (categoriesError) throw categoriesError;

    const { data: broadcasts, error: broadcastsError } = await supabase
      .from('broadcasts')
      .select('id, title, body, type, link_route, image_url, sent_count, created_at')
      .order('created_at', { ascending: false })
      .limit(30);
    if (broadcastsError) throw broadcastsError;

    const rows = tokens ?? [];
    const withSubs = rows.filter((t) => (t.category_ids?.length ?? 0) > 0);

    const byCategory = (categories ?? []).map((c) => {
      const id = Number(c.id1);
      const subscribers = rows.filter((t) =>
        Array.isArray(t.category_ids) && t.category_ids.includes(id),
      ).length;
      return {
        id,
        name: c.name as string,
        subscribers,
      };
    });

    return jsonResponse({
      totals: {
        tokens: rows.length,
        with_subscriptions: withSubs.length,
        without_subscriptions: rows.length - withSubs.length,
        android: rows.filter((t) => t.platform === 'android').length,
        ios: rows.filter((t) => t.platform === 'ios').length,
      },
      by_category: byCategory,
      recent_broadcasts: broadcasts ?? [],
    });
  } catch (error) {
    return jsonResponse({ error: `${error}` }, 500);
  }
});
