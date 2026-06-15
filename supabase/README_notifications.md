# Push Notifications Setup (Supabase + APNs)

## 1) SQL'i çalıştır
Supabase SQL Editor'da şu dosyayı çalıştır:

- `supabase/sql/notifications_setup.sql`

Bu işlem:
- `user_device_tokens` tablosu
- `notification_send_logs` tablosu
- RLS policy'leri
- `v_notification_audience_marketing` view
oluşturur.

## 2) Edge Function secret'larını ayarla
Supabase CLI ile:

```bash
supabase secrets set \
  APNS_KEY_ID=YOUR_KEY_ID \
  APNS_TEAM_ID=YOUR_TEAM_ID \
  APNS_BUNDLE_ID=com.mehmetfurkansakiz.Recipe-Buddy \
  APNS_ENV=sandbox \
  APNS_PRIVATE_KEY="$(cat /path/to/AuthKey_XXXX.p8)"
```

Notlar:
- `APNS_ENV=production` App Store/TestFlight için kullanılır.
- `APNS_PRIVATE_KEY` içine `.p8` dosyasının tam içeriği girilir.

## 3) Function deploy et
```bash
supabase functions deploy send-marketing-push
```

## 4) Manuel test çağrısı
```bash
curl -i \
  -X POST \
  "https://<PROJECT-REF>.functions.supabase.co/send-marketing-push" \
  -H "Authorization: Bearer <SERVICE_ROLE_OR_FUNCTION_JWT>" \
  -H "Content-Type: application/json" \
  -d '{
    "campaign_key":"welcome_week_1",
    "title":"Recipe Buddy",
    "body":"Sana özel yeni tarif önerileri var 👀",
    "limit":100
  }'
```

## 5) iOS tarafı zaten ne yapıyor?
- APNs izin akışı var.
- `device_token` alınıp local saklanıyor.
- Giriş sonrası token `user_device_tokens` tablosuna upsert ediliyor.

## 6) Üretim önerileri
- Campaign gönderimini cron ile tetikle (günde 1 veya haftada 2).
- `notification_send_logs` üzerinden başarısız tokenları izle.
- `Unregistered`/`BadDeviceToken` için `is_active=false` zaten otomatik işaretleniyor.

