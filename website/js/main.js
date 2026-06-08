// SKROL Landing — skrol.in

// Mobile menu
const menuBtn = document.getElementById('menuBtn');
const navLinks = document.getElementById('navLinks');

if (menuBtn && navLinks) {
  menuBtn.addEventListener('click', () => {
    navLinks.classList.toggle('open');
  });

  navLinks.querySelectorAll('a').forEach((link) => {
    link.addEventListener('click', () => navLinks.classList.remove('open'));
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

// Play Store link — update when published
const PLAY_STORE_URL = '#'; // Replace with Play Store URL
const playBtn = document.getElementById('playStoreBtn');
if (playBtn && PLAY_STORE_URL !== '#') {
  playBtn.href = PLAY_STORE_URL;
  playBtn.target = '_blank';
  playBtn.rel = 'noopener';
}
