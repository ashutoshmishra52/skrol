# SKROL Landing Page

Standalone marketing website for **https://skrol.in**

This is separate from the Flutter Android app. Deploy independently.

## Structure

```
website/
├── index.html      # Main landing page
├── privacy.html
├── terms.html
├── contact.html
├── css/styles.css
├── js/main.js
└── assets/         # Logo & favicon
```

## Deploy

### Vercel / Netlify
1. Connect repo
2. Set root directory to `website/`
3. Deploy

### Static hosting (Nginx, S3, Cloudflare Pages)
Upload entire `website/` folder to your host.

### Local preview
```bash
cd website
python3 -m http.server 8080
# Open http://localhost:8080
```

## APK download

Release APK lives at `downloads/android/skrol.apk`. To update:

```bash
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk website/downloads/android/skrol.apk
```

## iOS IPA

Release IPA lives at `downloads/ios/skrol.ipa`. To build and update (requires Mac + Xcode + CocoaPods):

```bash
chmod +x scripts/build_ios_website.sh
./scripts/build_ios_website.sh
```

## SEO

- `robots.txt` and `sitemap.xml` in website root
- Meta tags + Open Graph + JSON-LD on index.html
- Submit https://skrol.in/sitemap.xml in Google Search Console
