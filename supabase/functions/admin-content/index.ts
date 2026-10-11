import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

import {
  corsHeaders,
  isAdminRequest,
  jsonResponse,
} from '../_shared/fcm.ts';

type Body = {
  action?: string;
  id?: number | string;
  images?: string;
  links?: string;
  image_base64?: string;
  content_type?: string;
  listing_id?: string;
  sort_order?: number;
  query?: string;
  decision?: string;
  reason?: string;
};

function supabaseAdmin() {
  return createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );
}

function extFromContentType(contentType: string): string {
  if (contentType.includes('png')) return 'png';
  if (contentType.includes('webp')) return 'webp';
  if (contentType.includes('gif')) return 'gif';
  return 'jpg';
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (!isAdminRequest(req)) {
    return jsonResponse({ error: 'Unauthorized' }, 401);
  }

  try {
    const body = (await req.json()) as Body;
    const action = body.action?.trim();
    if (!action) {
      return jsonResponse({ error: 'action is required' }, 400);
    }

    const supabase = supabaseAdmin();

    switch (action) {
      case 'list_carousel': {
        const { data, error } = await supabase
          .from('carusel')
          .select('id, created_at, images, links')
          .order('id', { ascending: false });
        if (error) throw error;
        return jsonResponse({ items: data ?? [] });
      }

      case 'add_carousel': {
        let imageUrl = body.images?.trim() ?? '';
        if (body.image_base64) {
          const contentType = body.content_type || 'image/jpeg';
          const bytes = Uint8Array.from(atob(body.image_base64), (c) =>
            c.charCodeAt(0),
          );
          const path =
            `carousel/${Date.now()}_${crypto.randomUUID()}.${extFromContentType(contentType)}`;
          const { error: uploadError } = await supabase.storage
            .from('images')
            .upload(path, bytes, { contentType, upsert: false });
          if (uploadError) throw uploadError;
          imageUrl = supabase.storage.from('images').getPublicUrl(path).data
            .publicUrl;
        }
        if (!imageUrl) {
          return jsonResponse({ error: 'images or image_base64 required' }, 400);
        }
        const { error } = await supabase.from('carusel').insert({
          images: imageUrl,
          links: body.links?.trim() || null,
        });
        if (error) throw error;
        return jsonResponse({ ok: true });
      }

      case 'delete_carousel': {
        const id = Number(body.id);
        if (!Number.isFinite(id)) {
          return jsonResponse({ error: 'id is required' }, 400);
        }
        const { error } = await supabase.from('carusel').delete().eq('id', id);
        if (error) throw error;
        return jsonResponse({ ok: true });
      }

      case 'list_recommendations': {
        const { data, error } = await supabase
          .from('recommendations')
          .select(
            'id, listing_id, sort_order, is_active, created_at, listings(id, title, price, img, city)',
          )
          .order('sort_order', { ascending: true });
        if (error) throw error;
        const items = (data ?? []).map((row) => {
          const listing = (row as { listings?: Record<string, unknown> | null })
            .listings;
          return {
            id: row.id,
            listing_id: row.listing_id,
            sort_order: row.sort_order,
            is_active: row.is_active,
            created_at: row.created_at,
            title: listing?.title ?? null,
            price: listing?.price ?? null,
            img: listing?.img ?? null,
            city: listing?.city ?? null,
          };
        });
        return jsonResponse({ items });
      }

      case 'add_recommendation': {
        const listingId = body.listing_id?.trim();
        if (!listingId) {
          return jsonResponse({ error: 'listing_id is required' }, 400);
        }
        const { error } = await supabase.from('recommendations').upsert(
          {
            listing_id: listingId,
            sort_order: body.sort_order ?? 0,
            is_active: true,
          },
          { onConflict: 'listing_id' },
        );
        if (error) throw error;
        return jsonResponse({ ok: true });
      }

      case 'delete_recommendation': {
        const id = body.id?.toString();
        if (!id) {
          return jsonResponse({ error: 'id is required' }, 400);
        }
        const { error } = await supabase
          .from('recommendations')
          .delete()
          .eq('id', id);
        if (error) throw error;
        return jsonResponse({ ok: true });
      }

      case 'search_listings': {
        const q = body.query?.trim() ?? '';
        let query = supabase
          .from('listings')
          .select('id, title, price, img, city, moderation_status, created_at')
          .order('created_at', { ascending: false })
          .limit(30);
        if (q) {
          query = query.ilike('title', `%${q}%`);
        }
        const { data, error } = await query;
        if (error) throw error;
        return jsonResponse({ items: data ?? [] });
      }

      case 'list_reports': {
        const { data: listings, error } = await supabase
          .from('listings')
          .select(
            'id, title, description, price, img, city, user_name, user_id, moderation_status, report_count, moderated_at, moderation_reason, created_at',
          )
          .or('moderation_status.neq.active,report_count.gt.0')
          .order('report_count', { ascending: false })
          .limit(100);
        if (error) throw error;

        const ids = (listings ?? []).map((l) => l.id as string);
        let reportsByListing: Record<string, unknown[]> = {};
        if (ids.length > 0) {
          const { data: reports, error: reportsError } = await supabase
            .from('listing_reports')
            .select('id, listing_id, reporter_id, reason, details, created_at')
            .in('listing_id', ids.map(String))
            .order('created_at', { ascending: false });
          if (reportsError) throw reportsError;
          reportsByListing = {};
          for (const report of reports ?? []) {
            const key = String(report.listing_id);
            (reportsByListing[key] ??= []).push(report);
          }
        }

        const items = (listings ?? []).map((listing) => ({
          listing_id: listing.id,
          title: listing.title,
          description: listing.description,
          price: listing.price,
          img: listing.img,
          city: listing.city,
          user_name: listing.user_name,
          user_id: listing.user_id,
          moderation_status: listing.moderation_status,
          report_count: listing.report_count,
          moderated_at: listing.moderated_at,
          moderation_reason: listing.moderation_reason,
          created_at: listing.created_at,
          reports: reportsByListing[String(listing.id)] ?? [],
        }));
        return jsonResponse({ items });
      }

      case 'review_listing': {
        const listingId = body.listing_id?.trim();
        const decision = body.decision?.trim();
        if (!listingId || !decision) {
          return jsonResponse(
            { error: 'listing_id and decision are required' },
            400,
          );
        }
        if (decision !== 'active' && decision !== 'removed') {
          return jsonResponse({ error: 'invalid decision' }, 400);
        }
        const { error } = await supabase.rpc('admin_review_listing', {
          p_listing_id: listingId,
          p_decision: decision,
          p_reason: body.reason?.trim() || null,
        });
        if (error) {
          // Fallback if RPC signature/types differ.
          const { error: updateError } = await supabase
            .from('listings')
            .update({
              moderation_status: decision,
              moderated_at: new Date().toISOString(),
              moderation_reason: body.reason?.trim() || null,
            })
            .eq('id', listingId);
          if (updateError) throw error;
        }
        return jsonResponse({ ok: true });
      }

      case 'list_broadcasts': {
        const { data, error } = await supabase
          .from('broadcasts')
          .select(
            'id, title, body, type, link_route, image_url, sent_count, created_at',
          )
          .order('created_at', { ascending: false })
          .limit(50);
        if (error) throw error;
        return jsonResponse({ items: data ?? [] });
      }

      default:
        return jsonResponse({ error: `Unknown action: ${action}` }, 400);
    }
  } catch (error) {
    return jsonResponse({ error: `${error}` }, 500);
  }
});
