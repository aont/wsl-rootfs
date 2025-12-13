#!/bin/bash

IMAGENAME="$1"

if [[ -z "$IMAGENAME" ]]; then
  echo "usage: $0 imagename"
  exit 1
fi

skopeo list-tags docker://"$IMAGENAME" | jq -r .Tags[]
