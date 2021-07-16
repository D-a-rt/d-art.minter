#include "fa2_manager.mligo"
#include "fa2_minter.mligo"
#include "fa2_minter_manager.mligo"

type nft_asset_storage = {
  assets : assets;
  admin : admin_storage;
  metadata: (string, bytes) big_map; (* contract metadata *)
}

type nft_asset_entrypoints =
    | Assets of fa2_entry_points
    | Mint of mint_token_param
    | Admin of admin_minter_entrypoints

let fa2_main (param, storage : nft_asset_entrypoints * nft_asset_storage)
    : (operation  list) * nft_asset_storage =
  match param with
    | Assets fa2 ->
        let ops, new_assets = fa2_manager_main (fa2, storage.assets) in
        let new_storage = { storage with assets = new_assets; } in
        ops, new_storage

    | Mint new_token_param ->
        let _u = fail_if_not_minter storage.assets.minters in
        let _v = fail_if_minter_not_owner new_token_param.owner in
        let ops, new_assets = mint_token (new_token_param, storage.assets) in
        let new_storage = { storage with assets = new_assets; } in
        ops, new_storage

    | Admin minter_address ->
        let ops, new_nft_storage = minter_admin_main (minter_address, storage) in
        ops, new_nft_storage
