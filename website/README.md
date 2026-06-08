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

## iOS IPA (GitHub Actions — no Mac needed)

iOS builds run on GitHub cloud Mac runners: `.github/workflows/ios-build.yml`

### First release
```bash
git tag v1.0.1
git push origin v1.0.1
```

This builds the IPA and publishes it to [GitHub Releases](https://github.com/ashutoshmishra52/skrol/releases).  
The website links iPhone users to: `releases/latest/download/skrol.ipa`

### Install on iPhone (signed build required)
Add these GitHub repo secrets (Settings → Secrets → Actions):
- `IOS_CERTIFICATE_BASE64` — `.p12` distribution cert (base64)
- `IOS_CERTIFICATE_PASSWORD`
- `IOS_KEYCHAIN_PASSWORD` — any random string
- `IOS_PROVISIONING_PROFILE_BASE64` — provisioning profile (base64)

Without secrets, CI builds an **unsigned** IPA (artifact only — won't install on iPhone until signed).

### Manual build on Mac
```bash
./scripts/build_ios_website.sh
```

## SEO

- `robots.txt` and `sitemap.xml` in website root
- Meta tags + Open Graph + JSON-LD on index.html
- Submit https://skrol.in/sitemap.xml in Google Search Console
