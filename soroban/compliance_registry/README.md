# Compliance Registry

Soroban contract that wraps common operations around a Stellar Asset Contract (SAC). It is designed as a starting point for adding compliance checks to an ACE classic asset.

## Current behavior

- `init(admin, sac)` initializes the controller once and stores the admin and SAC addresses.
- `get_admin()` returns the configured admin address.
- `get_sac()` returns the configured SAC address.
- `set_sac(sac)` lets the admin rotate the SAC address.
- `balance(user)` reads a user's SAC token balance.
- `allowance(from, spender)` reads token allowance from the SAC.
- `transfer(from, to, amount)` requires `from` authorization and forwards the transfer to the SAC.
- `is_compliance_allowed(user)` is a placeholder that currently returns `true`.
- `version()` returns a small symbolic contract version marker.

## Build

From the repository root:

```bash
make soroban-build
```

Or from this directory:

```bash
cargo build --target wasm32v1-none --release
```

## Test

```bash
make soroban-test
```

## Production TODOs

Before using this controller with real assets:

1. Replace `is_compliance_allowed` with a real allowlist, denylist, or external compliance integration.
2. Enforce compliance checks inside mutating token actions such as `transfer`.
3. Add tests for initialization, admin-only SAC rotation, happy-path transfers, and rejected users.
4. Define upgrade and incident-response procedures for admin key rotation.
5. Review every caller-facing method for expected authentication behavior.
