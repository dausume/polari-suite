// Polari hub — documentation navigation. Reads assets/docs.json (the one
// manifest) and renders: the sidebar on every doc page (categories, pages,
// the current page marked, plus its own headings as a table of contents)
// and the category index on docs.html. Static fallbacks stay in the HTML,
// so a page reads fine without JS or without the manifest.
(function () {
  function el(tag, cls, text) {
    var e = document.createElement(tag);
    if (cls) { e.className = cls; }
    if (text) { e.textContent = text; }
    return e;
  }
  function here() {
    var p = location.pathname.replace(/^\//, '');
    return p === '' ? 'index.html' : p;
  }
  function renderNav(nav, docs) {
    nav.innerHTML = '';
    var current = here();
    docs.categories.forEach(function (cat) {
      nav.appendChild(el('div', 'col-h', cat.title));
      cat.pages.forEach(function (page) {
        var a = el('a', page.href === current ? 'active' : '', page.title);
        a.href = page.href;
        nav.appendChild(a);
      });
    });
    var heads = document.querySelectorAll('.article h2[id]');
    if (heads.length > 1) {
      var toc = el('div', 'toc');
      toc.appendChild(el('div', 'col-h', 'On this page'));
      Array.prototype.forEach.call(heads, function (h) {
        var a = el('a', '', h.textContent);
        a.href = '#' + h.id;
        toc.appendChild(a);
      });
      nav.appendChild(toc);
    }
  }
  function renderIndex(box, docs) {
    box.innerHTML = '';
    docs.categories.forEach(function (cat) {
      var c = el('div', 'cat');
      c.appendChild(el('h3', '', cat.title));
      c.appendChild(el('p', 'blurb', cat.blurb));
      cat.pages.forEach(function (page) {
        var a = el('a', '', page.title);
        a.href = page.href;
        a.appendChild(el('small', '', page.gist));
        c.appendChild(a);
      });
      box.appendChild(c);
    });
  }
  fetch('assets/docs.json', { cache: 'no-store' })
    .then(function (r) { return r.ok ? r.json() : null; })
    .then(function (docs) {
      if (!docs || !docs.categories) { return; }
      var nav = document.querySelector('.docs-nav[data-docs-nav]');
      if (nav) { renderNav(nav, docs); }
      var box = document.querySelector('.docs-index[data-docs-index]');
      if (box) { renderIndex(box, docs); }
    })
    .catch(function () { /* manifest unavailable — the static list in the page stands */ });
})();
