// SKROL Landing — skrol.in

const APK_URL = '/downloads/android/skrol.apk';
const PLAY_STORE_URL = '';
const APP_STORE_URL = '';
const IOS_COMING_SOON = true;

const PLATFORM = document.documentElement.getAttribute('data-platform') || detectPlatform();

function detectPlatform() {
  const ua = navigator.userAgent || '';
  const isIOS = /iPhone|iPad|iPod/i.test(ua)
    || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  if (isIOS) return 'ios';
  if (/android/i.test(ua)) return 'android';
  return 'other';
}

function useDirectFileLink() {
  return PLATFORM === 'android';
}

const PLATFORM_COPY = {
  android: {
    navLabel: 'Download APK',
    heroLabel: 'Download APK',
    heroNote: 'Free APK · Reels & Shorts tracking · No account',
  },
  ios: {
    navLabel: 'Coming Soon',
    heroLabel: 'Coming Soon on iOS',
    heroNote: 'iPhone app launching soon · Android available now',
  },
  other: {
    navLabel: 'Download',
    heroLabel: 'Get SKROL',
    heroNote: 'Free · No account · Data stays on device',
  },
};

let scrollLockCount = 0;

function lockScroll() {
  scrollLockCount += 1;
  document.body.style.overflow = 'hidden';
}

function unlockScroll() {
  scrollLockCount = Math.max(0, scrollLockCount - 1);
  if (!scrollLockCount) document.body.style.overflow = '';
}

function setupAndroidDownload(el) {
  if (!el) return;
  if (!PLAY_STORE_URL) {
    el.href = APK_URL;
    if (useDirectFileLink()) {
      el.removeAttribute('download');
    } else {
      el.setAttribute('download', 'skrol.apk');
    }
    el.removeAttribute('target');
    el.removeAttribute('rel');
    el.classList.remove('coming-soon-btn');
  } else {
    el.href = PLAY_STORE_URL;
    el.target = '_blank';
    el.rel = 'noopener';
    el.removeAttribute('download');
  }
}

function setupIOSComingSoon(el) {
  if (!el || el.tagName !== 'A') return;
  if (APP_STORE_URL && !IOS_COMING_SOON) {
    el.href = APP_STORE_URL;
    el.target = '_blank';
    el.rel = 'noopener';
    el.classList.remove('coming-soon-btn');
    return;
  }
  el.href = '#download';
  el.removeAttribute('download');
  el.removeAttribute('target');
  el.removeAttribute('rel');
  el.classList.add('coming-soon-btn');
}

function applyPlatformUI() {
  const copy = PLATFORM_COPY[PLATFORM] || PLATFORM_COPY.other;
  document.body.classList.add(`platform-${PLATFORM}`);

  const navBtn = document.getElementById('navDownloadBtn');
  const heroBtn = document.getElementById('heroDownloadBtn');
  const heroLabel = document.getElementById('heroDownloadLabel');
  const heroNote = document.getElementById('heroNote');
  const androidIcon = document.querySelector('.hero-dl-icon-android');
  const iosIcon = document.querySelector('.hero-dl-icon-ios');

  if (PLATFORM === 'android') {
    setupAndroidDownload(navBtn);
    setupAndroidDownload(heroBtn);
    setupAndroidDownload(document.getElementById('downloadBtn'));
    setupAndroidDownload(document.getElementById('footerDownloadBtn'));

    if (navBtn) {
      navBtn.textContent = copy.navLabel;
      navBtn.classList.add('nav-cta-android');
      navBtn.classList.remove('nav-cta-muted');
    }
    if (heroBtn) heroBtn.classList.remove('btn-coming-soon', 'btn-primary-ios');
    if (heroLabel) heroLabel.textContent = copy.heroLabel;
    if (heroNote) heroNote.textContent = copy.heroNote;
    if (androidIcon) androidIcon.hidden = false;
    if (iosIcon) iosIcon.hidden = true;

    document.getElementById('androidDownloadCard')?.classList.add('platform-highlight');
    document.getElementById('iosDownloadCard')?.classList.add('platform-muted');
  } else if (PLATFORM === 'ios') {
    if (navBtn) {
      navBtn.href = '#download';
      navBtn.textContent = copy.navLabel;
      navBtn.classList.remove('nav-cta-android', 'nav-cta-ios');
      navBtn.classList.add('nav-cta-muted');
      navBtn.removeAttribute('download');
    }
    if (heroBtn) {
      heroBtn.href = '#download';
      heroBtn.classList.add('btn-coming-soon');
      heroBtn.classList.remove('btn-primary-ios');
      heroBtn.removeAttribute('download');
    }
    if (heroLabel) heroLabel.textContent = copy.heroLabel;
    if (heroNote) heroNote.textContent = copy.heroNote;
    if (androidIcon) androidIcon.hidden = true;
    if (iosIcon) iosIcon.hidden = false;

    document.getElementById('iosDownloadCard')?.classList.add('platform-highlight');
    document.getElementById('androidDownloadCard')?.classList.add('platform-muted');
  } else {
    setupAndroidDownload(document.getElementById('downloadBtn'));
    setupAndroidDownload(document.getElementById('footerDownloadBtn'));

    if (navBtn) navBtn.href = '#download';
    if (heroBtn) {
      heroBtn.href = '#download';
      heroBtn.removeAttribute('download');
      heroBtn.classList.remove('btn-coming-soon', 'btn-primary-ios');
    }
    if (heroLabel) heroLabel.textContent = copy.heroLabel;
    if (heroNote) heroNote.textContent = copy.heroNote;
    if (androidIcon) androidIcon.hidden = false;
    if (iosIcon) iosIcon.hidden = true;
  }
}

applyPlatformUI();

// Mobile menu
const menuBtn = document.getElementById('menuBtn');
const navLinks = document.getElementById('navLinks');

function setMenuOpen(open) {
  if (!navLinks) return;
  navLinks.classList.toggle('open', open);
  if (open) lockScroll();
  else unlockScroll();
  if (menuBtn) menuBtn.setAttribute('aria-expanded', open ? 'true' : 'false');
}

if (menuBtn && navLinks) {
  menuBtn.addEventListener('click', () => setMenuOpen(!navLinks.classList.contains('open')));
  navLinks.querySelectorAll('a').forEach((link) => {
    link.addEventListener('click', () => setMenuOpen(false));
  });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && navLinks.classList.contains('open')) setMenuOpen(false);
  });
  window.addEventListener('resize', () => {
    if (window.innerWidth > 640) setMenuOpen(false);
  });
}

// FAQ accordion
document.querySelectorAll('.faq-question').forEach((btn) => {
  btn.addEventListener('click', () => {
    const item = btn.parentElement;
    const wasOpen = item.classList.contains('open');
    document.querySelectorAll('.faq-item').forEach((i) => i.classList.remove('open'));
    if (!wasOpen) item.classList.add('open');
  });
});

// Screenshot gallery + lightbox
const shotPreview = document.getElementById('shotPreview');
const shotLabel = document.getElementById('shotLabel');
const shotDesc = document.getElementById('shotDesc');
const screenCards = document.querySelectorAll('.screen-card');
const stagePreviewBtn = document.getElementById('stagePreviewBtn');
const lightbox = document.getElementById('shotLightbox');
const lightboxImg = document.getElementById('lightboxImg');
const lightboxCaption = document.getElementById('lightboxCaption');

let activeShot = {
  src: 'assets/screenshots/dashboard.png',
  label: 'Dashboard',
};

function selectScreenshot(card) {
  if (!card) return;

  screenCards.forEach((c) => c.classList.remove('active'));
  card.classList.add('active');

  const { shot, label, desc } = card.dataset;
  activeShot = { src: shot, label };

  if (shotPreview) {
    shotPreview.src = shot;
    shotPreview.alt = `SKROL ${label}`;
  }
  if (shotLabel) shotLabel.textContent = label;
  if (shotDesc) shotDesc.textContent = desc;
}

function openLightbox(src, label) {
  if (!lightbox || !lightboxImg) return;

  lightboxImg.src = src;
  lightboxImg.alt = `SKROL ${label}`;
  if (lightboxCaption) lightboxCaption.textContent = label;

  lightbox.hidden = false;
  requestAnimationFrame(() => lightbox.classList.add('open'));
  lockScroll();
}

function closeLightbox() {
  if (!lightbox) return;
  lightbox.classList.remove('open');
  lightbox.hidden = true;
  unlockScroll();
}

screenCards.forEach((card) => {
  card.addEventListener('click', () => {
    selectScreenshot(card);
    openLightbox(card.dataset.shot, card.dataset.label);
  });
});

if (stagePreviewBtn) {
  stagePreviewBtn.addEventListener('click', () => {
    openLightbox(activeShot.src, activeShot.label);
  });
}

if (lightbox) {
  lightbox.querySelectorAll('[data-close]').forEach((el) => {
    el.addEventListener('click', closeLightbox);
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && lightbox.classList.contains('open')) closeLightbox();
  });
}

// Nav scroll
const nav = document.querySelector('.nav');
if (nav) {
  window.addEventListener('scroll', () => {
    nav.classList.toggle('scrolled', window.scrollY > 24);
  }, { passive: true });
}

// Fade-in on scroll
const observer = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) entry.target.classList.add('visible');
    });
  },
  { threshold: 0.12 }
);

const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
const animateTargets = document.querySelectorAll('.screen-card, .feature-card, .why-item, .insight-stat, .download-box.platform');

if (!prefersReducedMotion) {
  animateTargets.forEach((el) => {
    el.style.opacity = '0';
    el.style.transform = 'translateY(20px)';
    el.style.transition = 'opacity 0.5s ease, transform 0.5s ease';
    observer.observe(el);
  });
}

const style = document.createElement('style');
style.textContent = '.visible { opacity: 1 !important; transform: translateY(0) !important; }';
document.head.appendChild(style);
