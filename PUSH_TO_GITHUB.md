# Push ToneVault to GitHub

Copy the whole `ToneVault/` folder to your computer, then run these once. The repo ships a `.gitignore`, so initialize git locally first.

```bash
cd path/to/ToneVault
git init -b main
git add -A
git commit -m "ToneVault 1.0 — offline guitar tone vault"
```

Then create the remote and push — pick **one** path.

## Path 1 — GitHub CLI (easiest)

With the [GitHub CLI](https://cli.github.com) installed and logged in (`gh auth login`):

```bash
gh repo create tonevault --public --source=. --remote=origin --push
```

That creates the repo under your account and pushes `main` in one command. Done.

## Path 2 — Plain git (create the repo in the browser)

1. Go to https://github.com/new
2. Repository name: `tonevault` · Public (or Private) · **do NOT** add a README/.gitignore/license (this repo already has them).
3. Click **Create repository**, then run:

```bash
git remote add origin https://github.com/<your-username>/tonevault.git
git push -u origin main
```

If prompted for a password, use a **Personal Access Token** (GitHub → Settings → Developer settings → Tokens), not your account password.

---

## After pushing — turn on the free privacy page (optional but needed for the App Store)

GitHub → your repo → **Settings → Pages** → Source: *Deploy from a branch* → Branch `main`, Folder `/docs` → **Save**.
After ~1 minute your Privacy Policy will be live at:

```
https://<your-username>.github.io/tonevault/privacy.html
```

Paste that URL into App Store Connect (App Information → Privacy Policy URL) and into `LegalLinks.privacyPolicy` in `ToneVault/Views/Paywall/PaywallView.swift`. Full detail in `docs/SUBMISSION.md`.
