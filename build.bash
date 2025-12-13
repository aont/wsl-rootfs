#!/bin/bash
set -xe

IMAGENAME="$1"
TAG="$2"

if [[ -z "$IMAGENAME" || -z "$TAG" ]]; then
  echo "usage: $0 imagename tag"
  exit 1
fi

OCIPATH=~/.oci
ROOTFSPATH=~/.rootfs
IMAGEPATH=~/image

mkdir -p "$OCIPATH"
mkdir -p "$ROOTFSPATH"
mkdir -p "$IMAGEPATH"

DIGEST_LIST=$(skopeo inspect --raw docker://"$IMAGENAME":"$TAG" | jq -r '.manifests[] | select(.platform.architecture=="amd64") | .digest')
NUM_DIGESTS="$(echo "$DIGEST_LIST" | wc -l)"

if [[ ! "$NUM_DIGESTS" -eq 1 ]]; then
    echo "number of image is ${NUM_DIGESTS}"
    exit 1
fi

DIGEST_SHORT="${DIGEST_LIST#sha256:}"
DIGEST_SHORT="${DIGEST_SHORT:0:7}"

skopeo copy docker://"$IMAGENAME":"$TAG" oci:"$OCIPATH"/"$IMAGENAME":"$TAG"
rm -rf "$ROOTFSPATH/$IMAGENAME"
umoci raw unpack --image "$OCIPATH"/"$IMAGENAME":"$TAG" "$ROOTFSPATH/$IMAGENAME"
tar czf "$IMAGEPATH"/"$IMAGENAME"_"$TAG"_"$DIGEST_SHORT".tar.gz --numeric-owner --xattrs --acls --selinux -p -C "$ROOTFSPATH/$IMAGENAME" .
