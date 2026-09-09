#!/usr/bin/env python3
"""
build-docs.py — the documentation generator for the Polari hub.

One manifest (site/assets/docs.json) lists categories and pages. A page
with a `source` is GENERATED here from that Markdown file in the suite
(the source is the thing to edit — never the generated HTML); a page
without one is hand-written under site/docs/. For every page this script
also rewrites the static sidebar (between <!-- docs-nav --> markers) and,
on docs.html, the static category index (<!-- docs-index --> markers), so
the manifest is the single source of truth with or without JavaScript.

Dependency-free on purpose (stdlib only; the site has no build step and
must build on an air-gapped isle). The Markdown subset covered is what
the suite's docs use: ATX headings, paragraphs, fenced code, inline code,
bold/italic, links, images (as their alt text), nested bullet and
numbered lists, pipe tables, block quotes, horizontal rules.

Run from anywhere:  python3 pol-hub/build-docs.py [--check]
  --check   report what would change and exit 1 if anything is stale
"""
import html
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SUITE = os.path.dirname(HERE)
SITE = os.path.join(HERE, 'site')
MANIFEST = os.path.join(SITE, 'assets', 'docs.json')
NAV_START, NAV_END = '<!-- docs-nav -->', '<!-- /docs-nav -->'
IDX_START, IDX_END = '<!-- docs-index -->', '<!-- /docs-index -->'

# ----------------------------------------------------------------- markdown

def slug(text):
    s = re.sub(r'[^a-z0-9]+', '-', text.lower()).strip('-')
    return s or 'section'


def inline(text, links):
    """Inline Markdown → HTML (escaped). `links` resolves relative .md targets."""
    out, i = [], 0
    # protect code spans first
    parts = re.split(r'(`[^`]+`)', text)
    for part in parts:
        if part.startswith('`') and part.endswith('`') and len(part) > 1:
            out.append('<code>%s</code>' % html.escape(part[1:-1]))
            continue
        s = html.escape(part, quote=False)
        s = re.sub(r'!\[([^\]]*)\]\(([^)]+)\)', lambda m: '<em>%s</em>' % m.group(1), s)
        def link(m):
            label, target = m.group(1), m.group(2).strip()
            href = links(target)
            if href is None:
                return '%s (<code>%s</code>)' % (label, target)
            ext = ' target="_blank" rel="noopener"' if href.startswith('http') else ''
            return '<a href="%s"%s>%s</a>' % (html.escape(href, quote=True), ext, label)
        s = re.sub(r'\[([^\]]+)\]\(([^)\s]+)\)', link, s)
        s = re.sub(r'(?<![\w*])\*\*(?=\S)(.+?)(?<=\S)\*\*(?!\w)', r'<strong>\1</strong>', s)
        s = re.sub(r'(?<![\w_])__(?=\S)(.+?)(?<=\S)__(?!\w)', r'<strong>\1</strong>', s)
        s = re.sub(r'(?<![\w*])\*(?=\S)([^*]+?)(?<=\S)\*(?!\w)', r'<em>\1</em>', s)
        s = re.sub(r'(?<![\w_])_(?=\S)([^_]+?)(?<=\S)_(?!\w)', r'<em>\1</em>', s)
        s = re.sub(r'(?<![">])(https?://[^\s<)]+)', r'<a href="\1" target="_blank" rel="noopener">\1</a>', s)
        out.append(s)
    return ''.join(out)


def md_to_html(text, links, drop_first_h1=True):
    lines = text.replace('\r\n', '\n').split('\n')
    out, i, n = [], 0, len(lines)
    seen_h1 = False
    para = []
    ids = {}

    def flush_para():
        if para:
            out.append('<p>%s</p>' % inline(' '.join(x.strip() for x in para), links))
            para.clear()

    def heading_id(t):
        base = slug(re.sub(r'<[^>]+>', '', t))
        k = ids.get(base, 0); ids[base] = k + 1
        return base if k == 0 else '%s-%d' % (base, k + 1)

    while i < n:
        line = lines[i]
        stripped = line.strip()
        # fenced code
        m = re.match(r'^\s*(```+|~~~+)\s*(\w+)?', line)
        if m:
            fence = m.group(1)[0] * 3
            lang = (m.group(2) or '').lower()
            flush_para()
            buf = []
            i += 1
            while i < n and not lines[i].strip().startswith(fence):
                buf.append(lines[i]); i += 1
            i += 1
            cls = ' class="lang-%s"' % html.escape(lang) if lang else ''
            out.append('<pre><code%s>%s</code></pre>' % (cls, html.escape('\n'.join(buf))))
            continue
        # headings
        m = re.match(r'^(#{1,6})\s+(.*?)\s*#*\s*$', line)
        if m:
            flush_para()
            level, t = len(m.group(1)), m.group(2)
            if level == 1 and drop_first_h1 and not seen_h1:
                seen_h1 = True; i += 1; continue
            level = max(2, level) if drop_first_h1 else level
            t_html = inline(t, links)
            out.append('<h%d id="%s">%s</h%d>' % (level, heading_id(t), t_html, level))
            i += 1; continue
        # horizontal rule
        if re.match(r'^\s*([-*_])(\s*\1){2,}\s*$', line):
            flush_para(); out.append('<hr />'); i += 1; continue
        # table
        if stripped.startswith('|') and i + 1 < n and re.match(r'^\s*\|?\s*:?-{2,}', lines[i + 1]):
            flush_para()
            head = [c.strip() for c in stripped.strip('|').split('|')]
            i += 2
            rows = []
            while i < n and lines[i].strip().startswith('|'):
                rows.append([c.strip() for c in lines[i].strip().strip('|').split('|')]); i += 1
            out.append('<div class="tablewrap"><table class="ref"><thead><tr>%s</tr></thead><tbody>%s</tbody></table></div>' % (
                ''.join('<th>%s</th>' % inline(c, links) for c in head),
                ''.join('<tr>%s</tr>' % ''.join('<td>%s</td>' % inline(c, links) for c in r) for r in rows)))
            continue
        # block quote
        if stripped.startswith('>'):
            flush_para()
            buf = []
            while i < n and lines[i].strip().startswith('>'):
                buf.append(re.sub(r'^\s*>\s?', '', lines[i])); i += 1
            out.append('<blockquote>%s</blockquote>' % md_to_html('\n'.join(buf), links, drop_first_h1=False))
            continue
        # lists (nested by indentation)
        m = re.match(r'^(\s*)([-*+]|\d+[.)])\s+(.*)$', line)
        if m:
            flush_para()
            items = []   # (indent, ordered, text)
            while i < n:
                mm = re.match(r'^(\s*)([-*+]|\d+[.)])\s+(.*)$', lines[i])
                if mm:
                    items.append([len(mm.group(1).expandtabs(4)), mm.group(2)[0].isdigit(), mm.group(3)])
                    i += 1
                elif lines[i].strip() and items and (len(lines[i]) - len(lines[i].lstrip())) > items[-1][0]:
                    items[-1][2] += ' ' + lines[i].strip(); i += 1   # continuation line
                else:
                    break
            out.append(render_list(items, links))
            continue
        # blank
        if not stripped:
            flush_para(); i += 1; continue
        # raw html block passthrough (rare) — keep simple tags only
        if stripped.startswith('<') and re.match(r'^<(/?)(details|summary|br|p|div)', stripped):
            flush_para(); out.append(stripped); i += 1; continue
        para.append(line); i += 1
    flush_para()
    return '\n'.join(out)


def render_list(items, links):
    """Nested lists from (indent, ordered, text) rows."""
    out = []
    stack = []   # (indent, tag)
    for indent, ordered, text in items:
        tag = 'ol' if ordered else 'ul'
        while stack and indent < stack[-1][0]:
            out.append('</li></%s>' % stack.pop()[1])
        if not stack or indent > stack[-1][0]:
            stack.append((indent, tag)); out.append('<%s><li>%s' % (tag, inline(text, links)))
        else:
            out.append('</li><li>%s' % inline(text, links))
    while stack:
        out.append('</li></%s>' % stack.pop()[1])
    return ''.join(out)


# ----------------------------------------------------------------- pages

def load_manifest():
    with open(MANIFEST, encoding='utf-8') as fh:
        return json.load(fh)


def all_pages(docs):
    for cat in docs['categories']:
        for page in cat['pages']:
            yield cat, page


def nav_html(docs, current):
    parts = []
    for cat in docs['categories']:
        parts.append('<div class="col-h">%s</div>' % html.escape(cat['title']))
        for page in cat['pages']:
            cls = ' class="active"' if page['href'] == current else ''
            parts.append('<a href="%s"%s>%s</a>' % (html.escape(page['href']), cls, html.escape(page['title'])))
    return '\n        '.join(parts)


def index_html(docs):
    parts = []
    for cat in docs['categories']:
        links = ''.join('<a href="%s">%s<small>%s</small></a>' % (
            html.escape(p['href']), html.escape(p['title']), html.escape(p.get('gist', ''))) for p in cat['pages'])
        parts.append('<div class="cat"><h3>%s</h3><p class="blurb">%s</p>%s</div>' % (
            html.escape(cat['title']), html.escape(cat.get('blurb', '')), links))
    return '\n        '.join(parts)


TEMPLATE = '''<!doctype html>
<html lang="en" data-theme="">
<head>
  <meta charset="utf-8" />
  <title>Polari — {title}</title>
  <base href="/" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta name="description" content="{gist}" />
  <link rel="icon" type="image/png" href="assets/polari-mark.png" />
  <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&family=Roboto+Mono:wght@400;500&display=swap" rel="stylesheet" />
  <link rel="stylesheet" href="assets/styles.css" />
  <link rel="stylesheet" href="assets/docs.css" />
</head>
<body>
  <!-- GENERATED by pol-hub/build-docs.py from {source} — edit the source, then rerun the script. -->
  <div class="wrap">
    <div class="topbar">
      <a class="brand" href="index.html"><img src="assets/polari-mark.png" alt="" /> Polari</a>
      <nav class="navlinks">
        <a href="index.html" class="hide-sm">Home</a>
        <a href="docs.html" class="active">Docs</a>
        <button class="theme-toggle" type="button">Theme</button>
      </nav>
    </div>

    <div class="docs-layout">
      <nav class="docs-nav" data-docs-nav aria-label="Documentation">
        {nav_start}
        {nav}
        {nav_end}
      </nav>

      <article class="article">
        <span class="eyebrow">{category}</span>
        <h1>{title}</h1>
        <dl class="meta">
          <dt>Source</dt><dd><code>{source}</code> in the suite repository. This page is generated from it; edits go there.</dd>
        </dl>
{body}
        <p style="margin-top:2.5rem;"><a href="docs.html">← All documentation</a></p>
      </article>
    </div>
  </div>

  <footer>
    <div class="wrap">
      <div class="brand-foot"><img src="assets/polari-mark.png" alt="" /> Polari</div>
      <p class="foot-note">Free and <span class="em">open source</span>, GPLv3.</p>
    </div>
  </footer>
  <script src="assets/app.js"></script>
  <script src="assets/docs.js"></script>
</body>
</html>
'''


def link_resolver(docs, source_path):
    """Relative .md links that point at another listed source become page
    links; anchors and http stay; everything else renders as a path."""
    by_source = {}
    for _, p in all_pages(docs):
        if p.get('source'):
            by_source[os.path.normpath(os.path.join(SUITE, p['source']))] = p['href']
    base = os.path.dirname(os.path.join(SUITE, source_path))

    def resolve(target):
        if target.startswith(('http://', 'https://', 'mailto:')):
            return target
        if target.startswith('#'):
            return target
        path, _, frag = target.partition('#')
        abs_path = os.path.normpath(os.path.join(base, path))
        href = by_source.get(abs_path)
        if href:
            return href + ('#' + frag if frag else '')
        return None
    return resolve


def replace_between(text, start, end, inner):
    a, b = text.find(start), text.find(end)
    if a < 0 or b < 0 or b < a:
        return None
    return text[:a + len(start)] + '\n        ' + inner + '\n        ' + text[b:]


def build(check=False):
    docs = load_manifest()
    changed, stale = [], []

    def write(path, content):
        old = open(path, encoding='utf-8').read() if os.path.exists(path) else None
        if old == content:
            return
        rel = os.path.relpath(path, HERE)
        if check:
            stale.append(rel); return
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w', encoding='utf-8') as fh:
            fh.write(content)
        changed.append(rel)

    for cat, page in all_pages(docs):
        path = os.path.join(SITE, page['href'])
        if page.get('source'):
            src = os.path.join(SUITE, page['source'])
            if not os.path.isfile(src):
                print('MISSING source for %s: %s' % (page['href'], page['source']), file=sys.stderr)
                continue
            body = md_to_html(open(src, encoding='utf-8').read(), link_resolver(docs, page['source']))
            content = TEMPLATE.format(
                title=html.escape(page['title']), gist=html.escape(page.get('gist', ''), quote=True),
                source=html.escape(page['source']), category=html.escape(cat['title']),
                nav_start=NAV_START, nav=nav_html(docs, page['href']), nav_end=NAV_END, body=body)
            write(path, content)
        elif os.path.isfile(path):
            text = open(path, encoding='utf-8').read()
            new = replace_between(text, NAV_START, NAV_END, nav_html(docs, page['href']))
            if new is None:
                if page['href'] != 'docs.html':   # the index page has no sidebar by design
                    print('no nav markers in hand page %s — sidebar not updated' % page['href'], file=sys.stderr)
                new = text
            if page['href'] == 'docs.html':
                idx = replace_between(new, IDX_START, IDX_END, index_html(docs))
                if idx is None:
                    print('no index markers in docs.html', file=sys.stderr)
                else:
                    new = idx
            write(path, new)
        else:
            print('hand page missing: %s' % page['href'], file=sys.stderr)
    pages = sum(1 for _ in all_pages(docs))
    if check:
        print('%d pages in manifest; stale: %s' % (pages, stale or 'none'))
        return 1 if stale else 0
    print('%d pages in manifest; written: %d' % (pages, len(changed)))
    for c in changed:
        print('  ' + c)
    return 0


if __name__ == '__main__':
    sys.exit(build(check='--check' in sys.argv[1:]))
