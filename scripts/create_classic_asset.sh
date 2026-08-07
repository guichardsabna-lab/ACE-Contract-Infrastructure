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
#   CLAWBACK_ENABLED=true|false      default: false
#   ISSUE_AMOUNT=<number>            default: 1000

REQUIRE_AUTH="${REQUIRE_AUTH:-true}"
REVOCABLE_AUTH="${REVOCABLE_AUTH:-true}"
CLAWBACK_ENABLED="${CLAWBACK_ENABLED:-false}"
ISSUE_AMOUNT="${ISSUE_AMOUNT:-1000}"

require_env() {
  local name="$1"
  local value="${!name:-}"
  if [[ -z "$value" || "$value" == *_HERE ]]; then
    echo "Missing env var: $name"
    exit 1
  fi
}

for v in NETWORK ASSET_CODE ISSUER_ACCOUNT DIST_ACCOUNT DIST_SECRET ISSUER_SECRET; do
  require_env "$v"
done

if ! command -v stellar >/dev/null 2>&1; then
  echo "stellar CLI not found. Install it first."
  exit 1
fi

echo "==> Configuring issuer flags (AUTH_REQUIRED / AUTH_REVOCABLE / AUTH_CLAWBACK_ENABLED)"
if [[ "$REQUIRE_AUTH" == "true" || "$REVOCABLE_AUTH" == "true" || "$CLAWBACK_ENABLED" == "true" ]]; then
  SET_OPTION_ARGS=()
  if [[ "$REQUIRE_AUTH" == "true" ]]; then
    SET_OPTION_ARGS+=("--set-required")
  fi
  if [[ "$REVOCABLE_AUTH" == "true" ]]; then
    SET_OPTION_ARGS+=("--set-revocable")
  fi
  if [[ "$CLAWBACK_ENABLED" == "true" ]]; then
    # Clawback requires the issuer to be revocable as well.
    if [[ "$REVOCABLE_AUTH" != "true" ]]; then
      echo "CLAWBACK_ENABLED=true requires REVOCABLE_AUTH=true"
      exit 1
    fi
    SET_OPTION_ARGS+=("--set-clawback-enabled")
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
