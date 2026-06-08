// SKROL Landing — skrol.in

const APK_URL = 'downloads/skrol.apk';
const PLAY_STORE_URL = '';

let scrollLockCount = 0;

function lockScroll() {
  scrollLockCount += 1;
  document.body.style.overflow = 'hidden';
}

function unlockScroll() {
  scrollLockCount = Math.max(0, scrollLockCount - 1);
  if (!scrollLockCount) document.body.style.overflow = '';
}

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

// Download links
function setupDownload(el) {
  if (!el) return;
  if (!PLAY_STORE_URL) {
    el.href = APK_URL;
    el.setAttribute('download', 'skrol.apk');
  } else {
    el.href = PLAY_STORE_URL;
    el.target = '_blank';
    el.rel = 'noopener';
    el.removeAttribute('download');
  }
}

['downloadBtn', 'heroDownloadBtn', 'navDownloadBtn', 'footerDownloadBtn'].forEach((id) => {
  setupDownload(document.getElementById(id));
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
const animateTargets = document.querySelectorAll('.screen-card, .feature-card, .why-item, .insight-stat');

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
