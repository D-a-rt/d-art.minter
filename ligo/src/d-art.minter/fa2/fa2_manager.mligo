#if !FA2_MULTI_NFT_TOKEN

#define FA2_MULTI_NFT_TOKEN

#include "../../../fa2/fa2_interface.mligo"
#include "../../../fa2/fa2_errors.mligo"

#include "../../../fa2/lib/fa2_operator_lib.mligo"
#include "../../../fa2/lib/fa2_owner_hooks_lib.mligo"
#include "../../common.mligo"

let dec_balance(owner, token_id, ledger : address option * token_id * ledger) : ledger =
  match owner with
  | None -> ledger (* this is mint transfer, don't change the ledger *)
  | Some o -> (
    let current_owner = Big_map.find_opt token_id ledger in
    match current_owner with
    | None -> (failwith fa2_token_undefined : ledger)
    | Some cur_o ->
      if cur_o = o
      then Big_map.remove token_id ledger
      else (failwith fa2_insufficient_balance : ledger)
  )

let inc_balance(owner, token_id, ledger : address option * token_id * ledger) : ledger =
  match owner with
  | None -> ledger (* this is burn transfer, don't change the ledger *)
  | Some o -> Big_map.add token_id o ledger

let update_ledger (transfer_descriptions, validate_operators, operators, original_ledger 
    : (transfer_description list) * operator_validator * operator_storage * ledger) : ledger =

  let make_transfer = fun (ledger, transfer_description : ledger * transfer_description) ->
      List.fold
          (fun (folded_ledger, destination : ledger * fa2_destination) ->
              let _fail = match transfer_description.from_ with
                  | None -> unit
                  | Some owner -> validate_operators (owner, Tezos.sender, destination.token_id, operators)
              in
              if destination.amount > 1n
                then (failwith fa2_insufficient_balance : ledger)
              else if destination.amount = 0n
                then match Big_map.find_opt destination.token_id folded_ledger with
                    | None -> (failwith fa2_token_undefined : ledger)
                    | Some _current_owner -> folded_ledger (* zero transfer, don't change the ledger *)
              else
                let new_ledger = dec_balance (transfer_description.from_, destination.token_id, folded_ledger) in
                inc_balance(destination.to_, destination.token_id, new_ledger)
          ) transfer_description.destinations ledger
    in
    List.fold make_transfer transfer_descriptions original_ledger

let fa2_transfer (transfer_descriptions, validate_op, storage
    : (transfer_description list) * operator_validator * assets)
    : (operation list) * assets =

    let new_ledger = update_ledger (transfer_descriptions, validate_op, storage.operators, storage.ledger) in

    let new_storage = { storage with ledger = new_ledger; } in
    let ops = ([] : operation list) in//get_owner_hook_ops (transfer_descriptions, storage) in
    ops, new_storage

let transfer_minter_royalties (royalties_param, storage : royalties_param * assets) : (operation list) * assets =

  let minter : address = match Big_map.find_opt royalties_param.token_id storage.tokens_minter with
      | None ->  (failwith "No token with this id" : address)       
      | Some minter -> minter
  in
  
  let minter_contract : unit contract = resolve_contract minter in
  let pay_royalties : operation = Tezos.transaction unit royalties_param.fee minter_contract in
  [pay_royalties], storage

(**
    Retrieve the balances for the specified tokens and owners
    @return callback operation
*)
let get_balance (p, ledger : balance_of_param * ledger) : operation =
  let to_balance = fun (r : balance_of_request) ->
    let owner = Big_map.find_opt r.token_id ledger in
    match owner with
    | None -> (failwith fa2_token_undefined : balance_of_response)
    | Some o ->
      let bal = 
        if o = r.owner 
        then 1n 
        else 0n 
      in
      { request = r; balance = bal; }
  in
  let responses = List.map to_balance p.requests in
  Tezos.transaction responses 0mutez p.callback

let fa2_manager_main (param, storage : fa2_entry_points * assets)
    : (operation  list) * assets =
  match param with
  | Minter_royalties royalties_param ->
    transfer_minter_royalties(royalties_param, storage)

  | Transfer transfers ->
    let tx_descriptors = transfers_to_descriptors transfers in
    fa2_transfer (tx_descriptors, default_operator_validator, storage)

  | Balance_of p ->
    let op = get_balance (p, storage.ledger) in
    [op], storage

  | Update_operators updates ->
    let new_operators = fa2_update_operators (updates, storage.operators) in
    let new_storage = { storage with operators = new_operators; } in
    ([] : operation list), new_storage

#endif
