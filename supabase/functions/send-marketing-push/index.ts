// deno-lint-ignore-file no-explicit-any
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type AudienceRow = {
  user_id: string;
  device_token: string;
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const APNS_KEY_ID = Deno.env.get("APNS_KEY_ID")!;
const APNS_TEAM_ID = Deno.env.get("APNS_TEAM_ID")!;
const APNS_BUNDLE_ID = Deno.env.get("APNS_BUNDLE_ID")!;
const APNS_PRIVATE_KEY = Deno.env.get("APNS_PRIVATE_KEY")!; // full .p8 content
const APNS_ENV = (Deno.env.get("APNS_ENV") ?? "sandbox").toLowerCase(); // sandbox | production

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

function base64UrlEncode(input: string): string {
  return btoa(input).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function createApnsJwt(): Promise<string> {
  const header = { alg: "ES256", kid: APNS_KEY_ID };
  const claims = { iss: APNS_TEAM_ID, iat: Math.floor(Date.now() / 1000) };
  const unsigned = `${base64UrlEncode(JSON.stringify(header))}.${base64UrlEncode(JSON.stringify(claims))}`;

  const keyData = APNS_PRIVATE_KEY
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");

  const keyBytes = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    keyBytes.buffer,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    cryptoKey,
    new TextEncoder().encode(unsigned),
  );

  const sig = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");

  return `${unsigned}.${sig}`;
}

async function sendApnsPush(token: string, jwt: string, title: string, body: string) {
  const host = APNS_ENV === "production"
    ? "https://api.push.apple.com"
    : "https://api.sandbox.push.apple.com";

  const payload = {
    aps: {
      alert: { title, body },
      sound: "default",
    },
    type: "marketing",
  };

  const res = await fetch(`${host}/3/device/${token}`, {
    method: "POST",
    headers: {
      authorization: `bearer ${jwt}`,
      "apns-topic": APNS_BUNDLE_ID,
      "apns-push-type": "alert",
      "apns-priority": "10",
      "content-type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  let reason: string | null = null;
  if (!res.ok) {
    try {
      const data = await res.json();
      reason = data?.reason ?? null;
    } catch {
      reason = `HTTP_${res.status}`;
    }
  }

  return {
    ok: res.ok,
    apnsId: res.headers.get("apns-id"),
    reason,
  };
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  const body = await req.json().catch(() => ({}));
  const title = body.title ?? "Recipe Buddy";
  const message = body.body ?? "Sana özel yeni tarif önerileri var!";
  const campaignKey = body.campaign_key ?? `manual_${Date.now()}`;
  const limit = Math.min(Number(body.limit ?? 100), 1000);

  const { data: audience, error: audienceError } = await supabase
    .from("v_notification_audience_marketing")
    .select("user_id, device_token")
    .limit(limit);

  if (audienceError) {
    return new Response(JSON.stringify({ error: audienceError.message }), { status: 500 });
  }

  const rows = (audience ?? []) as AudienceRow[];
  if (rows.length === 0) {
    return new Response(JSON.stringify({ sent: 0, failed: 0, message: "No audience" }), {
      status: 200,
      headers: { "content-type": "application/json" },
    });
  }

  const jwt = await createApnsJwt();
  let sent = 0;
  let failed = 0;

  for (const row of rows) {
    const result = await sendApnsPush(row.device_token, jwt, title, message);

    await supabase.from("notification_send_logs").insert({
      user_id: row.user_id,
      device_token: row.device_token,
      campaign_key: campaignKey,
      title,
      body: message,
      status: result.ok ? "sent" : "failed",
      apns_id: result.apnsId,
      error_reason: result.reason,
    });

    if (result.ok) {
      sent += 1;
    } else {
      failed += 1;
      if (result.reason === "Unregistered" || result.reason === "BadDeviceToken") {
        await supabase
          .from("user_device_tokens")
          .update({ is_active: false })
          .eq("device_token", row.device_token);
      }
    }
  }

  return new Response(JSON.stringify({ sent, failed, total: rows.length }), {
    status: 200,
    headers: { "content-type": "application/json" },
  });
});

