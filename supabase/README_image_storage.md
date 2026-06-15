# Image Storage Setup (Supabase Edge Function + S3)

Image upload and delete operations run through the authenticated `image-storage` Edge Function. Do not put AWS credentials in the iOS app bundle.

## 1) Set Edge Function secrets

```bash
supabase secrets set \
  AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY_ID \
  AWS_SECRET_ACCESS_KEY=YOUR_SECRET_ACCESS_KEY \
  AWS_REGION=eu-central-1 \
  S3_BUCKET_NAME=recipe-buddy-images
```

## 2) Deploy the function

```bash
supabase functions deploy image-storage
```

## 3) Required iOS config

`Keys.plist` should only contain client-safe values:

- `CloudFrontDomain`
- `SupabaseURL`
- `SupabaseKey`

