#!/bin/bash

# Rebrand an upstream Omarchy tree into maitri. Idempotent and deterministic:
# the same input tree always yields the same output, and running it twice is a
# no-op. tools/sync-upstream.sh runs it after every upstream merge; run
# `tools/rebrand.sh --check` before committing to catch anything that slipped in.
#
#   tools/rebrand.sh [--all]        delete upstream-only files, rename paths, rewrite contents
#   tools/rebrand.sh --no-delete    rename + rewrite only (used for the initial rename commit)
#   tools/rebrand.sh --paths F...   rewrite contents of the given files only (after a hand merge)
#   tools/rebrand.sh --check        exit 1 and list offenders if any unprotected brand token remains

set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"

# A line that mentions Omarchy on purpose (attribution, "grew from Omarchy",
# an upstream command name) carries the marker `rebrand:keep` -- as an HTML
# comment in markdown, a `#` comment in shell or YAML -- and is left alone.
#
# Upstream identifiers that must survive the rename: attribution, upstream
# repos, and hosts maitri does not own. Anything else spelled "omarchy" is ours
# to rename. Keep tokens specific; "omarchy.org" also covers pkgs./mirror./learn.
PROTECTED_TOKENS=(
  'github.com/basecamp/omarchy'
  'github.com/omacom/omarchy'
  'github.com/omacom-io/omarchy'
  'omacom-io/omarchy'
  'omacom/omarchy'
  'omarchy.org'
  'omacom.io'
  'discord.gg/'
  'Heinemeier'
  # The upstream release we track, named in migrations and comments as "Omarchy 4".
  'Omarchy 4'
)

# Files whose contents are never rewritten.
CONTENT_EXCLUDE=(
  'tools/rebrand.sh'
  'tools/sync-upstream.sh'
  'LICENSE'
)

# Upstream-only files maitri does not ship. Applied on every sync so they do
# not resurrect. Globs are expanded against the index.
DELETE_LIST=(
  'bin/omarchy-upgrade-to-*'
  'test/shell.d/upgrade-to-*-test.sh'
  'manual'
  'plans'
  'default/pacman/pacman-rc.conf'
  'default/pacman/mirrorlist-rc'
  'migrations/1788112314.sh'
  'bin/omarchy-launch-discord-community'
  'bin/omarchy-upload-log'
  'applications/Basecamp.desktop'
  'applications/HEY.desktop'
  'applications/Google Contacts.desktop'
  'applications/Google Maps.desktop'
  'applications/Google Messages.desktop'
  'applications/Google Photos.desktop'
  'applications/WhatsApp.desktop'
  'applications/X.desktop'
  'applications/icons/Basecamp.png'
  'applications/icons/HEY.png'
  'applications/icons/Google Contacts.png'
  'applications/icons/Google Maps.png'
  'applications/icons/Google Messages.png'
  'applications/icons/Google Photos.png'
  'applications/icons/WhatsApp.png'
  'applications/icons/X.png'
  'bin/omarchy-webapp-handler-hey'
  'default/chromium/extensions/whatsapp-slim'
  'test/shell.d/chromium-whatsapp-slim-test.sh'
  'test/shell.d/whatsapp-slim-test.sh'
  'config/starship.toml'
  'bin/omarchy-theme-set-browser'
  'bin/omarchy-theme-set-browser-policy'
  'etc/sudoers.d/omarchy-theme-browser'
  'default/themed/chromium.theme.tpl'
  'install/config/browser-policy.sh'
  'test/shell.d/browser-policy-sudoers-test.sh'
)

# Stock upstream themes are not shipped; only maitri's own live in themes/.
KEEP_THEMES=(spark harbor orchid ember garnet amethyst daybreak)

mode=all
paths=()
while (( $# )); do
  case "$1" in
    --all) mode=all ;;
    --no-delete) mode=no-delete ;;
    --check) mode=check ;;
    --paths) mode=paths; shift; paths=("$@"); break ;;
    -h|--help) sed -n '3,12p' "$0"; exit 0 ;;
    *) echo "rebrand.sh: unknown option $1" >&2; exit 2 ;;
  esac
  shift
done

rename_segment() {
  local s=$1
  s=${s//OMARCHY/MAITRI}
  s=${s//Omarchy/maitri}
  s=${s//omarchy/maitri}
  printf '%s' "$s"
}

is_excluded() {
  local f=$1 x
  for x in "${CONTENT_EXCLUDE[@]}"; do [[ $f == "$x" ]] && return 0; done
  return 1
}

is_text() {
  grep -Iq . "$1" 2>/dev/null
}

# Perl program shared by the rewrite and the check: protect upstream tokens,
# rewrite, restore. Tokens are passed via REBRAND_PROTECT (newline separated).
PERL_REWRITE='
  BEGIN { @p = grep { length } split /\n/, $ENV{REBRAND_PROTECT}; }
  unless (/rebrand:keep/) {
    for my $i (0..$#p) { my $t = $p[$i]; s/\Q$t\E/\x01P${i}\x01/g; }
    s/OMARCHY/MAITRI/g; s/Omarchy/maitri/g; s/omarchy/maitri/g;
    for my $i (0..$#p) { my $t = $p[$i]; s/\x01P${i}\x01/$t/g; }
  }
'
export REBRAND_PROTECT
REBRAND_PROTECT=$(printf '%s\n' "${PROTECTED_TOKENS[@]}")

rewrite_file() {
  local f=$1
  is_excluded "$f" && return 0
  is_text "$f" || return 0
  grep -q -i omarchy "$f" || return 0
  perl -pi -e "$PERL_REWRITE" "$f"
}

delete_upstream_only() {
  local d name
  for d in themes/*/; do
    name=$(basename "$d")
    local keep=0 k
    for k in "${KEEP_THEMES[@]}"; do [[ $name == "$k" ]] && keep=1; done
    (( keep )) || git rm -rq --ignore-unmatch -- "$d"
  done
  local entry
  for entry in "${DELETE_LIST[@]}"; do
    git rm -rq --ignore-unmatch -- "$entry" "$(rename_segment "$entry")" 2>/dev/null || true
  done
}

rename_paths() {
  local old new dir
  # Deepest paths first so a file moves before its parent directory is emptied.
  while IFS= read -r old; do
    new=$(rename_segment "$old")
    [[ $new == "$old" ]] && continue
    dir=$(dirname -- "$new")
    mkdir -p -- "$dir"
    git mv -k -- "$old" "$new"
  done < <(git ls-files | grep -i omarchy | awk '{ print gsub("/","/") "\t" $0 }' | sort -rn | cut -f2-)
}

rewrite_all() {
  local f
  while IFS= read -r -d '' f; do
    rewrite_file "$f"
  done < <(git ls-files -z)
}

check() {
  local rc=0 f
  if git ls-files | grep -qi omarchy; then
    echo "rebrand: paths still carry the upstream brand:" >&2
    git ls-files | grep -i omarchy >&2
    rc=1
  fi
  while IFS= read -r -d '' f; do
    is_excluded "$f" && continue
    is_text "$f" || continue
    grep -q -i omarchy "$f" || continue
    if ! diff -q "$f" <(perl -pe "$PERL_REWRITE" "$f") >/dev/null; then
      echo "rebrand: unprotected brand token in $f" >&2
      rc=1
    fi
  done < <(git ls-files -z)
  (( rc == 0 )) && echo "rebrand: clean"
  return $rc
}

case "$mode" in
  all)
    delete_upstream_only
    rename_paths
    rewrite_all
    ;;
  no-delete)
    rename_paths
    rewrite_all
    ;;
  paths)
    for f in "${paths[@]}"; do rewrite_file "$f"; done
    ;;
  check)
    check
    ;;
esac
