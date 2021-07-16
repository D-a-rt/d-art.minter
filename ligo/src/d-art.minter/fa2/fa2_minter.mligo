type minted_fa2 = {
  assets : assets;
  destinations : fa2_destination list;
}

type token_input_metadata = 
[@layout:comb]
{
    token_id: token_id;
    token_info: ((string, bytes) map);
}

type mint_token_param =
[@layout:comb]
{
    token_metadata: token_input_metadata;
    owner : address;
}

let update_meta_and_ledger (mint_token_param, assets : mint_token_param * assets ) : minted_fa2 =

    let new_token_metadata = Big_map.add assets.next_token_id mint_token_param.token_metadata assets.token_metadata in
    let new_tokens_minter = Big_map.add assets.next_token_id Tezos.sender assets.tokens_minter in
    let next_token_id : nat = assets.next_token_id + 1n in
    
    let new_assets = {
        assets with
        token_metadata = new_token_metadata;
        next_token_id = next_token_id;
        tokens_minter = new_tokens_minter
    } in

    let destination : fa2_destination = {
        to_ = Some mint_token_param.owner;
        token_id = assets.next_token_id;
        amount = 1n;
    } in

    let minted_fa2 : minted_fa2 = {
        assets = new_assets;
        destinations = [destination];
    } in

    minted_fa2

let mint_token (param, assets : mint_token_param * assets)
    : operation list * assets =
  
  let minted_token = update_meta_and_ledger (param, assets) in
    
  (* update ledger *)
  let transfer_description : transfer_description = {
    from_ = (None : address option);
    destinations = minted_token.destinations;
  } in

  let validate_operators =
    fun (_p : address * address * token_id * operator_storage) -> unit in
  
  fa2_transfer ([transfer_description], validate_operators, minted_token.assets)
  
