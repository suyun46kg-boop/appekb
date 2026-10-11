import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, x-admin-key',
};

export type PushPayload = {
  title: string;
  body: string;
  type: string;
  route: string;
  imageUrl?: string;
};

export type ServiceAccount = Record<string, string>;

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

export function isAdminRequest(req: Request): boolean {
  const adminKey = Deno.env.get('BROADCAST_ADMIN_KEY');
  return !!adminKey && req.headers.get('x-admin-key') === adminKey;
}

export function loadServiceAccount(): ServiceAccount {
  const raw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
  if (!raw) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT is not configured');
  }
  return JSON.parse(raw);
}

function base64UrlEncode(input: string): string {
  return btoa(input).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
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

export async function getFirebaseAccessToken(
  serviceAccount: ServiceAccount,
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
  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(serviceAccount.private_key),
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

async function sendFcmMessage(
  accessToken: string,
  projectId: string,
  token: string,
  payload: PushPayload,
): Promise<void> {
  const imageUrl = payload.imageUrl?.trim();
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
      type: payload.type,
      route: payload.route,
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
      payload: { aps: { 'mutable-content': 1 } },
      fcm_options: { image: imageUrl },
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
    throw new Error(await response.text());
  }
}

/// Sends [payload] to every token and deletes tokens FCM reports as dead.
export async function sendToTokens(
  supabase: SupabaseClient,
  tokens: string[],
  payload: PushPayload,
): Promise<{ sentCount: number; removedCount: number; failures: string[] }> {
  if (tokens.length === 0) {
    return { sentCount: 0, removedCount: 0, failures: [] };
  }

  const serviceAccount = loadServiceAccount();
  const accessToken = await getFirebaseAccessToken(serviceAccount);
  const projectId = serviceAccount.project_id;

  let sentCount = 0;
  const failures: string[] = [];
  const deadTokens: string[] = [];

  for (const token of tokens) {
    try {
      await sendFcmMessage(accessToken, projectId, token, payload);
      sentCount += 1;
    } catch (error) {
      const text = `${error}`;
      if (text.includes('UNREGISTERED')) {
        deadTokens.push(token);
      } else {
        failures.push(`${token.slice(0, 12)}…: ${text}`);
      }
    }
  }

  if (deadTokens.length > 0) {
    await supabase.from('device_tokens').delete().in('fcm_token', deadTokens);
  }

  return { sentCount, removedCount: deadTokens.length, failures };
}
