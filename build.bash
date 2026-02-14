#!/bin/bash
set -xe

IMAGENAME=""
TAG=""
OCIPATH=~/.oci
ROOTFSPATH=~/.rootfs
OUTPUT_PATH=""

usage() {
  cat <<USAGE
usage: $0 imagename tag [--ocipath path] [--rootfspath path] --output path/to/image.tar.gz
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ocipath)
      OCIPATH="$2"
      shift 2
      ;;
    --rootfspath)
      ROOTFSPATH="$2"
      shift 2
      ;;
    --output)
      OUTPUT_PATH="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      echo "unknown option: $1"
      usage
      exit 1
      ;;
    *)
      if [[ -z "$IMAGENAME" ]]; then
        IMAGENAME="$1"
      elif [[ -z "$TAG" ]]; then
        TAG="$1"
      else
        echo "too many positional arguments: $1"
        usage
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$IMAGENAME" || -z "$TAG" || -z "$OUTPUT_PATH" ]]; then
  usage
  exit 1
fi

mkdir -p "$OCIPATH"
mkdir -p "$ROOTFSPATH"
mkdir -p "$(dirname "$OUTPUT_PATH")"

DIGEST_LIST=$(skopeo inspect --raw docker://"$IMAGENAME":"$TAG" | jq -r '.manifests[] | select(.platform.architecture=="amd64") | .digest')
NUM_DIGESTS="$(echo "$DIGEST_LIST" | wc -l)"

if [[ ! "$NUM_DIGESTS" -eq 1 ]]; then
    echo "number of image is ${NUM_DIGESTS}"
    exit 1
fi


skopeo copy docker://"$IMAGENAME":"$TAG" oci:"$OCIPATH"/"$IMAGENAME":"$TAG"
rm -rf "$ROOTFSPATH/$IMAGENAME"
umoci raw unpack --image "$OCIPATH"/"$IMAGENAME":"$TAG" "$ROOTFSPATH/$IMAGENAME"
tar czf "$OUTPUT_PATH" --numeric-owner --xattrs --acls --selinux -p -C "$ROOTFSPATH/$IMAGENAME" .
