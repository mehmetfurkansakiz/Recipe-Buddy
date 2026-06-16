# 🧁 Recipe Buddy

Recipe Buddy is a SwiftUI iOS app for discovering, creating, saving, and managing recipes. It supports public recipe browsing without an account, while account-based features such as creating recipes, favorites, shopping lists, profile management, and preferences require authentication.

---

## ✨ Features

* 👀 **Guest Access**
  Public recipe discovery, search, categories, and recipe details are available without login.

* 🔐 **Authentication**
  Supabase Auth with email/password, Google, and Apple sign-in.

* 🏠 **Dynamic Home Feed**
  Featured recipes and a discover section for a rich browsing experience.

* 🔍 **Search & Category Filtering**
  Recipe search and category-based filtering.

* 📖 **Recipe Details**
  Ingredients, preparation steps, ratings, author profile links, and CloudFront-hosted images.

* 🍳 **Recipe Management**
  Account-based recipe creation, editing, and deletion.

* ❤️ **Favorites & Ratings**
  Favorites and recipe ratings for signed-in users.

* 🛒 **Shopping Lists**
  Editable shopping list items, ingredient selection, duplicate handling, and check-off states.

* 👤 **User Profiles**
  User profiles with stats, avatar support, and privacy-aware personal fields.

* ⚙️ **Settings**
  Theme, notifications, email preferences, data consent, support, and account actions.

* ☁️ **Secure Image Handling**
  Image upload/delete handled through authenticated Supabase Edge Functions instead of shipping AWS credentials in the iOS app.

---

## 🛠️ Tech Stack

* **SwiftUI**
* **Supabase**

  * Auth
  * Postgres
  * PostgREST
  * RPCs
  * Edge Functions
* **Amazon S3** for image storage
* **Amazon CloudFront** for image delivery
* **Nuke / NukeUI** for async image loading
* **Firebase Analytics and Crashlytics**
* **Swift Package Manager**

---

## 🧱 Architecture

* **MVVM** for screen-level state and business logic.
* **AppCoordinator** for app-level routing between splash, onboarding, auth, age gate, guest, and signed-in flows.
* **DataManager** as shared app state for current user data, home feed data, cached shopping lists, favorites, and profile stats.
* **Service Layer** for Supabase-backed operations:

  * `RecipeService`
  * `UserService`
  * `ShoppingListService`
  * `ImageUploaderService`
  * `NotificationPreferencesService`
  * `DeviceTokenService`
* **NotificationCenter Events** for cross-screen updates such as tab changes, recipe updates, APNs token updates, and guest-home routing.

---

## 🔓 Access Model

The app intentionally separates public and account-based features.

### Available without login

* Home feed
* Public recipe browsing
* Search
* Category filtering
* Recipe detail reading
* Ingredient viewing and local selection in recipe detail

### Requires login

* Creating recipes
* Editing/deleting owned recipes
* Favoriting recipes
* Rating recipes
* Creating shopping lists
* Adding selected recipe ingredients to shopping lists
* Profile and account settings

When a guest attempts an account-based action, the app presents a sign-in prompt instead of blocking public browsing.

---

## 🔐 Backend And Security Notes

The iOS app uses the Supabase anon key, which is safe to ship only when Row Level Security policies are configured correctly.

Image storage is intentionally routed through `supabase/functions/image-storage`:

* The app sends authenticated upload/delete requests to the Edge Function.
* AWS credentials are stored only as Supabase secrets.
* AWS access keys are not included in `Keys.plist` or the app bundle.

Public recipe details require read policies for relation tables. The repository includes:

```text
supabase/sql/public_recipe_read_policies.sql
```

This grants read access to recipe ingredients and recipe categories only for public recipes.

Notification setup docs are in:

```text
supabase/README_notifications.md
```

Image storage setup docs are in:

```text
supabase/README_image_storage.md
```

---

## 🚀 Local Setup

### Requirements

* Xcode 16 or later
* iOS simulator or physical device
* Supabase project
* S3 bucket and CloudFront distribution for images
* Firebase project if analytics/crash reporting is enabled

---

### Configure `Keys.plist`

Create `Recipe Buddy/Data/Network/Keys.plist` with only client-safe values:

```xml
<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">

<plist version="1.0">

<dict>
    <key>CloudFrontDomain</key>
    <string>https://your-cloudfront-domain.net</string>

    <key>SupabaseURL</key>
    <string>https://your-project-id.supabase.co</string>

    <key>SupabaseKey</key>
    <string>your-supabase-anon-key</string>
</dict>

</plist>
```

> Do not add AWS access keys to the iOS app.

---

## 🗄️ Supabase Setup

Apply the SQL files needed by your environment, including:

```text
supabase/sql/public_recipe_read_policies.sql
supabase/sql/notifications_setup.sql
```

Set Edge Function secrets for image storage:

```bash
supabase secrets set \
  AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY_ID \
  AWS_SECRET_ACCESS_KEY=YOUR_SECRET_ACCESS_KEY \
  AWS_REGION=eu-central-1 \
  S3_BUCKET_NAME=recipe-buddy-images
```

Deploy the image storage function:

```bash
supabase functions deploy image-storage
```

Deploy other functions as needed:

```bash
supabase functions deploy delete-auth-user
supabase functions deploy send-marketing-push
```

---

## 📱 App Store Review Notes

The app supports guest access for non-account-based features. Login is required only when the user performs account-based actions.

The app may collect birth date after account creation for account/profile setup. It does not provide parental controls, parental gates, or age assurance mechanisms.

---

## 💻 Development

Open `Recipe Buddy.xcodeproj` in Xcode and run the `Recipe Buddy` target.

Useful validation steps:

* Browse public recipes while logged out.
* Open a recipe detail while logged out and verify ingredients render.
* Select ingredients while logged out and confirm the shopping-list action shows the sign-in prompt.
* Sign in and verify recipe creation, favorites, ratings, shopping lists, and image upload.
* Sign out and verify the app returns to the guest home screen.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for details.
