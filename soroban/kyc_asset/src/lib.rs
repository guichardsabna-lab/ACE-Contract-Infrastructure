#![no_std]

use soroban_sdk::{contract, contractimpl, contracttype, token, Address, Env, Symbol, Vec};

#[contract]
pub struct KycAssetController;

#[contracttype]
#[derive(Clone)]
enum DataKey {
    Admin,
    Sac,
}

#[contractimpl]
impl KycAssetController {
    // Initialize once with admin and the target SAC address.
    pub fn init(env: Env, admin: Address, sac: Address) {
        admin.require_auth();
        if env.storage().instance().has(&DataKey::Admin) {
            panic!("already initialized");
        }
        env.storage().instance().set(&DataKey::Admin, &admin);
        env.storage().instance().set(&DataKey::Sac, &sac);
    }

    pub fn get_admin(env: Env) -> Address {
        env.storage()
            .instance()
            .get(&DataKey::Admin)
            .expect("not initialized")
    }

    pub fn get_sac(env: Env) -> Address {
        env.storage()
            .instance()
            .get(&DataKey::Sac)
            .expect("not initialized")
    }

    // Admin can rotate/update SAC if needed.
    pub fn set_sac(env: Env, sac: Address) {
        let admin = Self::get_admin(env.clone());
        admin.require_auth();
        env.storage().instance().set(&DataKey::Sac, &sac);
    }

    // Placeholder hook for future KYC gate logic.
    pub fn is_kyc_allowed(_env: Env, _user: Address) -> bool {
        true
    }

    // Simple read helper: token balance from SAC.
    pub fn balance(env: Env, user: Address) -> i128 {
        let sac = Self::get_sac(env.clone());
        token::Client::new(&env, &sac).balance(&user)
    }

    // Simple read helper: allowance from SAC.
    pub fn allowance(env: Env, from: Address, spender: Address) -> i128 {
        let sac = Self::get_sac(env.clone());
        token::Client::new(&env, &sac).allowance(&from, &spender)
    }

    // Transfer using SAC token interface.
    pub fn transfer(env: Env, from: Address, to: Address, amount: i128) {
        // Root invocation must authenticate `from` before forwarding to SAC.
        from.require_auth();
        let sac = Self::get_sac(env.clone());
        token::Client::new(&env, &sac).transfer(&from, &to, &amount);
    }

    pub fn version(env: Env) -> Vec<Symbol> {
        Vec::from_array(
            &env,
            [
                Symbol::new(&env, "kyc"),
                Symbol::new(&env, "asset"),
                Symbol::new(&env, "v2"),
            ],
        )
    }
}
