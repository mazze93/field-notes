#!/usr/bin/env bash
# =============================================================================
# new-artifact.sh — Scaffold a new artifact into the mazze-lab namespace
# =============================================================================
# Creates a self-contained artifact directory under the correct namespace
# (mz, mow, gsfc, tdhaw) with a starter index.html and a README stub.
# Also prints the JS snippet to paste into src/index.html's ARTIFACTS array.
#
# Usage:   bash scripts/new-artifact.sh
# Requires: bash 4+
# Platform: macOS ARM (M-series) + Linux compatible
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# ── Constants ─────────────────────────────────────────────────────────────────
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly SRC_DIR="$REPO_ROOT/src"
readonly VALID_NAMESPACES=("mz" "mow" "gsfc" "tdhaw")
readonly VALID_TYPES=("html" "react" "game" "lore")
readonly VALID_STATUSES=("live" "wip" "soon")

# ── Color helpers (TTY-safe) ──────────────────────────────────────────────────
tty_bold="" tty_reset="" tty_green="" tty_yellow="" tty_red="" tty_teal=""
if [ -t 1 ]; then
  tty_bold="\033[1m";  tty_reset="\033[0m"
  tty_green="\033[32m"; tty_yellow="\033[33m"
  tty_red="\033[31m";   tty_teal="\033[36m"
fi
info()    { printf "${tty_green}[INFO]${tty_reset}  %s\n" "$*"; }
warn()    { printf "${tty_yellow}[WARN]${tty_reset}  %s\n" "$*"; }
err()     { printf "${tty_red}[ERROR]${tty_reset} %s\n" "$*" >&2; }
die()     { err "$*"; exit 1; }
section() { printf "\n${tty_bold}${tty_teal}▸ %s${tty_reset}\n" "$*"; }

# ── Helpers ───────────────────────────────────────────────────────────────────

# Slugify: lowercase, spaces to hyphens, strip non-alphanumeric-hyphen chars
slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-'
}

# Validate that a value is in an allowed list
in_list() {
  local needle="$1"; shift
  for item in "$@"; do [[ "$item" == "$needle" ]] && return 0; done
  return 1
}

# Prompt with inline default; writes result into caller's variable via nameref
prompt_with_default() {
  local -n _var=$1
  local prompt=$2
  local default=$3
  printf "%s [%s]: " "$prompt" "$default"
  read -r _var
  _var="${_var:-$default}"
}

# Confirm yes/no; returns 0 for y, 1 otherwise
confirm() {
  local prompt="${1:-Continue?}"
  printf "%s [y/N]: " "$prompt"
  read -r reply
  [[ "${reply,,}" == "y" ]]
}

# ── Gather inputs ─────────────────────────────────────────────────────────────
gather_inputs() {
  section "New artifact — mazze lab"

  # Namespace
  printf "\nNamespaces: %s\n" "${VALID_NAMESPACES[*]}"
  prompt_with_default NAMESPACE "Namespace" "mz"
  in_list "$NAMESPACE" "${VALID_NAMESPACES[@]}" \
    || die "Invalid namespace '$NAMESPACE'. Choose from: ${VALID_NAMESPACES[*]}"

  # Human name
  printf "\nArtifact name (human-readable, e.g. 'Faction Map'):\n"
  prompt_with_default ARTIFACT_NAME "Name" "Untitled Artifact"

  # Slug (auto from name, can override)
  local auto_slug
  auto_slug=$(slugify "$ARTIFACT_NAME")
  prompt_with_default ARTIFACT_SLUG "Slug (URL path)" "$auto_slug"
  ARTIFACT_SLUG=$(slugify "$ARTIFACT_SLUG")  # re-slugify in case user typed spaces

  # Type
  printf "\nTypes: %s\n" "${VALID_TYPES[*]}"
  prompt_with_default ARTIFACT_TYPE "Type" "html"
  in_list "$ARTIFACT_TYPE" "${VALID_TYPES[@]}" \
    || die "Invalid type '$ARTIFACT_TYPE'. Choose from: ${VALID_TYPES[*]}"

  # Description
  printf "\nShort description (shown in gallery):\n"
  prompt_with_default ARTIFACT_DESC "Description" "An interactive artifact."

  # Status
  printf "\nStatuses: %s\n" "${VALID_STATUSES[*]}"
  prompt_with_default ARTIFACT_STATUS "Status" "wip"
  in_list "$ARTIFACT_STATUS" "${VALID_STATUSES[@]}" \
    || die "Invalid status '$ARTIFACT_STATUS'. Choose from: ${VALID_STATUSES[*]}"
}

# ── Create artifact directory and files ───────────────────────────────────────
create_artifact() {
  local artifact_dir="$SRC_DIR/$NAMESPACE/$ARTIFACT_SLUG"

  [[ -d "$artifact_dir" ]] && die "Artifact already exists at $artifact_dir"

  section "Creating files"

  mkdir -p "$artifact_dir"
  info "Directory: $artifact_dir"

  # index.html
  cat > "$artifact_dir/index.html" <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="description" content="$ARTIFACT_DESC" />
  <title>$ARTIFACT_NAME · mazze lab</title>
  <style>
    /* Cipher Gothic base — extend as needed */
    :root {
      --ink:    #0e0d0b;
      --vellum: #f4f0e8;
      --cipher: #1a1714;
      --teal:   #2d7a6e;
      --coral:  #c4503a;
      --gold:   #a8862a;
      --mist:   #c8c2b8;

      --font-display: 'Cormorant Garamond', Georgia, serif;
      --font-mono:    'Martian Mono', 'Courier New', monospace;
    }

    body {
      background: var(--cipher);
      color: var(--vellum);
      font-family: var(--font-display);
      font-size: 1rem;
      line-height: 1.6;
      font-weight: 300;
      margin: 0;
      min-height: 100dvh;
      display: grid;
      place-items: center;
      padding: 2rem;
    }

    .artifact-shell {
      max-width: 720px;
      width: 100%;
    }

    .artifact-back {
      font-family: var(--font-mono);
      font-size: 0.6rem;
      letter-spacing: 0.12em;
      text-transform: uppercase;
      color: var(--teal);
      text-decoration: none;
      display: inline-block;
      margin-bottom: 2rem;
    }

    .artifact-back:hover,
    .artifact-back:focus-visible {
      color: var(--vellum);
      outline: 2px solid var(--teal);
      outline-offset: 3px;
      border-radius: 1px;
    }

    h1 {
      font-size: clamp(1.8rem, 5vw, 3rem);
      font-weight: 300;
      letter-spacing: -0.02em;
      margin-bottom: 0.5rem;
    }

    .meta {
      font-family: var(--font-mono);
      font-size: 0.6rem;
      letter-spacing: 0.1em;
      text-transform: uppercase;
      color: var(--gold);
      margin-bottom: 2rem;
    }

    main {
      /* ↓ Build your artifact here */
      border: 1px dashed rgba(200, 194, 184, 0.15);
      padding: 2rem;
      border-radius: 2px;
      color: var(--mist);
      font-style: italic;
      text-align: center;
    }
  </style>
</head>
<body>
  <div class="artifact-shell">
    <a href="/" class="artifact-back" aria-label="Back to mazze lab gallery">← mazze lab</a>
    <h1>$ARTIFACT_NAME</h1>
    <p class="meta">/$NAMESPACE/$ARTIFACT_SLUG · $ARTIFACT_TYPE</p>
    <main id="artifact-root" aria-label="$ARTIFACT_NAME interactive content">
      <p>$ARTIFACT_DESC</p>
      <p>Build here ↓</p>
    </main>
  </div>
  <script>
    // Artifact entrypoint — $ARTIFACT_NAME
    // Namespace: /$NAMESPACE · Type: $ARTIFACT_TYPE
  </script>
</body>
</html>
HTML
  info "Created: index.html"

  # README.md stub
  cat > "$artifact_dir/README.md" <<MD
# $ARTIFACT_NAME

**Namespace:** \`/$NAMESPACE\`
**Slug:** \`$ARTIFACT_SLUG\`
**Type:** $ARTIFACT_TYPE
**Status:** $ARTIFACT_STATUS

## Description

$ARTIFACT_DESC

## Local preview

\`\`\`bash
# From repo root — any static server works
npx serve src/$NAMESPACE/$ARTIFACT_SLUG
# or
python3 -m http.server --directory src/$NAMESPACE/$ARTIFACT_SLUG 8080
\`\`\`

## Notes

<!-- Add implementation notes, dependencies, accessibility decisions here -->
MD
  info "Created: README.md"
}

# ── Print registry snippet ─────────────────────────────────────────────────────
print_registry_snippet() {
  section "Add this to ARTIFACTS in src/index.html"
  printf "\n"
  printf "${tty_teal}// Paste into the ARTIFACTS array in src/index.html${tty_reset}\n"
  cat <<SNIPPET
{
  namespace: '$NAMESPACE',
  name: '$ARTIFACT_NAME',
  type: '$ARTIFACT_TYPE',
  desc: '$ARTIFACT_DESC',
  href: '/$NAMESPACE/$ARTIFACT_SLUG/',
  status: '$ARTIFACT_STATUS',
},
SNIPPET
  printf "\n"
}

# ── Summary ────────────────────────────────────────────────────────────────────
print_summary() {
  section "Done"
  printf "${tty_bold}What was created:${tty_reset}\n"
  printf "  ✓ src/%s/%s/index.html\n" "$NAMESPACE" "$ARTIFACT_SLUG"
  printf "  ✓ src/%s/%s/README.md\n"  "$NAMESPACE" "$ARTIFACT_SLUG"
  printf "\n${tty_bold}Next steps:${tty_reset}\n"
  printf "  1. Paste the registry snippet above into ARTIFACTS in src/index.html\n"
  printf "  2. Build your artifact in index.html's <main> section\n"
  printf "  3. Preview: npx serve src/%s/%s\n" "$NAMESPACE" "$ARTIFACT_SLUG"
  printf "  4. git add . && git commit -m \"feat(%s): add %s artifact\"\n\n" "$NAMESPACE" "$ARTIFACT_SLUG"
}

# ── Main ───────────────────────────────────────────────────────────────────────
main() {
  gather_inputs

  printf "\n${tty_bold}Creating:${tty_reset} /%s/%s (%s)\n" \
    "$NAMESPACE" "$ARTIFACT_SLUG" "$ARTIFACT_TYPE"

  confirm "Looks right?" || die "Aborted."

  create_artifact
  print_registry_snippet
  print_summary
}

main "$@"
