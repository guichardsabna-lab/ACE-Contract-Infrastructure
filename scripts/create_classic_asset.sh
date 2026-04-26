#!/usr/bin/env bash
set -euo pipefail

# Required env vars:
#   NETWORK            (e.g. testnet)
#   ASSET_CODE         (e.g. ACEUSD)
#   ISSUER_ACCOUNT     (G... or configured alias)
#   DIST_ACCOUNT       (G... or configured alias)
#   DIST_SECRET        (S...; used as tx source for trustline)
#   ISSUER_SECRET      (S...; used for issuing + auth)
#
# Optional:
#   REQUIRE_AUTH=true|false          default: true
#   REVOCABLE_AUTH=true|false        default: true
#   ISSUE_AMOUNT=<number>            default: 1000

REQUIRE_AUTH="${REQUIRE_AUTH:-true}"
REVOCABLE_AUTH="${REVOCABLE_AUTH:-true}"
ISSUE_AMOUNT="${ISSUE_AMOUNT:-1000}"

for v in NETWORK ASSET_CODE ISSUER_ACCOUNT DIST_ACCOUNT DIST_SECRET ISSUER_SECRET; do
  if [[ -z "${!v:-}" ]]; then
    echo "Missing env var: $v"
    exit 1
  fi
done

if ! command -v stellar >/dev/null 2>&1; then
  echo "stellar CLI not found. Install it first."
  exit 1
fi

echo "==> Configuring issuer flags (AUTH_REQUIRED / AUTH_REVOCABLE)"
if [[ "$REQUIRE_AUTH" == "true" || "$REVOCABLE_AUTH" == "true" ]]; then
  SET_OPTION_ARGS=()
  if [[ "$REQUIRE_AUTH" == "true" ]]; then
    SET_OPTION_ARGS+=("--set-required")
  fi
  if [[ "$REVOCABLE_AUTH" == "true" ]]; then
    SET_OPTION_ARGS+=("--set-revocable")
  fi

  stellar tx new set-options \
    --source-account "$ISSUER_SECRET" \
    "${SET_OPTION_ARGS[@]}" \
    --network "$NETWORK"
fi

echo "==> Distributor trustline to ${ASSET_CODE}:${ISSUER_ACCOUNT}"
stellar tx new change-trust \
  --source-account "$DIST_SECRET" \
  --line "${ASSET_CODE}:${ISSUER_ACCOUNT}" \
  --network "$NETWORK"

if [[ "$REQUIRE_AUTH" == "true" ]]; then
  echo "==> Authorizing distributor trustline"
  stellar tx new set-trustline-flags \
    --source-account "$ISSUER_SECRET" \
    --trustor "$DIST_ACCOUNT" \
    --asset "${ASSET_CODE}:${ISSUER_ACCOUNT}" \
    --set-authorize \
    --network "$NETWORK"
fi

echo "==> Issuing ${ISSUE_AMOUNT} ${ASSET_CODE} to distributor"
stellar tx new payment \
  --source-account "$ISSUER_SECRET" \
  --destination "$DIST_ACCOUNT" \
  --asset "${ASSET_CODE}:${ISSUER_ACCOUNT}" \
  --amount "$ISSUE_AMOUNT" \
  --network "$NETWORK"

echo "Classic asset flow finished."
echo "Asset: ${ASSET_CODE}:${ISSUER_ACCOUNT}"
