// ── Navbar scroll effect ──
const nav = document.getElementById('navbar');
window.addEventListener('scroll', () => {
  nav.classList.toggle('scrolled', window.scrollY > 20);
});

// ── Mobile menu ──
const hamburger = document.getElementById('hamburger');
const navLinks = document.getElementById('navLinks');
hamburger.addEventListener('click', () => {
  hamburger.classList.toggle('open');
  navLinks.classList.toggle('open');
});
navLinks.querySelectorAll('a').forEach(link => {
  link.addEventListener('click', () => {
    hamburger.classList.remove('open');
    navLinks.classList.remove('open');
  });
});

// ── Scroll-triggered animations ──
const observer = new IntersectionObserver((entries) => {
  entries.forEach((entry, i) => {
    if (entry.isIntersecting) {
      entry.target.style.transitionDelay = `${i * 0.1}s`;
      entry.target.classList.add('visible');
      observer.unobserve(entry.target);
    }
  });
}, { threshold: 0.15 });

document.querySelectorAll('.animate-on-scroll').forEach(el => observer.observe(el));

// ── Animated counters ──
const countObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (!entry.isIntersecting) return;
    const el = entry.target;
    const target = parseInt(el.dataset.count);
    if (!target) return;
    let current = 0;
    const step = Math.max(1, Math.floor(target / 60));
    const timer = setInterval(() => {
      current += step;
      if (current >= target) {
        current = target;
        clearInterval(timer);
      }
      el.textContent = current.toLocaleString() + '+';
    }, 25);
    countObserver.unobserve(el);
  });
}, { threshold: 0.5 });

document.querySelectorAll('[data-count]').forEach(el => countObserver.observe(el));

// ── Build timestamp ──
fetch('build-info.json?' + Date.now())
  .then(r => r.json())
  .then(info => {
    const d = new Date(info.timestamp);
    const formatted = d.toLocaleDateString('en-GB', {
      day: '2-digit', month: 'short', year: 'numeric'
    }) + ' · ' + d.toLocaleTimeString('en-GB', {
      hour: '2-digit', minute: '2-digit', hour12: false
    });
    const label = info.build ? `Build #${info.build}` : 'Build';
    document.getElementById('buildTimestamp').textContent = `${label}: ${formatted}`;
  })
  .catch(() => {
    document.getElementById('buildTimestamp').textContent = '';
  });

// ── Download button feedback ──
const downloadBtn = document.getElementById('downloadBtn');
downloadBtn.addEventListener('click', () => {
  const original = downloadBtn.innerHTML;
  downloadBtn.innerHTML = `
    <svg width="24" height="24" fill="currentColor" viewBox="0 0 16 16"><path d="M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0zm-3.97-3.03a.75.75 0 0 0-1.08.022L7.477 9.417 5.384 7.323a.75.75 0 0 0-1.06 1.06L6.97 11.03a.75.75 0 0 0 1.079-.02l3.992-4.99a.75.75 0 0 0-.01-1.05z"/></svg>
    Downloading...
  `;
  downloadBtn.style.pointerEvents = 'none';
  setTimeout(() => {
    downloadBtn.innerHTML = original;
    downloadBtn.style.pointerEvents = '';
  }, 3000);
});
