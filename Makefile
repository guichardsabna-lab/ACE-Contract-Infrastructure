SHELL := /usr/bin/env bash

NETWORK ?= testnet
ASSET_CODE ?= ACEUSD
ISSUER_ACCOUNT ?= alice
DIST_ACCOUNT ?= alice2
ISSUER_SECRET ?= 
DIST_SECRET ?= SABHNOHCOVS27LOVPIB63OZFGGPT6ONNS67YU5HH3ZN4EXPIRVOSSTHC
SOURCE_SECRET ?= 
NEW_USER_ACCOUNT ?= GBCX4IVFVGSRUTN6YSVP2QLWD6WAZ5FL4GB4MUNS5GHQZGOFNUAJB5MA
NEW_USER_SECRET ?= 
ISSUE_AMOUNT ?= 1000
SEND_AMOUNT ?= 100
REQUIRE_AUTH ?= true
REVOCABLE_AUTH ?= true
SAC_ID ?= CD242MLPC2MNFU2RILWMIMBPW66RVGE7J3O7AOG7QWZUVSDABV2QBC3X
KYC_CONTRACT_ID ?= CA4BWZDQKXRO3PPETJO5GKA2TON2HDPKOTBPLLBPUMSM2WNSEUWYXVLW
ADMIN_ACCOUNT ?= G_ADMIN_ACCOUNT_HERE

.PHONY: help print-env classic-asset onboard-user register-sac soroban-build soroban-test

help:
	@echo "Targets:"
	@echo "  make print-env      # show current environment values used by scripts"
	@echo "  make classic-asset  # create/configure classic asset + trustline/auth flow"
	@echo "  make onboard-user   # new user trustline + optional auth + optional send"
	@echo "  make register-sac   # register/get SAC for ASSET_CODE:ISSUER_ACCOUNT"
	@echo "  make soroban-build  # build soroban contract in soroban/kyc_asset"
	@echo "  make soroban-test   # run soroban contract tests"

print-env:
	@echo "NETWORK=$(NETWORK)"
	@echo "ASSET_CODE=$(ASSET_CODE)"
	@echo "ISSUER_ACCOUNT=$(ISSUER_ACCOUNT)"
	@echo "DIST_ACCOUNT=$(DIST_ACCOUNT)"
	@echo "NEW_USER_ACCOUNT=$(NEW_USER_ACCOUNT)"
	@echo "ISSUE_AMOUNT=$(ISSUE_AMOUNT)"
	@echo "SEND_AMOUNT=$(SEND_AMOUNT)"
	@echo "REQUIRE_AUTH=$(REQUIRE_AUTH)"
	@echo "REVOCABLE_AUTH=$(REVOCABLE_AUTH)"
	@echo "SOURCE_SECRET=$$( [[ '$(SOURCE_SECRET)' == S_SOURCE_SECRET_HERE ]] && echo '<placeholder>' || echo '<set>' )"
	@echo "ISSUER_SECRET=$$( [[ '$(ISSUER_SECRET)' == S_ISSUER_SECRET_HERE ]] && echo '<placeholder>' || echo '<set>' )"
	@echo "DIST_SECRET=$$( [[ '$(DIST_SECRET)' == S_DISTRIBUTOR_SECRET_HERE ]] && echo '<placeholder>' || echo '<set>' )"
	@echo "NEW_USER_SECRET=$$( [[ '$(NEW_USER_SECRET)' == S_NEW_USER_SECRET_HERE ]] && echo '<placeholder>' || echo '<set>' )"

classic-asset:
	@NETWORK="$(NETWORK)" \
	ASSET_CODE="$(ASSET_CODE)" \
	ISSUER_ACCOUNT="$(ISSUER_ACCOUNT)" \
	DIST_ACCOUNT="$(DIST_ACCOUNT)" \
	ISSUER_SECRET="$(ISSUER_SECRET)" \
	DIST_SECRET="$(DIST_SECRET)" \
	ISSUE_AMOUNT="$(ISSUE_AMOUNT)" \
	REQUIRE_AUTH="$(REQUIRE_AUTH)" \
	REVOCABLE_AUTH="$(REVOCABLE_AUTH)" \
	bash scripts/create_classic_asset.sh

register-sac:
	@set -euo pipefail; \
	if ! command -v stellar >/dev/null 2>&1; then \
		echo "stellar CLI not found. Install it first."; \
		exit 1; \
	fi; \
	ASSET="$(ASSET_CODE):$(ISSUER_ACCOUNT)"; \
	echo "==> Registering/getting SAC for $$ASSET"; \
	SAC_ID="$$(stellar contract asset deploy \
		--asset "$$ASSET" \
		--source-account "$(SOURCE_SECRET)" \
		--network "$(NETWORK)")"; \
	echo "SAC contract id: $$SAC_ID"

onboard-user:
	@NETWORK="$(NETWORK)" \
	ASSET_CODE="$(ASSET_CODE)" \
	ISSUER_ACCOUNT="$(ISSUER_ACCOUNT)" \
	ISSUER_SECRET="$(ISSUER_SECRET)" \
	DIST_SECRET="$(DIST_SECRET)" \
	NEW_USER_ACCOUNT="$(NEW_USER_ACCOUNT)" \
	NEW_USER_SECRET="$(NEW_USER_SECRET)" \
	REQUIRE_AUTH="$(REQUIRE_AUTH)" \
	SEND_AMOUNT="$(SEND_AMOUNT)" \
	bash scripts/onboard_user_trustline.sh

soroban-build:
	@cd soroban/kyc_asset && cargo build --target wasm32v1-none --release

soroban-test:
	@cd soroban/kyc_asset && cargo test

contract-deploy:
	stellar contract deploy \
  		--wasm soroban/kyc_asset/target/wasm32v1-none/release/kyc_asset.wasm \
  		--source-account SC7FWTEOHJ6XDD7HYFGB4KURHRRRE4BPVIMUSCBDC3H22PG45KJXMSV4 \
  		--network $(NETWORK)

contract-invoke:
	stellar contract invoke \
  		--id $(KYC_CONTRACT_ID) \
  		--source-account $(SOURCE_SECRET) \
  		--network $(NETWORK) \
  		-- init \
  		--admin alice \
  		--sac $(SAC_ID)

contract-transfer:
	stellar contract invoke \
  		--id $(KYC_CONTRACT_ID) \
  		--source-account $(SOURCE_SECRET) \
  		--network $(NETWORK) \
  		-- transfer \
  		--from alice \
  		--to alice2 \
  		--amount 100

