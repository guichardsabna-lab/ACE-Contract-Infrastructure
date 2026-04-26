# KYC Asset Controller (Soroban)

This folder contains starter Soroban code for controlling workflows around a
SAC (Stellar Asset Contract) that wraps your classic asset.

## What this starter does

- Stores `admin` address and `sac` address via `init`
- Exposes `get_sac()` accessor
- Includes placeholder `is_kyc_allowed(user)` logic

## Build

From `Contracts/`:

```bash
make soroban-build
```

## Next step (recommended)

Implement explicit methods that check KYC status before invoking SAC transfers.
For production, wire this to your compliance source of truth and add tests.
