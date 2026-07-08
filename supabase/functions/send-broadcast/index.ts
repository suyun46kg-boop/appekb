import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, x-admin-key',
};

type BroadcastRequest = {
  title: string;
  body: string;
  type?: 'news' | 'promo';
  link_route?: string;
  image_url?: string;
};

function base64UrlEncode(input: string): string {
  return btoa(input).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

async function getFirebaseAccessToken(
  serviceAccount: Record<string, string>,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64UrlEncode(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claimSet = base64UrlEncode(
    JSON.stringify({
      iss: serviceAccount.client_email,
      sub: serviceAccount.client_email,
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
    }),
  );

  const unsignedToken = `${header}.${claimSet}`;
  const privateKey = serviceAccount.private_key;

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(privateKey),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(unsignedToken),
  );

  const signedJwt = `${unsignedToken}.${base64UrlEncode(
    String.fromCharCode(...new Uint8Array(signature)),
  )}`;

  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: signedJwt,
    }),
  });

  const tokenJson = await tokenResponse.json();
  if (!tokenResponse.ok) {
    throw new Error(`Firebase auth failed: ${JSON.stringify(tokenJson)}`);
  }

  return tokenJson.access_token as string;
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const cleaned = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s+/g, '');
  const binary = atob(cleaned);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

async function sendFcmMessage(
  accessToken: string,
  projectId: string,
  token: string,
  payload: BroadcastRequest,
) {
  const imageUrl = payload.image_url?.trim();
  const notification: Record<string, string> = {
    title: payload.title,
    body: payload.body,
  };
  if (imageUrl) {
    notification.image = imageUrl;
  }

  const message: Record<string, unknown> = {
    token,
    notification,
    data: {
      type: payload.type ?? 'news',
      route: payload.link_route ?? '/',
      ...(imageUrl ? { image_url: imageUrl } : {}),
    },
    android: {
      priority: 'HIGH',
      notification: {
        channel_id: 'ekbkyrgyzdar_default',
        ...(imageUrl ? { image: imageUrl } : {}),
      },
    },
  };

  if (imageUrl) {
    message.apns = {
      payload: {
        aps: {
          'mutable-content': 1,
        },
      },
      fcm_options: {
        image: imageUrl,
      },
    };
  }

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ message }),
    },
  );

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(errorText);
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const adminKey = Deno.env.get('BROADCAST_ADMIN_KEY');
    const requestAdminKey = req.headers.get('x-admin-key');

    if (!adminKey || requestAdminKey !== adminKey) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const serviceAccountRaw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
    if (!serviceAccountRaw) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT is not configured');
    }

    const serviceAccount = JSON.parse(serviceAccountRaw);
    const payload = (await req.json()) as BroadcastRequest;

    if (!payload.title?.trim() || !payload.body?.trim()) {
      return new Response(JSON.stringify({ error: 'title and body are required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const { data: tokens, error: tokensError } = await supabase
      .from('device_tokens')
      .select('fcm_token');

    if (tokensError) {
      throw tokensError;
    }

    const accessToken = await getFirebaseAccessToken(serviceAccount);
    const projectId = serviceAccount.project_id as string;

    let sentCount = 0;
    const failures: string[] = [];

    for (const row of tokens ?? []) {
      try {
        await sendFcmMessage(accessToken, projectId, row.fcm_token, payload);
        sentCount += 1;
      } catch (error) {
        failures.push(`${row.fcm_token}: ${error}`);
      }
    }

    await supabase.from('broadcasts').insert({
      title: payload.title,
      body: payload.body,
      type: payload.type ?? 'news',
      link_route: payload.link_route ?? null,
      image_url: payload.image_url ?? null,
      sent_count: sentCount,
    });

    return new Response(
      JSON.stringify({
        sent_count: sentCount,
        total_tokens: tokens?.length ?? 0,
        failures,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: `${error}` }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
