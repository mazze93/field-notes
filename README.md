# mazze-lab

Interactive artifact gallery for [mazzeleczzare.com](https://mazzeleczzare.com).
Deployed to `lab.mazzeleczzare.com` via Cloudflare Pages.

## Namespaces

| Slug | Project |
|------|---------|
| `/mz` | mazzeleczzare.com — blog companions & tools |
| `/mow` | Merchants of War |
| `/gsfc` | Go South for Cunning |
| `/tdhaw` | The Devil Had a Wife |

## Structure

```
mazze-lab/
├── .github/
│   └── workflows/
│       └── deploy.yml          ← GitHub Actions pipeline
├── docs/
│   ├── setup-guide.md          ← human-readable setup + troubleshooting
│   └── setup-manifest.json     ← machine-readable equivalent
├── scripts/
│   └── new-artifact.sh         ← artifact scaffolder
├── src/
│   ├── index.html              ← gallery index (edit ARTIFACTS array here)
│   ├── mz/
│   ├── mow/
│   ├── gsfc/
│   └── tdhaw/
├── README.md
└── wrangler.toml               ← Cloudflare Pages config + security headers
```

## Quickstart

```bash
# Add a new artifact (interactive prompt)
bash scripts/new-artifact.sh

# Preview locally
npx serve src
# → http://localhost:3000

# Deploy to Cloudflare Pages
wrangler pages deploy src --project-name mazze-lab
```

## Adding an artifact manually

1. Create `src/<namespace>/<slug>/index.html`
2. Add an entry to the `ARTIFACTS` array in `src/index.html`
3. Commit and push — Cloudflare Pages deploys automatically on push to `main`

## First deploy setup

```bash
npm install -g wrangler
wrangler login
wrangler pages project create mazze-lab
wrangler pages deploy src --project-name mazze-lab
```

Then in Cloudflare dashboard:
→ Pages → mazze-lab → Custom domains → Add `lab.mazzeleczzare.com`

## Documentation

| File | Purpose |
|---|---|
| `docs/setup-guide.md` | Step-by-step human-readable setup and troubleshooting |
| `docs/setup-manifest.json` | Machine-readable equivalent — same steps, JSON format for tooling |

## Conventions

- Each artifact is self-contained: one directory, one `index.html`, no shared runtime
- Cipher Gothic palette: `--cipher #1a1714`, `--vellum #f4f0e8`, `--teal #2d7a6e`, `--gold #a8862a`
- Fonts: Cormorant Garamond (display) + Martian Mono (mono)
- WCAG 2.1 AA minimum for all artifacts
- Git commits: `feat(mow): add faction-map artifact` / `fix(mz): contrast ratio on palette tool`
