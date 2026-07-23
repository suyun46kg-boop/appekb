import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, x-admin-key',
};

type AdminRequest = {
  action: string;
  id?: number | string;
  images?: string;
  links?: string;
  listing_id?: string;
  sort_order?: number;
  query?: string;
  image_base64?: string;
  content_type?: string;
};

function extensionForContentType(contentType: string): string {
  switch (contentType) {
    case 'image/png':
      return 'png';
    case 'image/webp':
      return 'webp';
    case 'image/gif':
      return 'gif';
    case 'image/jpeg':
    case 'image/jpg':
    default:
      return 'jpg';
  }
}

function decodeBase64Image(raw: string): Uint8Array {
  const cleaned = raw.replace(/^data:image\/[a-zA-Z0-9.+-]+;base64,/, '');
  const binary = atob(cleaned);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const adminKey = Deno.env.get('BROADCAST_ADMIN_KEY');
    const requestAdminKey = req.headers.get('x-admin-key');

    if (!adminKey || requestAdminKey !== adminKey) {
      return jsonResponse({ error: 'Unauthorized' }, 401);
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const payload = (await req.json()) as AdminRequest;
    const action = payload.action?.trim();

    if (!action) {
      return jsonResponse({ error: 'action is required' }, 400);
    }

    switch (action) {
      case 'list_carousel': {
        const { data, error } = await supabase
          .from('carusel')
          .select('*')
          .order('id', { ascending: true });
        if (error) throw error;
        return jsonResponse({ items: data ?? [] });
      }

      case 'add_carousel': {
        let images = payload.images?.trim() || '';

        if (payload.image_base64?.trim()) {
          const contentType =
            payload.content_type?.trim() || 'image/jpeg';
          const bytes = decodeBase64Image(payload.image_base64.trim());
          if (bytes.byteLength === 0) {
            return jsonResponse({ error: 'empty image' }, 400);
          }
          if (bytes.byteLength > 4 * 1024 * 1024) {
            return jsonResponse(
              { error: 'image too large (max 4MB)' },
              400,
            );
          }

          const ext = extensionForContentType(contentType);
          const path = `carousel/${Date.now()}-${crypto.randomUUID()}.${ext}`;
          const { error: uploadError } = await supabase.storage
            .from('images')
            .upload(path, bytes, {
              contentType,
              upsert: false,
            });
          if (uploadError) throw uploadError;

          const { data: publicData } = supabase.storage
            .from('images')
            .getPublicUrl(path);
          images = publicData.publicUrl;
        }

        if (!images) {
          return jsonResponse(
            { error: 'images or image_base64 is required' },
            400,
          );
        }
        const { data, error } = await supabase
          .from('carusel')
          .insert({
            images,
            links: payload.links?.trim() || null,
          })
          .select()
          .single();
        if (error) throw error;
        return jsonResponse({ item: data });
      }

      case 'delete_carousel': {
        if (payload.id === undefined || payload.id === null) {
          return jsonResponse({ error: 'id is required' }, 400);
        }
        const { error } = await supabase
          .from('carusel')
          .delete()
          .eq('id', payload.id);
        if (error) throw error;
        return jsonResponse({ ok: true });
      }

      case 'list_recommendations': {
        const { data, error } = await supabase
          .from('recommendations')
          .select(
            'id, listing_id, sort_order, is_active, created_at, listings(id, title, img, price, city)',
          )
          .order('sort_order', { ascending: true });
        if (error) throw error;

        const items = (data ?? []).map((row: Record<string, unknown>) => {
          const listing = row.listings as Record<string, unknown> | null;
          return {
            id: row.id,
            listing_id: row.listing_id,
            sort_order: row.sort_order,
            is_active: row.is_active,
            created_at: row.created_at,
            title: listing?.title ?? null,
            img: listing?.img ?? null,
            price: listing?.price ?? null,
            city: listing?.city ?? null,
          };
        });
        return jsonResponse({ items });
      }

      case 'add_recommendation': {
        const listingId = payload.listing_id?.trim();
        if (!listingId) {
          return jsonResponse({ error: 'listing_id is required' }, 400);
        }
        const sortOrder =
          typeof payload.sort_order === 'number' ? payload.sort_order : 0;
        const { data, error } = await supabase
          .from('recommendations')
          .insert({
            listing_id: listingId,
            sort_order: sortOrder,
            is_active: true,
          })
          .select()
          .single();
        if (error) throw error;
        return jsonResponse({ item: data });
      }

      case 'delete_recommendation': {
        if (!payload.id) {
          return jsonResponse({ error: 'id is required' }, 400);
        }
        const { error } = await supabase
          .from('recommendations')
          .delete()
          .eq('id', payload.id);
        if (error) throw error;
        return jsonResponse({ ok: true });
      }

      case 'search_listings': {
        const q = payload.query?.trim() ?? '';
        let query = supabase
          .from('listings')
          .select('id, title, img, price, city, created_at')
          .order('created_at', { ascending: false })
          .limit(20);

        if (q) {
          query = query.ilike('title', `%${q}%`);
        }

        const { data, error } = await query;
        if (error) throw error;
        return jsonResponse({ items: data ?? [] });
      }

      case 'list_broadcasts': {
        const { data, error } = await supabase
          .from('broadcasts')
          .select('*')
          .order('created_at', { ascending: false })
          .limit(30);
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
