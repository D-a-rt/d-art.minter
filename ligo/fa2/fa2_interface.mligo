#if ! FA2_INTERFACE
#define FA2_INTERFACE

type token_id = nat

type token_metadata =
[@layout:comb]
  {
    token_id: token_id;
    token_info: ((string, bytes) map);
  }

type transfer_destination =
[@layout:comb]
{
  to_ : address;
  token_id : token_id;
  amount : nat;
}

type fa2_destination =
[@layout:comb]
{
  to_ : address option;
  token_id : token_id;
  amount : nat;
}


type transfer_description =
[@layout:comb]
{
  from_ : address option;
  destinations : fa2_destination list
}

type transfer =
[@layout:comb]
{
  from_ : address;
  destinations : transfer_destination list;
}

type balance_of_request =
[@layout:comb]
{
  owner : address;
  token_id : token_id;
}

type balance_of_response =
[@layout:comb]
{
  request : balance_of_request;
  balance : nat;
}

type balance_of_param =
[@layout:comb]
{
  requests : balance_of_request list;
  callback : (balance_of_response list) contract;
}

type royalties_param =
[@layout:comb] 
{
  token_id: token_id;
  fee: tez;
}

type operator_param =
[@layout:comb]
{
  owner : address;
  operator : address;
  token_id: token_id;
}

type update_operator =
[@layout:comb]
  | Add_operator of operator_param
  | Remove_operator of operator_param

type token_metadata_param =
[@layout:comb]
{
  token_ids : token_id list;
  handler : (token_metadata list) -> unit;
}

(*
One of the options to make token metadata discoverable is to declare
`token_metadata : token_metadata_storage` field inside the FA2 contract storage
*)
type token_metadata_storage = (token_id, token_metadata) big_map

type fa2_entry_points =
  | Minter_royalties of royalties_param
  | Transfer of transfer list
  | Balance_of of balance_of_param
  | Update_operators of update_operator list
  (* | Token_metadata_registry of address contract *)

type fa2_token_metadata =
  | Token_metadata of token_metadata_param

(* permission policy definition *)

type operator_transfer_policy =
  [@layout:comb]
  | No_transfer
  | Owner_transfer
  | Owner_or_operator_transfer

type owner_hook_policy =
  [@layout:comb]
  | Owner_no_hook
  | Optional_owner_hook
  | Required_owner_hook

type custom_permission_policy =
[@layout:comb]
{
  tag : string;
  config_api: address option;
}

type transfer_destination_descriptor =
[@layout:comb]
{
  to_ : address option;
  token_id : token_id;
  amount : nat;
}

type transfer_description_param =
[@layout:comb]
{
  batch : transfer_description list;
  operator : address;
}

type ledger = (token_id, address) big_map

type permissions_descriptor =
[@layout:comb]
{
  operator : operator_transfer_policy;
  receiver : owner_hook_policy;
  sender : owner_hook_policy;
  custom : custom_permission_policy option;
}



type nft_meta = (nat, token_metadata) big_map

type minters = (address, unit) big_map

type tokens_minter = (token_id, address) big_map

type operator_storage = ((address * (address * token_id)), unit) big_map

type assets = {
  ledger : ledger;
  token_metadata : nft_meta;
  next_token_id : token_id;
  operators : operator_storage;
  minters : minters;
  tokens_minter : tokens_minter;
}

#endif
