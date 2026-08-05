# ACE Contracts

Utilities and starter smart-contract code for issuing an ACE-branded Stellar asset and controlling it through a Soroban KYC wrapper.

The repository currently contains two parts:

- **Classic Stellar asset scripts** for creating an issuer/distributor flow, trustlines, authorization flags, and initial payments.
- **Soroban KYC Asset Controller** that stores an admin account and a Stellar Asset Contract (SAC) address, then exposes helper methods for balance, allowance, and transfers.

> Keep secret keys out of Git. Copy `.env.example` to `.env`, fill in local values, and source it before running deployment or onboarding commands.

## Repository layout

```text
.
├── Makefile                         # Common workflows for scripts and Soroban commands
├── scripts/
│   ├── create_classic_asset.sh       # Configure issuer flags, trustline, auth, and issuance
│   └── onboard_user_trustline.sh     # Add/authorize a user trustline and optionally send funds
└── soroban/
    └── kyc_asset/
        ├── Cargo.toml
        ├── README.md
        └── src/lib.rs                # KYC asset controller contract
```

## Prerequisites

Install the following before running the workflows:

- `stellar` CLI configured for your target network
- Rust toolchain with `cargo`
- `wasm32v1-none` Rust target for Soroban builds

Example target install:

```bash
rustup target add wasm32v1-none
```

## Configuration

Create a local environment file:

```bash
cp .env.example .env
```

Edit `.env` with your own accounts and secrets, then load it:

```bash
set -a
source .env
set +a
```

Check what the Makefile will use:

```bash
make print-env
```

Secrets are intentionally displayed only as `<set>` or `<unset/placeholder>`.

## Common workflows

### 1. Create/configure the classic asset

```bash
make classic-asset
```

This script can:

1. Set issuer authorization flags.
2. Create the distributor trustline.
3. Authorize the distributor trustline when `REQUIRE_AUTH=true`.
4. Issue the configured amount to the distributor account.

### 2. Register the Stellar Asset Contract (SAC)

```bash
make register-sac
```

Save the returned contract ID as `SAC_ID` in your local `.env`.

### 3. Build and test the Soroban controller

```bash
make soroban-build
make soroban-test
```

### 4. Deploy and initialize the controller

```bash
make contract-deploy
make contract-invoke
```

After deployment, store the new contract ID as `KYC_CONTRACT_ID` in `.env`.

### 5. Onboard a new user

```bash
make onboard-user
```

This creates the user's trustline, optionally authorizes it, and optionally sends an initial amount when `SEND_AMOUNT` is not `0`.

## Useful variables

| Variable | Purpose | Default |
| --- | --- | --- |
| `NETWORK` | Stellar network name used by the CLI | `testnet` |
| `ASSET_CODE` | Classic asset code | `ACEUSD` |
| `ISSUER_ACCOUNT` | Issuer public key or CLI alias | `alice` |
| `DIST_ACCOUNT` | Distributor public key or CLI alias | `alice2` |
| `ISSUER_SECRET` | Issuer secret/source account | placeholder |
| `DIST_SECRET` | Distributor secret/source account | placeholder |
| `SOURCE_SECRET` | Source account used for contract deploy/invoke | placeholder |
| `NEW_USER_ACCOUNT` | New user public key or CLI alias | sample public key |
| `NEW_USER_SECRET` | New user secret/source account | placeholder |
| `ISSUE_AMOUNT` | Initial issuance amount | `1000` |
| `SEND_AMOUNT` | Optional user onboarding transfer | `100` |
| `REQUIRE_AUTH` | Require issuer approval for trustlines | `true` |
| `REVOCABLE_AUTH` | Allow issuer to revoke authorization | `true` |
| `SAC_ID` | Stellar Asset Contract ID | placeholder |
| `KYC_CONTRACT_ID` | Deployed KYC controller contract ID | placeholder |

## Contract notes

The Soroban controller in `soroban/kyc_asset` is intentionally small and currently includes placeholder KYC logic:

- `init(admin, sac)` stores the admin and target SAC address.
- `set_sac(sac)` lets the admin rotate the SAC address.
- `balance(user)` and `allowance(from, spender)` read through the SAC token interface.
- `transfer(from, to, amount)` forwards a token transfer after requiring `from` authorization.
- `is_kyc_allowed(user)` currently returns `true` and should be replaced with real compliance checks before production use.

## Safety checklist

Before using this with real assets:

- Replace placeholder KYC logic with policy-backed allowlist/denylist checks.
- Add contract tests for initialization, admin-only updates, transfers, and rejected users.
- Confirm issuer flags match the compliance requirements for the asset.
- Rotate any secret that was ever committed or shared outside a secure secret manager.
- Use separate accounts for development, staging, and production.
