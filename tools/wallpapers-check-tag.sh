#!/bin/bash

# Check that a tag is a maitri release tag on main before wallpapers.yml hands
# the bucket token to the uploader. Run from a checkout of main; only the tag's
# name and commit are read, nothing from its tree.
#
#   tools/wallpapers-check-tag.sh <tag>

set -euo pipefail

die() {
  echo "wallpapers-check-tag: $1" >&2
  exit 1
}

(( $# == 1 )) || die "usage: tools/wallpapers-check-tag.sh <tag>"
tag=$1

[[ $tag =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]] || die "$tag is not a release tag (vX.Y.Z or vX.Y.Z-pre)"
git fetch --quiet --no-tags origin "+refs/tags/$tag:refs/tags/$tag" 2>/dev/null || die "$tag does not exist"
commit=$(git rev-parse --verify --quiet "refs/tags/$tag^{commit}") || die "$tag does not point at a commit"
git merge-base --is-ancestor "$commit" HEAD || die "$tag is not on main"
echo "$tag is $commit, on main"
