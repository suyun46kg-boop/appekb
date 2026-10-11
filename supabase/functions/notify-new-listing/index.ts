import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

import {
  corsHeaders,
  isAdminRequest,
  jsonResponse,
  sendToTokens,
} from '../_shared/fcm.ts';

/// Called by the `listings` insert trigger (see supabase/category_push.sql).
/// Pushes the new listing to devices subscribed to its root category,
/// skipping the author's own devices.
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (!isAdminRequest(req)) {
    return jsonResponse({ error: 'Unauthorized' }, 401);
  }

  try {
    const { listing_id: listingId } = await req.json();
    if (!listingId) {
      return jsonResponse({ error: 'listing_id is required' }, 400);
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const { data: listing, error: listingError } = await supabase
      .from('listings')
      .select('id, title, price, city, img, category_id, user_id, moderation_status')
      .eq('id', listingId)
      .maybeSingle();
    if (listingError) {
      throw listingError;
    }
    if (!listing || listing.category_id == null) {
      return jsonResponse({ sent_count: 0, reason: 'listing or category missing' });
    }
    if (listing.moderation_status && listing.moderation_status !== 'active') {
      return jsonResponse({ sent_count: 0, reason: 'listing not active' });
    }

    // Subscriptions are stored per root category; walk up from a subcategory.
    const categoryIds = [listing.category_id as number];
    let rootName: string | null = null;
    for (let i = 0; i < 4; i++) {
      const { data: category } = await supabase
        .from('categories')
        .select('id1, name, parent_id1')
        .eq('id1', categoryIds[categoryIds.length - 1])
        .maybeSingle();
      if (!category) break;
      rootName = category.name;
      if (category.parent_id1 == null) break;
      categoryIds.push(category.parent_id1);
    }

    let query = supabase
      .from('device_tokens')
      .select('fcm_token')
      .overlaps('category_ids', categoryIds);
    if (listing.user_id) {
      query = query.or(`user_id.is.null,user_id.neq.${listing.user_id}`);
    }
    const { data: rows, error: tokensError } = await query;
    if (tokensError) {
      throw tokensError;
    }

    const tokens = (rows ?? []).map((row) => row.fcm_token as string);
    const details = [
      listing.price != null ? `${listing.price}` : null,
      listing.city,
    ].filter(Boolean).join(' · ');

    const result = await sendToTokens(supabase, tokens, {
      title: rootName ? `Новое в «${rootName}»` : 'Новое объявление',
      body: details ? `${listing.title} — ${details}` : `${listing.title}`,
      type: 'listing',
      route: `/pagpage?idproductpage=${listing.id}`,
      imageUrl: listing.img?.startsWith('http') ? listing.img : undefined,
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
