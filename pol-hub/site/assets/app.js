// Polari hub — theme persistence + the ambient node-mesh hero.
(function () {
  var root = document.documentElement;

  // Theme: honor a stored choice; the toggle flips + persists it.
  try {
    var stored = localStorage.getItem('polari-theme');
    if (stored === 'dark' || stored === 'light') { root.setAttribute('data-theme', stored); }
  } catch (e) { /* storage unavailable — fall back to prefers-color-scheme */ }

  function currentIsDark() {
    var t = root.getAttribute('data-theme');
    if (t) { return t === 'dark'; }
    return window.matchMedia('(prefers-color-scheme: dark)').matches;
  }
  Array.prototype.forEach.call(document.querySelectorAll('.theme-toggle'), function (btn) {
    btn.addEventListener('click', function () {
      var next = currentIsDark() ? 'light' : 'dark';
      root.setAttribute('data-theme', next);
      try { localStorage.setItem('polari-theme', next); } catch (e) {}
    });
  });

  // Project links resolve per environment. The site is static, so we read a
  // runtime-config.json at load time: staging/prod mount a generated file
  // (built from PRF_URL / PSC_URL / PROD_DOMAIN by the setup scripts) over the
  // shipped default, so every environment shows a valid URL for each project.
  function applyLinks(links) {
    Array.prototype.forEach.call(document.querySelectorAll('[data-link]'), function (a) {
      var href = links && links[a.getAttribute('data-link')];
      if (!href) { return; }
      a.setAttribute('href', href);
      if (/^https?:\/\//.test(href)) { a.setAttribute('target', '_blank'); a.setAttribute('rel', 'noopener'); }
    });
  }
  fetch('assets/runtime-config.json', { cache: 'no-store' })
    .then(function (r) { return r.ok ? r.json() : null; })
    .then(function (cfg) { if (cfg) { applyLinks(cfg.links); } })
    .catch(function () { /* no config served — leave the in-page fallback hrefs */ });

  // Ambient node-mesh: Polari as a multi-node substrate. Reduced-motion -> static.
  var canvas = document.getElementById('mesh');
  if (!canvas) { return; }
  var ctx = canvas.getContext('2d');
  var reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var dpr = Math.min(window.devicePixelRatio || 1, 2), nodes = [], W = 0, H = 0, raf = null;

  function meshColor() { return getComputedStyle(root).getPropertyValue('--mesh').trim() || '33, 150, 243'; }
  function resize() {
    var host = canvas.parentElement;
    W = host.clientWidth; H = host.clientHeight;
    canvas.width = W * dpr; canvas.height = H * dpr;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    var count = Math.min(64, Math.floor(W * H / 16000));
    nodes = [];
    for (var i = 0; i < count; i++) {
      nodes.push({ x: Math.random() * W, y: Math.random() * H, vx: (Math.random() - 0.5) * 0.22, vy: (Math.random() - 0.5) * 0.22 });
    }
  }
  function frame() {
    var c = meshColor();
    ctx.clearRect(0, 0, W, H);
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i];
      if (!reduce) { n.x += n.vx; n.y += n.vy; if (n.x < 0 || n.x > W) n.vx *= -1; if (n.y < 0 || n.y > H) n.vy *= -1; }
      for (var j = i + 1; j < nodes.length; j++) {
        var m = nodes[j], d = Math.hypot(n.x - m.x, n.y - m.y);
        if (d < 132) {
          ctx.strokeStyle = 'rgba(' + c + ',' + (0.16 * (1 - d / 132)).toFixed(3) + ')';
          ctx.lineWidth = 1; ctx.beginPath(); ctx.moveTo(n.x, n.y); ctx.lineTo(m.x, m.y); ctx.stroke();
        }
      }
      ctx.fillStyle = 'rgba(' + c + ', 0.5)';
      ctx.beginPath(); ctx.arc(n.x, n.y, 1.6, 0, Math.PI * 2); ctx.fill();
    }
    if (!reduce) raf = requestAnimationFrame(frame);
  }
  function start() { if (raf) cancelAnimationFrame(raf); resize(); frame(); }
  window.addEventListener('resize', start);
  start();
})();
