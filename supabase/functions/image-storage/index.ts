import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { DeleteObjectCommand, PutObjectCommand, S3Client } from "npm:@aws-sdk/client-s3";

type ImageStorageRequest = {
  action?: "upload" | "delete";
  folder?: string;
  imageBase64?: string;
  key?: string;
  contentType?: string;
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const AWS_ACCESS_KEY_ID = Deno.env.get("AWS_ACCESS_KEY_ID")!;
const AWS_SECRET_ACCESS_KEY = Deno.env.get("AWS_SECRET_ACCESS_KEY")!;
const AWS_REGION = Deno.env.get("AWS_REGION")!;
const S3_BUCKET_NAME = Deno.env.get("S3_BUCKET_NAME")!;

const allowedFolders = new Set(["public/avatar", "public/recipes"]);

const s3 = new S3Client({
  region: AWS_REGION,
  credentials: {
    accessKeyId: AWS_ACCESS_KEY_ID,
    secretAccessKey: AWS_SECRET_ACCESS_KEY,
  },
});

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "Method Not Allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return json({ error: "Missing authorization" }, 401);
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData.user) {
    return json({ error: "Unauthorized" }, 401);
  }

  const body = await req.json().catch(() => null) as ImageStorageRequest | null;
  if (!body?.action) {
    return json({ error: "Missing action" }, 400);
  }

  if (body.action === "upload") {
    return uploadImage(body);
  }

  if (body.action === "delete") {
    return deleteImage(body);
  }

  return json({ error: "Unsupported action" }, 400);
});

async function uploadImage(body: ImageStorageRequest): Promise<Response> {
  const folder = body.folder;
  if (!folder || !allowedFolders.has(folder)) {
    return json({ error: "Invalid folder" }, 400);
  }

  if (!body.imageBase64) {
    return json({ error: "Missing image data" }, 400);
  }

  const imageBytes = decodeBase64(body.imageBase64);
  if (imageBytes.byteLength > 350_000) {
    return json({ error: "Image too large" }, 413);
  }

  const key = `${folder}/${crypto.randomUUID()}.jpg`;
  await s3.send(new PutObjectCommand({
    Bucket: S3_BUCKET_NAME,
    Key: key,
    Body: imageBytes,
    ContentType: body.contentType ?? "image/jpeg",
  }));

  return json({ key });
}

async function deleteImage(body: ImageStorageRequest): Promise<Response> {
  if (!body.key || !isAllowedKey(body.key)) {
    return json({ error: "Invalid key" }, 400);
  }

  await s3.send(new DeleteObjectCommand({
    Bucket: S3_BUCKET_NAME,
    Key: body.key,
  }));

  return json({ ok: true });
}

function isAllowedKey(key: string): boolean {
  return [...allowedFolders].some((folder) => key.startsWith(`${folder}/`));
}

function decodeBase64(value: string): Uint8Array {
  const binary = atob(value);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "content-type": "application/json" },
  });
}
