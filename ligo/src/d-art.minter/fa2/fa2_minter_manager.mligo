#include "../../../fa2_modules/admin.mligo"

type admin_minter_entrypoints =
    | Add_minter of address
    | Remove_minter of address

type nft_asset_storage = {
  assets : assets;
  admin : admin_storage;
  metadata: (string, bytes) big_map; (* contract metadata *)
}

(* True if sender is a minter *)
[@inline]
let is_minter (minter, minters : address * minters) : bool =
  Big_map.mem minter minters

(* Only callable by admin *)
let add_minter (new_minter, assets: address * assets) : assets =
    if (is_minter(new_minter, assets.minters))
    then (failwith "MINTER_ALREADY_ADDED" : assets)
    else { assets with minters = Big_map.add new_minter unit assets.minters }

(* Only callable by admin *)
let remove_minter (old_minter, assets: address * assets) : assets =
    if (is_minter(old_minter, assets.minters))
    then { assets with minters = Big_map.remove old_minter assets.minters }
    else (failwith "MINTER_NOT_FOUND" : assets)

(* Fails if sender is not admin *)
let fail_if_not_minter (minters : minters) : unit =
  if (Big_map.mem Tezos.sender minters)
  then unit
  else failwith "NOT_A_MINTER"

let fail_if_minter_not_owner (owner : address) : unit =
  if Tezos.sender = owner
  then unit
  else failwith "OWNER_IS_NOT_MINTER"

let minter_admin_main (param, storage : admin_minter_entrypoints * nft_asset_storage)
    : (operation list) * nft_asset_storage =
  match param with
  | Add_minter minter_address ->
    let _fail = fail_if_not_admin (storage.admin) in
    let new_assets = add_minter (minter_address, storage.assets) in
    let new_storage = { storage with assets = new_assets; } in
    (([] : operation list), new_storage)

  | Remove_minter minter_address ->
    let _fail = fail_if_not_admin (storage.admin) in
    let new_assets = remove_minter (minter_address, storage.assets) in
    let new_storage = { storage with assets = new_assets; } in
    (([] : operation list), new_storage)
