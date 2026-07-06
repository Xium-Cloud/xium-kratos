#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

BUILDER="${BUILDER:-cloud-xiumjp-xium-builder}"
IMAGE="${IMAGE:-xiumjp/xium-karats}"
TAG="${TAG:-dev}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"
DOCKERFILE="${DOCKERFILE:-.docker/Dockerfile-build}"
PUSH="${PUSH:-true}"
LATEST="${LATEST:-false}"

if [[ "${PUSH}" != "true" && "${PLATFORMS}" == *,* ]]; then
  echo "PUSH=false は単一プラットフォームの場合のみ利用できます。PLATFORMS を 1 つにしてください。" >&2
  exit 1
fi

if ! docker buildx inspect "${BUILDER}" >/dev/null 2>&1; then
  echo "Docker buildx builder '${BUILDER}' が見つかりません。" >&2
  exit 1
fi

BUILD_DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
COMMIT="$(git -C "${PROJECT_ROOT}" rev-parse --short HEAD 2>/dev/null || echo unknown)"
VERSION="${VERSION:-${TAG}}"

OUTPUT_FLAG="--push"
if [[ "${PUSH}" != "true" ]]; then
  OUTPUT_FLAG="--load"
fi

TAGS=(-t "${IMAGE}:${TAG}")
if [[ "${LATEST}" == "true" ]]; then
  TAGS+=(-t "${IMAGE}:latest")
fi

cd "${PROJECT_ROOT}"

docker buildx build \
  --builder "${BUILDER}" \
  --platform "${PLATFORMS}" \
  --file "${DOCKERFILE}" \
  --build-arg "VERSION=${VERSION}" \
  --build-arg "COMMIT=${COMMIT}" \
  --build-arg "BUILD_DATE=${BUILD_DATE}" \
  "${TAGS[@]}" \
  "${OUTPUT_FLAG}" \
  "$@" \
  .
