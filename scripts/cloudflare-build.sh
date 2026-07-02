#!/usr/bin/env bash
set -euo pipefail

echo "==> Cloudflare Quartz build started"

: "${NOTES_REPO:?Missing NOTES_REPO, example: JayYuan99/high_school}"

NOTES_BRANCH="${NOTES_BRANCH:-main}"
NOTES_SOURCE_DIR="${NOTES_SOURCE_DIR:-}"

CONTENT_DIR="content"
TMP_DIR="content-tmp"

echo "==> Site repo: JayYuan99/high-school-site"
echo "==> Notes repo: ${NOTES_REPO}"
echo "==> Notes branch: ${NOTES_BRANCH}"

rm -rf "$CONTENT_DIR" "$TMP_DIR"

if [ -n "${NOTES_REPO_TOKEN:-}" ]; then
  echo "==> Clone private notes repo with token"
  git clone \
    --depth=1 \
    --branch "$NOTES_BRANCH" \
    "https://x-access-token:${NOTES_REPO_TOKEN}@github.com/${NOTES_REPO}.git" \
    "$TMP_DIR"
else
  echo "==> Clone public notes repo"
  git clone \
    --depth=1 \
    --branch "$NOTES_BRANCH" \
    "https://github.com/${NOTES_REPO}.git" \
    "$TMP_DIR"
fi

if [ -n "$NOTES_SOURCE_DIR" ]; then
  SRC_DIR="$TMP_DIR/$NOTES_SOURCE_DIR"
else
  SRC_DIR="$TMP_DIR"
fi

if [ ! -d "$SRC_DIR" ]; then
  echo "ERROR: Source directory not found: $SRC_DIR"
  exit 1
fi

mkdir -p "$CONTENT_DIR"

echo "==> Sync notes into Quartz content/"
echo "==> Source: $SRC_DIR"
echo "==> Target: $CONTENT_DIR"

rsync -av --delete \
  --exclude='.git/' \
  --exclude='.github/' \
  --exclude='.obsidian/' \
  --exclude='.trash/' \
  --exclude='.DS_Store' \
  --exclude='.claude/' \
  --exclude='.claudian/' \
  --exclude='node_modules/' \
  --exclude='public/' \
  --exclude='.quartz/' \
  --exclude='.quartz-cache/' \
  --exclude='private/' \
  "$SRC_DIR"/ "$CONTENT_DIR"/

rm -rf "$TMP_DIR"

if [ ! -f "$CONTENT_DIR/index.md" ]; then
  echo "WARNING: content/index.md not found."
  echo "Quartz can still build, but homepage may not be correct."
fi

echo "==> Install Quartz plugins"
npx quartz plugin install

echo "==> Build Quartz"
npx quartz build

echo "==> Quartz build completed"