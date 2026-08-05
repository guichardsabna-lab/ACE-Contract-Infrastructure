#!/usr/bin/env bash
set -euo pipefail

# Required env vars:
#   NETWORK            (e.g. testnet)
#   ASSET_CODE         (e.g. ACEUSD)
#   ISSUER_ACCOUNT     (G... or configured alias)
#   ISSUER_SECRET      (S...; used to authorize trustline)
#   DIST_SECRET        (S...; used for optional initial transfer)
#   NEW_USER_ACCOUNT   (G... or configured alias)
#   NEW_USER_SECRET    (S...; user account signing trustline tx)
#
# Optional:
#   REQUIRE_AUTH=true|false          default: true
#   SEND_AMOUNT=<number>             default: 0

REQUIRE_AUTH="${REQUIRE_AUTH:-true}"
SEND_AMOUNT="${SEND_AMOUNT:-0}"

require_env() {
  local name="$1"
  local value="${!name:-}"
  if [[ -z "$value" || "$value" == *_HERE ]]; then
    echo "Missing env var: $name"
    exit 1
  fi
}

for v in NETWORK ASSET_CODE ISSUER_ACCOUNT ISSUER_SECRET DIST_SECRET NEW_USER_ACCOUNT NEW_USER_SECRET; do
  require_env "$v"
done

if ! command -v stellar >/dev/null 2>&1; then
  echo "stellar CLI not found. Install it first."
  exit 1
fi

ASSET="${ASSET_CODE}:${ISSUER_ACCOUNT}"

echo "==> Creating trustline for ${NEW_USER_ACCOUNT} to ${ASSET}"
stellar tx new change-trust \
  --source-account "$NEW_USER_SECRET" \
  --line "$ASSET" \
  --network "$NETWORK"

if [[ "$REQUIRE_AUTH" == "true" ]]; then
  echo "==> Authorizing trustline for ${NEW_USER_ACCOUNT}"
  stellar tx new set-trustline-flags \
    --source-account "$ISSUER_SECRET" \
    --trustor "$NEW_USER_ACCOUNT" \
    --asset "$ASSET" \
    --set-authorize \
    --network "$NETWORK"
fi

if [[ "$SEND_AMOUNT" != "0" ]]; then
  echo "==> Sending ${SEND_AMOUNT} ${ASSET_CODE} to ${NEW_USER_ACCOUNT}"
  stellar tx new payment \
    --source-account "$DIST_SECRET" \
    --destination "$NEW_USER_ACCOUNT" \
    --asset "$ASSET" \
    --amount "$SEND_AMOUNT" \
    --network "$NETWORK"
fi

echo "User onboarding flow finished."
echo "Asset: ${ASSET}"
echo "User: ${NEW_USER_ACCOUNT}"
