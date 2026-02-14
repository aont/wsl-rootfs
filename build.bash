#!/bin/bash
set -xe

IMAGENAME="$1"
TAG="$2"
OUTPUT_SUFFIX="$3"

if [[ -z "$IMAGENAME" || -z "$TAG" ]]; then
  echo "usage: $0 imagename tag [output_suffix]"
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

if [[ -z "$OUTPUT_SUFFIX" ]]; then
  OUTPUT_SUFFIX="$DIGEST_SHORT"
fi

IMAGE_BASENAME="${IMAGENAME##*/}"
OUTPUT_FILENAME="${IMAGE_BASENAME}_${TAG}_${OUTPUT_SUFFIX}.tar.gz"

skopeo copy docker://"$IMAGENAME":"$TAG" oci:"$OCIPATH"/"$IMAGENAME":"$TAG"
rm -rf "$ROOTFSPATH/$IMAGENAME"
umoci raw unpack --image "$OCIPATH"/"$IMAGENAME":"$TAG" "$ROOTFSPATH/$IMAGENAME"
tar czf "$IMAGEPATH"/"$OUTPUT_FILENAME" --numeric-owner --xattrs --acls --selinux -p -C "$ROOTFSPATH/$IMAGENAME" .

echo "created image archive: $IMAGEPATH/$OUTPUT_FILENAME"
