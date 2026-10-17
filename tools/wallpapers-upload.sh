#!/bin/bash

# Publish the wallpapers staged under wallpapers/<theme>/ to the maitri-assets
# bucket under their content hashes, write the release's manifest and point the
# stable channel at it. .github/workflows/wallpapers.yml runs this on a release;
# see docs/wallpapers.md.
#
#   tools/wallpapers-upload.sh [--dry-run] [--from <dir>] <tag>
#
# A real run needs the aws CLI and R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY and
# R2_ENDPOINT. --dry-run needs neither: it reads the public bucket, says what it
# would upload and prints the manifest it would publish.

set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

die() {
  echo "wallpapers-upload: $1" >&2
  exit 1
}

usage="usage: tools/wallpapers-upload.sh [--dry-run] [--from <dir>] <tag>"
dry_run=0
from="$ROOT/wallpapers"
tag=""
while (( $# > 0 )); do
  case $1 in
    --dry-run) dry_run=1 ;;
    --from)
      (( $# > 1 )) || die "$usage"
      from=$2
      shift
      ;;
    -*) die "$usage" ;;
    *)
      [[ -z $tag ]] || die "$usage"
      tag=$1
      ;;
  esac
  shift
done
[[ $tag =~ ^v[0-9][0-9A-Za-z.+-]*$ ]] || die "$usage"
[[ -d $from ]] || die "no staging directory at $from"

bucket=maitri-assets
base_url=${MAITRI_WALLPAPERS_URL:-https://maitri.cdn.k7.dev}
file_cache="public, max-age=31536000, immutable"
manifest_cache="public, max-age=60"

if (( dry_run == 0 )); then
  : "${R2_ACCESS_KEY_ID:?R2_ACCESS_KEY_ID is not set}"
  : "${R2_SECRET_ACCESS_KEY:?R2_SECRET_ACCESS_KEY is not set}"
  : "${R2_ENDPOINT:?R2_ENDPOINT is not set}"
  export AWS_ACCESS_KEY_ID=$R2_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$R2_SECRET_ACCESS_KEY AWS_DEFAULT_REGION=auto
  # aws CLI 2.23 started sending CRC checksums on every request, which R2 has
  # rejected; Cloudflare's guidance is to only send them where S3 requires one.
  export AWS_REQUEST_CHECKSUM_CALCULATION=when_required AWS_RESPONSE_CHECKSUM_VALIDATION=when_required
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

s3() {
  aws s3api --endpoint-url "$R2_ENDPOINT" "$@"
}

public_get() {
  local status
  status=$(curl -sS --max-time 60 -o "$2" -w '%{http_code}' "$base_url/$1") || die "could not reach $base_url/$1"
  if (( status == 200 )); then
    return 0
  elif (( status == 404 )); then
    return 1
  fi
  die "$base_url/$1 answered $status"
}

get() {
  local error
  if (( dry_run == 1 )); then
    public_get "$1" "$2"
    return
  fi
  error=$(s3 get-object --bucket "$bucket" --key "$1" "$2" 2>&1 >/dev/null) && return 0
  [[ $error == *NoSuchKey* || $error == *"(404)"* ]] && return 1
  die "reading $1 failed: $error"
}

exists() {
  local error
  if (( dry_run == 1 )); then
    public_get "$1" /dev/null
    return
  fi
  error=$(s3 head-object --bucket "$bucket" --key "$1" 2>&1 >/dev/null) && return 0
  [[ $error == *"(404)"* || $error == *"Not Found"* ]] && return 1
  die "checking $1 failed: $error"
}

put() {
  if (( dry_run == 1 )); then
    echo "would upload $2" >&2
    return
  fi
  s3 put-object --bucket "$bucket" --key "$2" --body "$1" --content-type "$3" --cache-control "$4" >/dev/null
  echo "uploaded $2" >&2
}

previous_release=""
if get channels/stable/manifest.json "$work/stable.json"; then
  jq -e '
    (.release | type == "string") and (.files | type == "array") and (.files | all(
      type == "object" and (.theme | type == "string") and (.sha256 | type == "string") and (.size | type == "number")
      and (.file | type == "string" and test("^themes/[a-z0-9-]+/[0-9a-f]{64}\\.[a-z0-9]+$"))
      and (. as $entry | $entry.file | startswith("themes/\($entry.theme)/\($entry.sha256)."))
    ))' "$work/stable.json" >/dev/null ||
    die "channels/stable/manifest.json is not a valid manifest; fix it before publishing over it"
  previous_release=$(jq -r '.release' "$work/stable.json")
else
  echo '{"release": "", "files": []}' >"$work/stable.json"
fi

: >"$work/added.jsonl"
shopt -s nullglob
for dir in "$from"/*/; do
  theme=$(basename "$dir")
  [[ $theme =~ ^[a-z0-9-]+$ ]] || die "$dir: theme names are lowercase letters, digits and dashes"
  [[ -d $ROOT/themes/$theme ]] || die "$dir: maitri has no $theme theme"

  for wallpaper in "$dir"*; do
    [[ -f $wallpaper && ! -L $wallpaper ]] || die "$wallpaper: only plain image files go in a theme directory"
    extension=${wallpaper##*.}
    extension=${extension,,}
    case $extension in
      jpg | jpeg)
        extension=jpg
        content_type=image/jpeg
        ;;
      png) content_type=image/png ;;
      webp) content_type=image/webp ;;
      *) die "$wallpaper: wallpapers are jpg, png or webp" ;;
    esac

    sha256=$(sha256sum "$wallpaper" | cut -d' ' -f1)
    size=$(stat -c %s "$wallpaper")
    key="themes/$theme/$sha256.$extension"

    if exists "$key"; then
      echo "already published $key ($wallpaper)" >&2
    else
      put "$wallpaper" "$key" "$content_type" "$file_cache"
    fi

    jq -nc --arg theme "$theme" --arg file "$key" --arg sha256 "$sha256" --argjson size "$size" \
      '{theme: $theme, file: $file, sha256: $sha256, size: $size}' >>"$work/added.jsonl"
  done
done

jq --arg release "$tag" --slurpfile added "$work/added.jsonl" \
  '{release: $release, files: (.files + $added | unique_by(.file) | sort_by(.theme, .file))}' \
  "$work/stable.json" >"$work/manifest.json"

release_key="releases/$tag/manifest.json"
if get "$release_key" "$work/published.json"; then
  [[ $(jq -cS '.files' "$work/published.json") == $(jq -cS '.files' "$work/manifest.json") ]] ||
    die "$release_key is already published with other files; wallpapers for a published tag are fixed, so ship them with the next release"
  echo "already published $release_key" >&2
else
  put "$work/manifest.json" "$release_key" application/json "$manifest_cache"
fi

newest=$(printf '%s\n%s\n' "$previous_release" "$tag" | sort -V | tail -n 1)
if [[ $newest == "$tag" ]]; then
  put "$work/manifest.json" channels/stable/manifest.json application/json "$manifest_cache"
else
  echo "stable is on $previous_release, newer than $tag; leaving it there" >&2
fi

cat "$work/manifest.json"
