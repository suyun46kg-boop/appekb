import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

import {
  corsHeaders,
  isAdminRequest,
  jsonResponse,
  sendToTokens,
} from '../_shared/fcm.ts';

type BroadcastRequest = {
  title: string;
  body: string;
  type?: 'news' | 'promo';
  link_route?: string;
  image_url?: string;
  /// Root category id. Omitted = admin news to everyone.
  category_id?: number;
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (!isAdminRequest(req)) {
    return jsonResponse({ error: 'Unauthorized' }, 401);
  }

  try {
    const payload = (await req.json()) as BroadcastRequest;

    if (!payload.title?.trim() || !payload.body?.trim()) {
      return jsonResponse({ error: 'title and body are required' }, 400);
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    let query = supabase.from('device_tokens').select('fcm_token');
    if (payload.category_id != null) {
      query = query.contains('category_ids', [payload.category_id]);
    }
    const { data: rows, error: tokensError } = await query;
    if (tokensError) {
      throw tokensError;
    }

    const tokens = (rows ?? []).map((row) => row.fcm_token as string);
    const result = await sendToTokens(supabase, tokens, {
      title: payload.title,
      body: payload.body,
      type: payload.type ?? 'news',
      route: payload.link_route ?? '/',
      imageUrl: payload.image_url,
    });

    await supabase.from('broadcasts').insert({
      title: payload.title,
      body: payload.body,
      type: payload.type ?? 'news',
      link_route: payload.link_route ?? null,
      image_url: payload.image_url ?? null,
      sent_count: result.sentCount,
    });

    return jsonResponse({
      sent_count: result.sentCount,
      total_tokens: tokens.length,
      removed_dead_tokens: result.removedCount,
      failures: result.failures,
    });
  } catch (error) {
    return jsonResponse({ error: `${error}` }, 500);
  }
});
