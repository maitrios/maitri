#!/bin/bash

# Publish the wallpapers staged under wallpapers/<theme>/ to the maitri-assets
# bucket under their content hashes, each with a WebP preview, write the
# release's manifest and point the stable channel at it.
# .github/workflows/wallpapers.yml runs this on a release; see docs/wallpapers.md.
#
#   tools/wallpapers-upload.sh [--dry-run] [--prerelease] [--from <dir> | --tar <file>]
#     [--make-previews <dir> | --previews <dir>] <tag>
#
# Decoding an image means running image libraries on files from a release
# asset, so it never happens with the bucket token around. --make-previews
# checks the staged wallpapers, writes their previews under <dir> with vips and
# stops; it touches no network and refuses to run with a token in its
# environment. A real run takes those previews with --previews and only checks
# their names, sizes and first bytes. A dry run without --previews makes its own,
# which needs vips.
#
# A real run needs the aws CLI and R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY and
# R2_ENDPOINT. --dry-run needs neither: it reads the public bucket, says what it
# would upload and prints the manifest it would publish. --tar takes the staged
# wallpapers from a wallpapers.tar instead of a directory. --prerelease, or a tag
# with a prerelease suffix, writes only the release's manifest and leaves stable.

set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

die() {
  echo "wallpapers-upload: $1" >&2
  exit 1
}

usage="usage: tools/wallpapers-upload.sh [--dry-run] [--prerelease] [--from <dir> | --tar <file>] [--make-previews <dir> | --previews <dir>] <tag>"
dry_run=0
prerelease=0
from="$ROOT/wallpapers"
tar=""
make_previews=""
previews=""
tag=""
while (( $# > 0 )); do
  case $1 in
    --dry-run) dry_run=1 ;;
    --prerelease) prerelease=1 ;;
    --from)
      (( $# > 1 )) || die "$usage"
      from=$2
      shift
      ;;
    --tar)
      (( $# > 1 )) || die "$usage"
      tar=$2
      shift
      ;;
    --make-previews)
      (( $# > 1 )) || die "$usage"
      make_previews=$2
      shift
      ;;
    --previews)
      (( $# > 1 )) || die "$usage"
      previews=$2
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
[[ $tag =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]] || die "$usage"
[[ $tag != *-* ]] || prerelease=1
[[ -n $tar || -d $from ]] || die "no staging directory at $from"
[[ -z $tar || -f $tar ]] || die "no tar at $tar"
[[ -z $make_previews || -z $previews ]] || die "$usage"
[[ -z $previews || -d $previews ]] || die "no previews at $previews"
previews=${previews%/}

bucket=maitri-assets
base_url=${MAITRI_WALLPAPERS_URL:-https://maitri.cdn.k7.dev}
file_cache="public, max-age=31536000, immutable"
manifest_cache="public, max-age=60"
max_size=$((64 * 1024 * 1024))
max_manifest_size=1048576
max_preview_size=$((4 * 1024 * 1024))
preview_width=960
preview_options="Q=80,effort=6,keep=none"

if (( dry_run == 0 )) && [[ -z $make_previews ]]; then
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
  status=$(curl -sS --max-time 60 "${@:3}" -o "$2" -w '%{http_code}' "$base_url/$1") || die "could not reach $base_url/$1"
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
    public_get "$1" /dev/null --head
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

valid_manifest() {
  jq -e --argjson max "$max_size" '
    (.release | type == "string") and (.files | type == "array") and (.files | all(
      type == "object" and (.theme | type == "string" and test("^[a-z0-9-]+$"))
      and (.sha256 | type == "string" and test("^[0-9a-f]{64}$"))
      and (.size | type == "number" and . >= 0 and . <= $max and floor == .)
      and (.file | type == "string" and test("^themes/[a-z0-9-]+/[0-9a-f]{64}\\.(jpg|png|webp|avif)$"))
      and (. as $entry | $entry.file | startswith("themes/\($entry.theme)/\($entry.sha256)."))
      and (has("preview") == has("preview_sha256"))
      and ((has("preview") | not) or (. as $entry | $entry.preview == "themes/\($entry.theme)/\($entry.sha256).preview.webp"
        and ($entry.preview_sha256 | type == "string" and test("^[0-9a-f]{64}$"))))
    ))' "$1" >/dev/null
}

if [[ -n $tar ]]; then
  types=$(tar -tvf "$tar" | cut -c1) || die "$tar could not be read"
  [[ -z $types ]] || ! grep -qv '^[-d]$' <<<"$types" || die "$tar: only directories and plain files go in wallpapers.tar"
  from="$work/staged"
  mkdir "$from"
  tar -xf "$tar" -C "$from" --no-same-owner --no-same-permissions || die "$tar could not be unpacked"
fi

unsafe_name='[[:cntrl:]\\]'

image_type() {
  case $(od -An -tx1 -N12 "$1" | tr -d ' \n') in
    ffd8ff*) echo jpg ;;
    89504e470d0a1a0a*) echo png ;;
    52494646????????57454250) echo webp ;;
  esac
}

make_preview() {
  local error
  ln -sfn "$(realpath -- "$1")" "$work/source"
  error=$(vips thumbnail "$work/source" "$2[$preview_options]" "$preview_width" --height 10000000 --size down 2>&1) ||
    die "$1: could not be decoded to make its preview: $error"
}

make_all_previews() {
  local i
  [[ -z ${R2_ACCESS_KEY_ID:-}${R2_SECRET_ACCESS_KEY:-}${AWS_SECRET_ACCESS_KEY:-} ]] ||
    die "won't decode images with a bucket token in the environment; make the previews with --make-previews in a job without it"
  for i in "${!preview_keys[@]}"; do
    mkdir -p "$1/${preview_keys[$i]%/*}"
    make_preview "${upload_files[$i]}" "$1/${preview_keys[$i]}"
  done
}

check_preview() {
  local size
  [[ -f $1 && ! -L $1 ]] || die "$2: there is no preview for it"
  [[ $(image_type "$1") == "webp" ]] || die "$2: the preview is not a WebP"
  size=$(stat -c %s "$1")
  (( size > 0 && size <= max_preview_size )) || die "$2: the preview is $size bytes, previews are at most $max_preview_size"
}

upload_files=()
upload_keys=()
upload_types=()
preview_keys=()
upload_entries=()
shopt -s nullglob dotglob
for entry in "$from"/*; do
  [[ ${entry##*/} != "README.md" ]] || continue
  [[ -d $entry && ! -L $entry ]] || die "$entry: only theme directories go at the top of the staging directory"
  theme=${entry##*/}
  [[ $theme =~ ^[a-z0-9-]+$ ]] || die "$entry: theme names are lowercase letters, digits and dashes"
  [[ -d $ROOT/themes/$theme ]] || die "$entry: maitri has no $theme theme"

  for wallpaper in "$entry"/*; do
    [[ -f $wallpaper && ! -L $wallpaper ]] || die "$wallpaper: only plain image files go in a theme directory"
    [[ ! ${wallpaper##*/} =~ $unsafe_name ]] || die "$wallpaper: file names can't hold control characters or backslashes"
    extension=${wallpaper##*.}
    extension=${extension,,}
    [[ $extension != "jpeg" ]] || extension=jpg
    case $extension in
      jpg) content_type=image/jpeg ;;
      png) content_type=image/png ;;
      webp) content_type=image/webp ;;
      *) die "$wallpaper: wallpapers are jpg, png or webp" ;;
    esac
    [[ $(image_type "$wallpaper") == "$extension" ]] || die "$wallpaper: the file is not a $extension image"

    size=$(stat -c %s "$wallpaper")
    (( size > 0 && size <= max_size )) || die "$wallpaper: $size bytes, wallpapers are at most $max_size"
    sha256=$(sha256sum <"$wallpaper" | cut -d' ' -f1)
    [[ $sha256 =~ ^[0-9a-f]{64}$ ]] || die "$wallpaper: could not hash it"
    key="themes/$theme/$sha256.$extension"
    preview_key="themes/$theme/$sha256.preview.webp"

    upload_files+=("$wallpaper")
    upload_keys+=("$key")
    upload_types+=("$content_type")
    preview_keys+=("$preview_key")
    upload_entries+=("$(jq -nc --arg theme "$theme" --arg file "$key" --arg sha256 "$sha256" --argjson size "$size" \
      '{theme: $theme, file: $file, sha256: $sha256, size: $size}')")
  done
done

if [[ -n $make_previews ]]; then
  make_all_previews "$make_previews"
  echo "made ${#preview_keys[@]} previews in $make_previews" >&2
  exit 0
fi

if [[ -n $previews ]]; then
  declare -A expected=()
  for key in "${preview_keys[@]}"; do
    expected[$key]=1
  done
  while IFS= read -r -d '' path; do
    [[ ! -d $path || -L $path ]] || continue
    relative=${path#"$previews"/}
    [[ -f $path && ! -L $path ]] || die "$previews: $relative is not a plain file"
    [[ -n ${expected[$relative]:-} ]] || die "$previews: $relative is not the preview of a staged wallpaper"
  done < <(find "$previews" -mindepth 1 -print0)
elif (( ${#preview_keys[@]} > 0 )); then
  (( dry_run == 1 )) ||
    die "a real run takes its previews from --previews, made by --make-previews without the bucket token"
  previews="$work/previews"
  make_all_previews "$previews"
fi

previous_release=""
if get channels/stable/manifest.json "$work/stable.json"; then
  valid_manifest "$work/stable.json" ||
    die "channels/stable/manifest.json is not a valid manifest; fix it before publishing over it"
  previous_release=$(jq -r '.release' "$work/stable.json")
else
  echo '{"release": "", "files": []}' >"$work/stable.json"
fi

declare -A preview_sha256=() preview_upload=()
mkdir -p "$work/published-previews"
for key in "${preview_keys[@]}"; do
  [[ -z ${preview_sha256[$key]:-} ]] || continue
  if get "$key" "$work/published-previews/preview"; then
    check_preview "$work/published-previews/preview" "$key"
    preview_sha256[$key]=$(sha256sum <"$work/published-previews/preview" | cut -d' ' -f1)
    echo "already published $key" >&2
  else
    check_preview "$previews/$key" "$key"
    preview_sha256[$key]=$(sha256sum <"$previews/$key" | cut -d' ' -f1)
    preview_upload[$key]=1
  fi
done

: >"$work/added.jsonl"
for i in "${!upload_entries[@]}"; do
  jq -c --arg preview "${preview_keys[$i]}" --arg preview_sha256 "${preview_sha256[${preview_keys[$i]}]}" \
    '. + {preview: $preview, preview_sha256: $preview_sha256}' <<<"${upload_entries[$i]}" >>"$work/added.jsonl"
done

jq --arg release "$tag" --slurpfile added "$work/added.jsonl" \
  '{release: $release, files: (.files + $added | group_by(.file) | map(add) | sort_by(.theme, .file))}' \
  "$work/stable.json" >"$work/manifest.json"
valid_manifest "$work/manifest.json" || die "the manifest for $tag would not be valid; nothing was uploaded"
(( $(stat -c %s "$work/manifest.json") <= max_manifest_size )) ||
  die "the manifest for $tag would be over $max_manifest_size bytes, more than maitri-update-wallpapers reads; nothing was uploaded"

release_key="releases/$tag/manifest.json"
write_release=1
if get "$release_key" "$work/published.json"; then
  jq -e --slurpfile new "$work/manifest.json" \
    '(.files | map({theme, file, sha256, size})) - ($new[0].files | map({theme, file, sha256, size})) == []' \
    "$work/published.json" >/dev/null ||
    die "$release_key is already published with files this run would drop; a release's wallpapers only grow, so ship them with the next release"
  if [[ $(jq -cS '.files' "$work/published.json") == "$(jq -cS '.files' "$work/manifest.json")" ]]; then
    echo "already published $release_key" >&2
    write_release=0
  fi
fi

for i in "${!upload_keys[@]}"; do
  if exists "${upload_keys[$i]}"; then
    echo "already published ${upload_keys[$i]} (${upload_files[$i]})" >&2
  else
    put "${upload_files[$i]}" "${upload_keys[$i]}" "${upload_types[$i]}" "$file_cache"
  fi
done

for key in "${preview_keys[@]}"; do
  [[ -n ${preview_upload[$key]:-} ]] || continue
  unset "preview_upload[$key]"
  put "$previews/$key" "$key" image/webp "$file_cache"
done

(( write_release == 0 )) || put "$work/manifest.json" "$release_key" application/json "$manifest_cache"

newest=$(printf '%s\n%s\n' "$previous_release" "$tag" | sort -V | tail -n 1)
if (( prerelease == 1 )); then
  echo "$tag is a prerelease; leaving stable on $previous_release" >&2
elif [[ $newest == "$tag" ]]; then
  put "$work/manifest.json" channels/stable/manifest.json application/json "$manifest_cache"
else
  echo "stable is on $previous_release, newer than $tag; leaving it there" >&2
fi

cat "$work/manifest.json"
