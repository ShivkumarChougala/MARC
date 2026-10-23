# MARC website

Static marketing pages, documentation, and legal pages for getmarc.app.
The site requires Python 3.9 or later to build. It has no npm dependencies.

## Local preview

```sh
python3 build.py
python3 check.py
python3 -m http.server 8000 --directory dist
```

Open http://localhost:8000. Edit source files, then rebuild and refresh.

## Source layout

- `components/`: shared navigation, footer, and homepage sections.
- `css/styles.css`: shared marketing layout, navigation, hero, and sections.
- `css/docs.css`: documentation layout and Spotlight search.
- `css/policies.css`: Privacy and Terms reading layout.
- `css/legal.css`: license and fallback pages.
- `js/main.js`: marketing navigation, screen explorer, and motion.
- `js/docs.js`: documentation search, copy buttons, sidebar, and contents tracking.
- `js/reading.js`: reading-page entrances.
- `docs/`: individual guides. Their embedded search index includes all 12 guides.
- `assets/`: referenced screenshots, logos, icons, and ceramic backgrounds.

`build.py` expands components and fingerprints local resources. It produces
20 complete pages in `dist/`. The generated site loads its scripts directly;
it does not fetch HTML components at runtime. Build output is repeatable and
is ignored by Git. `check.py` checks local links, anchors, search-index targets,
resource references, and asset fingerprints.

## Cloudflare Pages

When this folder lives at `web/` in the MARC repository, configure:

- Root directory: `web`
- Build command: `python3 build.py && python3 check.py`
- Build output directory: `dist`

Deploy the generated output, rather than the source directory. Components are
expanded during the build, so publishing source HTML directly is unsupported.
The `_headers`, `robots.txt`, and `sitemap.xml` files are copied into output.

## Editing

Keep shared navigation and footer markup in `components/`. Keep documentation
styles in `docs.css` and policy-specific styles in `policies.css`. Update the
existing rule when changing a design rather than appending another override.
Keep keyboard focus styles and reduced-motion rules when changing interactions.
