#!/bin/bash

# This script replaces the image tag with the string from the script

set -x 

MANIFEST=${1}
IMAGE_TAG=${2}

if [ -n "${IMAGE_TAG}" ]; then
  sed -i "s/{{ image_tag }}/:${IMAGE_TAG}/" ${MANIFEST}
else
  sed -i "s/{{ image_tag }}//" ${MANIFEST}
fi

