# mazze-lab — Setup & Troubleshooting Guide

**Deploy target:** `lab.mazzeleczzare.com`  
**Pipeline:** GitHub push → GitHub Actions → Cloudflare Pages  
**Time to complete:** ~15 minutes (first time)

---

## Before you start

You need all four of these before the first step:

| Requirement | How to verify |
|---|---|
| GitHub account with a `mazze-lab` repo created | `git remote -v` shows `github.com` |
| Cloudflare account with `mazzeleczzare.com` as a managed zone | Log in at dash.cloudflare.com |
| Wrangler CLI installed | `wrangler --version` (need ≥ 3.0) |
| Node.js installed (for Wrangler) | `node --version` (need ≥ 18) |

Install Wrangler if you haven't:

```bash
npm install -g wrangler
```

---

## Setup steps

### Step 1 — Create the Cloudflare Pages project

Run this once. If the project already exists, skip ahead.

```bash
wrangler login         # opens browser — log in to your CF account
wrangler pages project create mazze-lab
```

You should see: `Successfully created the 'mazze-lab' project`.

---

### Step 2 — Get your Cloudflare Account ID

1. Go to [dash.cloudflare.com](https://dash.cloudflare.com)
2. Click on any zone (e.g. mazzeleczzare.com) — or go to **Workers & Pages**
3. Look at the **right sidebar** — your Account ID is a 32-character hex string

Copy it. You'll need it in Step 4.

---

### Step 3 — Create a scoped Cloudflare API token

> **Important:** Do not use your Global API Key. Create a scoped token — it limits blast radius if it ever leaks.

1. Go to [dash.cloudflare.com/profile/api-tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Click **Create Token**
3. Choose **Edit Cloudflare Workers** template — or click **Create Custom Token**
4. If custom, set:
   - **Permission:** `Cloudflare Pages` → `Edit`
   - **Account Resources:** Include → Your account
   - **Zone Resources:** All zones (or just `mazzeleczzare.com`)
5. Click **Continue to summary** → **Create Token**
6. **Copy the token immediately.** It is shown only once.

---

### Step 4 — Add secrets to GitHub

1. Go to your repo on GitHub
2. Navigate to **Settings → Secrets and variables → Actions**
3. Click **New repository secret** and add both:

| Secret name | Value |
|---|---|
| `CLOUDFLARE_API_TOKEN` | The token from Step 3 |
| `CLOUDFLARE_ACCOUNT_ID` | The Account ID from Step 2 |

Neither value should have quotes, spaces, or newlines — paste the raw string.

---

### Step 5 — Push the repository

If this is a fresh repo:

```bash
cd mazze-lab
git init
git add .
git commit -m "feat: initial mazze-lab scaffold"
git branch -M main
git remote add origin https://github.com/mazze93/mazze-lab.git
git push -u origin main
```

If the repo already exists:

```bash
git add .
git commit -m "feat: add GitHub Actions deploy workflow"
git push origin main
```

The push triggers the Action automatically.

---

### Step 6 — Watch the first deployment

1. Go to your repo on GitHub → **Actions** tab
2. You should see a workflow run called **Deploy to Cloudflare Pages** in progress
3. Click it to see live logs — the deploy step takes ~30 seconds

A successful run looks like:

```
✓ Checkout repository
✓ Verify src/ directory exists
✓ Deploy to Cloudflare Pages
  Uploading... (X files)
  Deployment complete! URL: https://mazze-lab.pages.dev
```

---

### Step 7 — Add the custom domain

1. Go to [dash.cloudflare.com](https://dash.cloudflare.com) → **Workers & Pages** → **mazze-lab**
2. Click **Custom domains** → **Set up a custom domain**
3. Enter: `lab.mazzeleczzare.com`
4. Click **Continue** → **Activate domain**

Cloudflare automatically adds a CNAME DNS record. Because `mazzeleczzare.com` is already managed by Cloudflare, propagation is usually instant.

Verify it's live:

```bash
curl -I https://lab.mazzeleczzare.com
# Look for: HTTP/2 200
```

---

## How the pipeline works day-to-day

| Event | What happens |
|---|---|
| Push to `main` | Production deploy → `lab.mazzeleczzare.com` |
| Open a pull request | Preview deploy → `https://{branch}.mazze-lab.pages.dev` |
| Merge PR to `main` | Production deploy with merged changes |
| Click "Run workflow" in Actions UI | Manual production deploy |

Pull request preview URLs are unique per branch and auto-expire when the PR closes.

---

## Adding a new artifact

```bash
bash scripts/new-artifact.sh
```

The script prompts you for namespace, name, type, description, and status — then creates the files and prints the snippet to paste into `src/index.html`. Commit and push to deploy.

---

## Troubleshooting

### Action fails: `Authentication error [code: 10000]`

**Cause:** The API token is missing, wrong, or has insufficient permissions.

**Fix:**
1. Go to GitHub → Settings → Secrets → confirm `CLOUDFLARE_API_TOKEN` exists
2. Go to [dash.cloudflare.com/profile/api-tokens](https://dash.cloudflare.com/profile/api-tokens) → confirm the token has `Cloudflare Pages — Edit` permission
3. If unsure, delete the token and create a new one following Step 3 above
4. Update the GitHub secret with the new token value

---

### Action fails: `account not found` or `account ID invalid`

**Cause:** `CLOUDFLARE_ACCOUNT_ID` secret is missing or incorrect.

**Fix:**
1. Re-copy your Account ID from the Cloudflare dashboard right sidebar
2. It must be exactly 32 hex characters — no spaces, no quotes
3. Update the GitHub secret

---

### Action fails: `Project not found`

**Cause:** The `mazze-lab` Pages project doesn't exist in Cloudflare yet.

**Fix:**

```bash
wrangler login
wrangler pages project create mazze-lab
```

Then push again to re-trigger the Action.

---

### Action fails: `src/ directory not found`

**Cause:** The `src/` directory wasn't committed, or you're on the wrong branch.

**Fix:**

```bash
git status                    # confirm src/ appears as tracked
git add src/
git commit -m "fix: include src/ directory"
git push origin main
```

---

### `lab.mazzeleczzare.com` shows DNS error

**Cause:** Custom domain not added, or DNS hasn't propagated.

**Fix:**
1. Check Cloudflare → Workers & Pages → mazze-lab → Custom domains
2. If the domain shows **Pending**, wait up to 24 hours (usually much faster on CF-managed zones)
3. If the domain isn't listed at all, follow Step 7 above

Test DNS resolution directly:

```bash
dig lab.mazzeleczzare.com CNAME
# Should show a CNAME pointing to mazze-lab.pages.dev
```

---

### Fonts or scripts blocked in browser console

**Cause:** The Content Security Policy in `wrangler.toml` doesn't allow the origin.

**Fix:** Edit the `[[headers]]` section in `wrangler.toml`:

```toml
Content-Security-Policy = "default-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://your-new-origin.com; ..."
```

Commit, push, and the new headers deploy automatically.

---

### Preview URL not working on a pull request

**Cause:** Branch name has special characters that don't translate cleanly to a subdomain.

**Fix:** Use lowercase, hyphen-only branch names: `feat/mow-faction-map` → preview URL will be `feat-mow-faction-map.mazze-lab.pages.dev`.

---

## Quick reference

```bash
# Scaffold a new artifact
bash scripts/new-artifact.sh

# Preview the gallery locally
npx serve src
# → http://localhost:3000

# Manual deploy (without git push)
wrangler pages deploy src --project-name=mazze-lab

# Check current deployment status
wrangler pages deployment list --project-name=mazze-lab

# Roll back to a previous deployment
wrangler pages deployment rollback --project-name=mazze-lab
```

---

## File map

```
mazze-lab/
├── .github/
│   └── workflows/
│       └── deploy.yml          ← GitHub Actions pipeline
├── docs/
│   ├── setup-guide.md          ← this file
│   └── setup-manifest.json     ← machine-readable version of this guide
├── scripts/
│   └── new-artifact.sh         ← artifact scaffolder
├── src/
│   ├── index.html              ← gallery index (edit ARTIFACTS array here)
│   ├── mz/                     ← mazzeleczzare.com artifacts
│   ├── mow/                    ← Merchants of War artifacts
│   ├── gsfc/                   ← Go South for Cunning artifacts
│   └── tdhaw/                  ← The Devil Had a Wife artifacts
├── README.md                   ← project overview
└── wrangler.toml               ← Cloudflare Pages config + security headers
```
