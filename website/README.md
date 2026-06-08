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

Release APK lives at `downloads/skrol.apk`. To update:

```bash
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk website/downloads/skrol.apk
```

## Before launch

1. Update Play Store URL in `js/main.js` (`PLAY_STORE_URL`) when listed
2. Point `skrol.in` DNS to your host (deploy `website/` folder)
3. Enable HTTPS

## SEO

- Meta tags + Open Graph on index.html
- JSON-LD structured data (MobileApplication)
- Semantic HTML, fast load (no frameworks)
